import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app/config/env_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/circuit_breaker.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_message_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WsSignalingClient implements SignalingClient {
  final AppLogger _logger;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();

  final CircuitBreaker _circuitBreaker;

  String? _peerId;
  String? _currentRoomId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _isExplicitlyClosed = false;

  static const Duration _initialDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  static const double _backoffFactor = 1.5;

  WsSignalingClient(this._logger, {CircuitBreaker? circuitBreaker})
    : _circuitBreaker =
          circuitBreaker ??
          CircuitBreaker(
            maxFailures: 5,
            resetTimeout: const Duration(minutes: 5),
          );

  @override
  String? get peerId => _peerId;

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _logger.i(
      '[ws_signaling_client.dart -> connect -> 1.0 -> Connection request for room: $roomId]',
      module: 'WsSignaling',
    );
    _currentRoomId = roomId;
    _isExplicitlyClosed = false;

    if (_isConnecting) {
      _logger.d(
        '[ws_signaling_client.dart -> connect -> 1.1 -> Already connecting, ignoring request]',
        module: 'WsSignaling',
      );
      return;
    }

    if (!_circuitBreaker.canExecute()) {
      _logger.w(
        '[ws_signaling_client.dart -> connect -> 1.2 -> Circuit Breaker is OPEN. Aborting connection attempt]',
        module: 'WsSignaling',
      );
      _stateController.add(SignalingState.disconnected);
      return;
    }

    _isConnecting = true;
    _logger.d(
      '[ws_signaling_client.dart -> connect -> 1.3 -> Cleaning up old connection before connecting]',
      module: 'WsSignaling',
    );
    await _cleanupConnection();

    _stateController.add(SignalingState.connecting);

    try {
      final urlString = '${EnvConfig.current.wsBaseUrl}?room=$roomId';
      _logger.i(
        '[ws_signaling_client.dart -> connect -> 1.4 -> WebSocket URI: $urlString]',
        module: 'WsSignaling',
      );

      final uri = Uri.parse(urlString);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnecting = false;
      _stopReconnectTimer();
      _circuitBreaker.onSuccess();

      _stateController.add(SignalingState.connected);
      _logger.i(
        '[ws_signaling_client.dart -> connect -> 1.5 -> WebSocket connected successfully]',
        module: 'WsSignaling',
      );

      _subscription = _channel!.stream.listen(
        (rawMessage) {
          _handleIncomingMessage(rawMessage);
        },
        onDone: () {
          _logger.w(
            '[ws_signaling_client.dart -> listen -> onDone -> Connection closed]',
            module: 'WsSignaling',
          );
          _handleConnectionLoss();
        },
        onError: (Object error, Object? stackTrace) {
          _logger.e(
            '[ws_signaling_client.dart -> listen -> onError -> Stream error]',
            module: 'WsSignaling',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
          _handleConnectionLoss();
        },
      );
    } catch (e, st) {
      _logger.e(
        '[ws_signaling_client.dart -> connect -> ERR -> Exception during WS connection]',
        module: 'WsSignaling',
        error: e,
        stackTrace: st,
      );
      _isConnecting = false;
      _handleConnectionLoss();
    }
  }

  void _handleIncomingMessage(dynamic raw) {
    if (raw is! String) return;

    _logger.t(
      '[ws_signaling_client.dart -> _handleIncomingMessage -> 1.0 -> Raw payload: $raw]',
      module: 'WsSignaling',
    );
    final events = parseSignalingMessages(raw);

    for (final event in events) {
      if (event is RoomJoinedEvent) {
        _peerId = event.myPeerId;
        _logger.i(
          '[ws_signaling_client.dart -> _handleIncomingMessage -> 1.1 -> Assigned peerId: $_peerId]',
          module: 'WsSignaling',
        );
      }
      _logger.d(
        '[ws_signaling_client.dart -> _handleIncomingMessage -> 1.2 -> Parsed event: ${event.runtimeType}]',
        module: 'WsSignaling',
      );
      _eventController.add(event);
    }

    if (events.isEmpty) {
      _logger.w(
        '[ws_signaling_client.dart -> _handleIncomingMessage -> 1.3 -> Unknown or unparseable payload: $raw]',
        module: 'WsSignaling',
      );
    }
  }

  void _handleConnectionLoss() {
    _logger.w(
      '[ws_signaling_client.dart -> _handleConnectionLoss -> 1.0 -> Handling connection loss | Resetting peerId]',
      module: 'WsSignaling',
    );
    _peerId = null;
    _circuitBreaker.onFailure();
    _stateController.add(SignalingState.disconnected);

    if (!_isExplicitlyClosed) {
      _startReconnectTimer();
    }
  }

  void _startReconnectTimer() {
    if (_reconnectTimer?.isActive ?? false) return;

    if (_circuitBreaker.isOpen) {
      _logger.w(
        '[ws_signaling_client.dart -> _startReconnectTimer -> 1.0 -> Circuit Breaker OPEN. Skipping reconnect]',
        module: 'WsSignaling',
      );
      return;
    }

    final delay = _calculateBackoffDelay();
    _logger.i(
      '[ws_signaling_client.dart -> _startReconnectTimer -> 1.1 -> Scheduling reconnect attempt #${_reconnectAttempts + 1} in ${delay.inMilliseconds}ms]',
      module: 'WsSignaling',
    );

    _reconnectTimer = Timer(delay, () {
      if (_currentRoomId != null && !_isExplicitlyClosed && !_isConnecting) {
        _reconnectAttempts++;
        _logger.i(
          '[ws_signaling_client.dart -> _startReconnectTimer -> 1.2 -> Executing auto-reconnect attempt #$_reconnectAttempts]',
          module: 'WsSignaling',
        );
        connect(_currentRoomId!);
      }
    });
  }

  Duration _calculateBackoffDelay() {
    final calculatedMs =
        _initialDelay.inMilliseconds * pow(_backoffFactor, _reconnectAttempts);
    final cappedMs = min(
      calculatedMs.toDouble(),
      _maxDelay.inMilliseconds.toDouble(),
    );

    final random = Random();
    final jitter = cappedMs * 0.25 * random.nextDouble();

    return Duration(milliseconds: (cappedMs + jitter).toInt());
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  Future<void> _cleanupConnection() async {
    _logger.d(
      '[ws_signaling_client.dart -> _cleanupConnection -> 1.0 -> Cleaning active stream and channel]',
      module: 'WsSignaling',
    );
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _send(Map<String, dynamic> data) {
    try {
      final payload = jsonEncode(data);
      _logger.t(
        '[ws_signaling_client.dart -> _send -> 1.0 -> Sending WS payload: $payload]',
        module: 'WsSignaling',
      );
      _channel?.sink.add(payload);
    } catch (e, st) {
      _logger.e(
        '[ws_signaling_client.dart -> _send -> ERR -> Failed to send WebSocket message]',
        module: 'WsSignaling',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void sendOffer(String targetId, String sdp) {
    _logger.d(
      '[ws_signaling_client.dart -> sendOffer -> 1.0 -> Sending SDP offer to target: $targetId]',
      module: 'WsSignaling',
    );
    _send({
      'type': 'offer',
      'target_id': targetId,
      'payload': {'sdp': sdp},
    });
  }

  @override
  void sendAnswer(String targetId, String sdp) {
    _logger.d(
      '[ws_signaling_client.dart -> sendAnswer -> 1.0 -> Sending SDP answer to target: $targetId]',
      module: 'WsSignaling',
    );
    _send({
      'type': 'answer',
      'target_id': targetId,
      'payload': {'sdp': sdp},
    });
  }

  @override
  void sendIceCandidate(
    String targetId,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {
    _logger.d(
      '[ws_signaling_client.dart -> sendIceCandidate -> 1.0 -> Sending ICE candidate to target: $targetId]',
      module: 'WsSignaling',
    );
    _send({
      'type': 'candidate',
      'target_id': targetId,
      'payload': {
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
      },
    });
  }

  void onNetworkRestored() {
    if (_circuitBreaker.isOpen && _currentRoomId != null) {
      _logger.i(
        '[ws_signaling_client.dart -> onNetworkRestored -> 1.0 -> Network restored - resetting Circuit Breaker and reconnecting]',
        module: 'WsSignaling',
      );
      _circuitBreaker.reset();
      connect(_currentRoomId!);
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.i(
      '[ws_signaling_client.dart -> disconnect -> 1.0 -> Explicit disconnect called]',
      module: 'WsSignaling',
    );
    _isExplicitlyClosed = true;
    _peerId = null;
    _stopReconnectTimer();
    _circuitBreaker.dispose();
    await _cleanupConnection();
    _currentRoomId = null;
    _stateController.add(SignalingState.disconnected);
  }
}
