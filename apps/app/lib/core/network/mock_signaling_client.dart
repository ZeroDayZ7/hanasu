import 'dart:async';

import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';

final class MockSignalingClient implements SignalingClient {
  final AppLogger _logger;
  final _stateController = StreamController<SignalingState>.broadcast();
  final _eventController = StreamController<SignalingEvent>.broadcast();
  Timer? _peerConnectTimer;

  MockSignalingClient(this._logger);

  @override
  Stream<SignalingState> get stateStream => _stateController.stream;

  @override
  Stream<SignalingEvent> get eventStream => _eventController.stream;

  @override
  Future<void> connect(String roomId) async {
    _logger.i('Connecting to mock room: $roomId', module: 'MockSignaling');
    _stateController.add(SignalingState.connecting);

    await Future.delayed(const Duration(milliseconds: 600));
    _stateController.add(SignalingState.connected);
    _logger.i('Connected to mock room: $roomId', module: 'MockSignaling');

    _peerConnectTimer?.cancel();
    _peerConnectTimer = Timer(const Duration(seconds: 2), () {
      const peerId = 'peer_mock_99';
      _logger.d('Mock peer joined: $peerId', module: 'MockSignaling');
      _eventController.add(PeerJoinedEvent(peerId));
    });
  }

  @override
  Future<void> disconnect() async {
    _logger.i('Disconnecting from mock signaling', module: 'MockSignaling');
    _peerConnectTimer?.cancel();
    _stateController.add(SignalingState.disconnected);
  }

  @override
  void sendOffer(String targetId, String sdp) {
    _logger.d('Sending mock offer to: $targetId', module: 'MockSignaling');
  }

  @override
  void sendAnswer(String targetId, String sdp) {
    _logger.d('Sending mock answer to: $targetId', module: 'MockSignaling');
  }

  @override
  void sendIceCandidate(
    String targetId,
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) {
    _logger.t(
      'Sending mock ICE candidate to: $targetId ($sdpMid)',
      module: 'MockSignaling',
    );
  }
}
