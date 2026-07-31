import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/env_config.dart';
import 'signaling_client.dart';

class WsSignalingClient implements SignalingClient {
  WebSocketChannel? _channel;
  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _stateController.add(SignalingState.connecting);
    try {
      final uri = Uri.parse('${EnvConfig.current.wsBaseUrl}?room=$roomId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (rawMessage) {
          _handleIncomingMessage(rawMessage);
        },
        onDone: () => _stateController.add(SignalingState.disconnected),
        onError: (_) => _stateController.add(SignalingState.error),
      );

      _stateController.add(SignalingState.connected);
    } catch (_) {
      _stateController.add(SignalingState.error);
    }
  }

  void _handleIncomingMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String?;

      switch (type) {
        case 'peer_joined':
          _eventController.add(PeerJoinedEvent(map['peer_id'] as String));
          break;
        case 'peer_left':
          _eventController.add(PeerLeftEvent(map['peer_id'] as String));
          break;
        case 'offer':
          _eventController.add(
            OfferReceivedEvent(
              senderId: map['sender_id'] as String,
              sdp: map['sdp'] as String,
            ),
          );
          break;
        case 'answer':
          _eventController.add(
            AnswerReceivedEvent(
              senderId: map['sender_id'] as String,
              sdp: map['sdp'] as String,
            ),
          );
          break;
        case 'candidate':
          _eventController.add(
            IceCandidateReceivedEvent(
              senderId: map['sender_id'] as String,
              candidate: map['candidate'] as String,
              sdpMid: map['sdpMid'] as String,
              sdpMLineIndex: map['sdpMLineIndex'] as int,
            ),
          );
          break;
      }
    } catch (_) {
      // Błędy parsowania
    }
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  @override
  void sendOffer(String targetId, String sdp) {
    _send({'type': 'offer', 'target_id': targetId, 'sdp': sdp});
  }

  @override
  void sendAnswer(String targetId, String sdp) {
    _send({'type': 'answer', 'target_id': targetId, 'sdp': sdp});
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
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _stateController.add(SignalingState.disconnected);
  }
}
