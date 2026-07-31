import 'dart:async';

import 'package:app/core/network/signaling_client.dart';

class MockSignalingClient implements SignalingClient {
  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();
  Timer? _peerConnectTimer;

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _stateController.add(SignalingState.connecting);
    await Future.delayed(const Duration(milliseconds: 600));
    _stateController.add(SignalingState.connected);

    // Symulacja dołączenia drugiego użytkownika po 2 sekundach
    _peerConnectTimer?.cancel();
    _peerConnectTimer = Timer(const Duration(seconds: 2), () {
      _eventController.add(PeerJoinedEvent('peer_mock_99'));
    });
  }

  @override
  Future<void> disconnect() async {
    _peerConnectTimer?.cancel();
    _stateController.add(SignalingState.disconnected);
  }

  @override
  void sendOffer(String targetId, String sdp) {}

  @override
  void sendAnswer(String targetId, String sdp) {}

  @override
  void sendIceCandidate(
    String targetId,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {}
}
