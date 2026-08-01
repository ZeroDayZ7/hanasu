import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app/config/env_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_message_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WsSignalingClient implements SignalingClient {
  final AppLogger _logger;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();

  String? _currentRoomId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _isExplicitlyClosed = false;

  // Konfiguracja Exponential Backoff
  static const Duration _initialDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  static const double _backoffFactor = 1.5;

  WsSignalingClient(this._logger);

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _currentRoomId = roomId;
    _isExplicitlyClosed = false;

    if (_isConnecting) return;
    _isConnecting = true;

    await _cleanupConnection();

    _logger.i('Connecting to WebSocket room: $roomId', module: 'WsSignaling');
    _stateController.add(SignalingState.connecting);

    try {
      final urlString = '${EnvConfig.current.wsBaseUrl}?room=$roomId';
      _logger.i('Full WebSocket URI: $urlString', module: 'WsSignaling');

      final uri = Uri.parse(urlString);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnecting = false;
      _stopReconnectTimer();

      _stateController.add(SignalingState.connected);
      _logger.i('WebSocket connected successfully', module: 'WsSignaling');

      _subscription = _channel!.stream.listen(
        (rawMessage) {
          _handleIncomingMessage(rawMessage);
        },
        onDone: () {
          _logger.w('WebSocket connection closed', module: 'WsSignaling');
          _handleConnectionLoss();
        },
        onError: (Object error, Object? stackTrace) {
          _logger.e(
            'WebSocket stream error',
            module: 'WsSignaling',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
          _handleConnectionLoss();
        },
      );
    } catch (e, st) {
      _logger.e(
        'Failed to connect to WebSocket',
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

    _logger.t('Received raw message: $raw', module: 'WsSignaling');
    final event = parseSignalingMessage(raw);

    if (event != null) {
      _logger.d('Parsed event: ${event.runtimeType}', module: 'WsSignaling');
      _eventController.add(event);
    } else {
      _logger.w(
        'Unknown or unparseable payload received: $raw',
        module: 'WsSignaling',
      );
    }
  }

  void _handleConnectionLoss() {
    _stateController.add(SignalingState.disconnected);

    if (!_isExplicitlyClosed) {
      _startReconnectTimer();
    }
  }

  void _startReconnectTimer() {
    if (_reconnectTimer?.isActive ?? false) return;

    final delay = _calculateBackoffDelay();
    _logger.i(
      'Scheduling reconnect attempt #${_reconnectAttempts + 1} in ${delay.inMilliseconds}ms',
      module: 'WsSignaling',
    );

    _reconnectTimer = Timer(delay, () {
      if (_currentRoomId != null && !_isExplicitlyClosed && !_isConnecting) {
        _reconnectAttempts++;
        _logger.i(
          'Attempting auto-reconnect (attempt #$_reconnectAttempts)...',
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

    // Jitter: dodajemy losowy szum (0-25%), aby zapobiec jednoczesnym strzałom wielu klientów
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
      _logger.t('Sending WS payload: $payload', module: 'WsSignaling');
      _channel?.sink.add(payload);
    } catch (e, st) {
      _logger.e(
        'Failed to send WebSocket message',
        module: 'WsSignaling',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void sendOffer(String targetId, String sdp) {
    _send({
      'type': 'offer',
      'target_id': targetId,
      'payload': {'sdp': sdp},
    });
  }

  @override
  void sendAnswer(String targetId, String sdp) {
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

  @override
  Future<void> disconnect() async {
    _isExplicitlyClosed = true;
    _stopReconnectTimer();
    await _cleanupConnection();
    _currentRoomId = null;
    _stateController.add(SignalingState.disconnected);
  }
}
