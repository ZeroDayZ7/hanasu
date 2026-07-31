import 'dart:async';

enum SignalingState { disconnected, connecting, connected, error }

abstract class SignalingEvent {}

class PeerJoinedEvent extends SignalingEvent {
  final String peerId;
  PeerJoinedEvent(this.peerId);
}

class PeerLeftEvent extends SignalingEvent {
  final String peerId;
  PeerLeftEvent(this.peerId);
}

class OfferReceivedEvent extends SignalingEvent {
  final String senderId;
  final String sdp;
  OfferReceivedEvent({required this.senderId, required this.sdp});
}

class AnswerReceivedEvent extends SignalingEvent {
  final String senderId;
  final String sdp;
  AnswerReceivedEvent({required this.senderId, required this.sdp});
}

class IceCandidateReceivedEvent extends SignalingEvent {
  final String senderId;
  final String candidate;
  final String sdpMid;
  final int sdpMLineIndex;

  IceCandidateReceivedEvent({
    required this.senderId,
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });
}

abstract class SignalingClient {
  Stream<SignalingState> get stateStream;
  Stream<SignalingEvent> get eventStream;

  Future<void> connect(String roomId);
  Future<void> disconnect();

  void sendOffer(String targetId, String sdp);
  void sendAnswer(String targetId, String sdp);
  void sendIceCandidate(String targetId, String candidate, String sdpMid, int sdpMLineIndex);
}