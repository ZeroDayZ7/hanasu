import 'dart:async';
import 'dart:convert';

import 'package:app/config/env_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class WsSignalingClient implements SignalingClient {
  final AppLogger _logger;
  WebSocketChannel? _channel;
  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();

  WsSignalingClient(this._logger);

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _logger.i('Connecting to WebSocket room: $roomId', module: 'WsSignaling');
    _stateController.add(SignalingState.connecting);

    try {
      final uri = Uri.parse('${EnvConfig.current.wsBaseUrl}?room=$roomId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (rawMessage) {
          _handleIncomingMessage(rawMessage);
        },
        onDone: () {
          _logger.w('WebSocket connection closed', module: 'WsSignaling');
          _stateController.add(SignalingState.disconnected);
        },
        onError: (Object error, Object? stackTrace) {
          _logger.e(
            'WebSocket stream error',
            module: 'WsSignaling',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
          _stateController.add(SignalingState.error);
        },
      );

      _stateController.add(SignalingState.connected);
      _logger.i('WebSocket connected successfully', module: 'WsSignaling');
    } catch (e, st) {
      _logger.e(
        'Failed to connect to WebSocket',
        module: 'WsSignaling',
        error: e,
        stackTrace: st,
      );
      _stateController.add(SignalingState.error);
    }
  }

  void _handleIncomingMessage(dynamic raw) {
    try {
      _logger.t('Received raw message: $raw', module: 'WsSignaling');
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String?;

      switch (type) {
        case 'peer_joined':
          final peerId = map['peer_id'] as String;
          _logger.d('Event: Peer joined -> $peerId', module: 'WsSignaling');
          _eventController.add(PeerJoinedEvent(peerId));
          break;
        case 'peer_left':
          final peerId = map['peer_id'] as String;
          _logger.d('Event: Peer left -> $peerId', module: 'WsSignaling');
          _eventController.add(PeerLeftEvent(peerId));
          break;
        case 'offer':
          final senderId = map['sender_id'] as String;
          _logger.d(
            'Event: Offer received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            OfferReceivedEvent(senderId: senderId, sdp: map['sdp'] as String),
          );
          break;
        case 'answer':
          final senderId = map['sender_id'] as String;
          _logger.d(
            'Event: Answer received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            AnswerReceivedEvent(senderId: senderId, sdp: map['sdp'] as String),
          );
          break;
        case 'candidate':
          final senderId = map['sender_id'] as String;
          _logger.t(
            'Event: ICE Candidate received from -> $senderId',
            module: 'WsSignaling',
          );
          _eventController.add(
            IceCandidateReceivedEvent(
              senderId: senderId,
              candidate: map['candidate'] as String,
              sdpMid: map['sdpMid'] as String,
              sdpMLineIndex: map['sdpMLineIndex'] as int,
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
    _logger.i('Disconnecting WebSocket client', module: 'WsSignaling');
    await _channel?.sink.close();
    _stateController.add(SignalingState.disconnected);
  }
}
