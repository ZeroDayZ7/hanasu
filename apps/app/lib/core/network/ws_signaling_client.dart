// lib/core/network/ws_signaling_client.dart
import 'dart:async';
import 'dart:convert';

import 'package:app/config/env_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WsSignalingClient implements SignalingClient {
  final AppLogger _logger;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();

  String? _currentRoomId;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isExplicitlyClosed = false;

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

      // Oczekiwanie na gotowość gniazda
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

  void _handleConnectionLoss() {
    _stateController.add(SignalingState.disconnected);

    if (!_isExplicitlyClosed) {
      _startReconnectTimer();
    }
  }

  void _startReconnectTimer() {
    if (_reconnectTimer?.isActive ?? false) return;

    _logger.i(
      'Starting auto-reconnect timer (retrying every 3s)...',
      module: 'WsSignaling',
    );
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentRoomId != null && !_isExplicitlyClosed && !_isConnecting) {
        _logger.i(
          'Attempting auto-reconnect to room: $_currentRoomId',
          module: 'WsSignaling',
        );
        connect(_currentRoomId!);
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _cleanupConnection() async {
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _handleIncomingMessage(dynamic raw) {
    try {
      _logger.t('Received raw message: $raw', module: 'WsSignaling');
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String?;

      switch (type) {
        case 'peer_joined':
          final payload = map['payload'] as Map<String, dynamic>?;
          final peerId =
              payload?['peer_id'] as String? ??
              map['peer_id'] as String? ??
              'unknown';
          _logger.d('Event: Peer joined -> $peerId', module: 'WsSignaling');
          _eventController.add(PeerJoinedEvent(peerId));
          break;

        case 'peer_left':
          final payload = map['payload'] as Map<String, dynamic>?;
          final peerId =
              payload?['peer_id'] as String? ??
              map['peer_id'] as String? ??
              'unknown';
          _logger.d('Event: Peer left -> $peerId', module: 'WsSignaling');
          _eventController.add(PeerLeftEvent(peerId));
          break;

        case 'offer':
          final senderId =
              map['sender'] as String? ?? map['sender_id'] as String? ?? '';
          final payload = map['payload'] as Map<String, dynamic>?;
          final sdp = payload?['sdp'] as String? ?? map['sdp'] as String? ?? '';
          _logger.d(
            'Event: Offer received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            OfferReceivedEvent(senderId: senderId, sdp: sdp),
          );
          break;

        case 'answer':
          final senderId =
              map['sender'] as String? ?? map['sender_id'] as String? ?? '';
          final payload = map['payload'] as Map<String, dynamic>?;
          final sdp = payload?['sdp'] as String? ?? map['sdp'] as String? ?? '';
          _logger.d(
            'Event: Answer received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            AnswerReceivedEvent(senderId: senderId, sdp: sdp),
          );
          break;

        case 'candidate':
          final senderId =
              map['sender'] as String? ?? map['sender_id'] as String? ?? '';
          final payload = map['payload'] as Map<String, dynamic>?;
          final candidate =
              payload?['candidate'] as String? ??
              map['candidate'] as String? ??
              '';
          final sdpMid =
              payload?['sdpMid'] as String? ?? map['sdpMid'] as String? ?? '';
          final sdpMLineIndex =
              payload?['sdpMLineIndex'] as int? ??
              map['sdpMLineIndex'] as int? ??
              0;

          _logger.t(
            'Event: ICE Candidate received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            IceCandidateReceivedEvent(
              senderId: senderId,
              candidate: candidate,
              sdpMid: sdpMid,
              sdpMLineIndex: sdpMLineIndex,
            ),
          );
          break;

        default:
          _logger.w(
            'Unknown message type received: $type',
            module: 'WsSignaling',
          );
      }
    } catch (e, st) {
      _logger.e(
        'Failed to parse incoming WebSocket message',
        module: 'WsSignaling',
        error: e,
        stackTrace: st,
      );
    }
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
    _logger.d('Sending offer to -> $targetId', module: 'WsSignaling');
    _send({'type': 'offer', 'target_id': targetId, 'sdp': sdp});
  }

  @override
  void sendAnswer(String targetId, String sdp) {
    _logger.d('Sending answer to -> $targetId', module: 'WsSignaling');
    _send({'type': 'answer', 'target_id': targetId, 'sdp': sdp});
  }

  @override
  void sendIceCandidate(
    String targetId,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {
    _logger.t('Sending ICE candidate to -> $targetId', module: 'WsSignaling');
    _send({
      'type': 'candidate',
      'target_id': targetId,
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  @override
  Future<void> disconnect() async {
    _logger.i(
      'Disconnecting WebSocket client explicitly',
      module: 'WsSignaling',
    );
    _isExplicitlyClosed = true;
    _stopReconnectTimer();
    await _cleanupConnection();
    _currentRoomId = null;
    _stateController.add(SignalingState.disconnected);
  }
}
