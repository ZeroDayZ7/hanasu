import 'dart:convert';

import 'package:app/core/network/signaling_client.dart';

/// Czysta, wyodrębniona funkcja mapująca surowy ciąg znaków WebSocket
/// na ścisłą hierarchię typów [SignalingEvent].
SignalingEvent? parseSignalingMessage(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final type = map['type'] as String?;

    return switch (type) {
      'peer_joined' => PeerJoinedEvent(_extractPeerId(map)),
      'peer_left' => PeerLeftEvent(_extractPeerId(map)),
      'offer' => OfferReceivedEvent(
        senderId: _extractSenderId(map),
        sdp: _extractSdp(map),
      ),
      'answer' => AnswerReceivedEvent(
        senderId: _extractSenderId(map),
        sdp: _extractSdp(map),
      ),
      'candidate' => IceCandidateReceivedEvent(
        senderId: _extractSenderId(map),
        candidate: _extractCandidate(map),
        sdpMid: _extractSdpMid(map),
        sdpMLineIndex: _extractSdpMLineIndex(map),
      ),
      _ => null,
    };
  } catch (_) {
    return null;
  }
}

// Private helpers do czyszczenia wyciągania zagnieżdżonych pól payloadu

String _extractPeerId(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['peer_id'] as String? ??
      map['peer_id'] as String? ??
      'unknown';
}

String _extractSenderId(Map<String, dynamic> map) {
  return map['sender'] as String? ?? map['sender_id'] as String? ?? '';
}

String _extractSdp(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['sdp'] as String? ?? map['sdp'] as String? ?? '';
}

String _extractCandidate(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['candidate'] as String? ?? map['candidate'] as String? ?? '';
}

String _extractSdpMid(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['sdpMid'] as String? ?? map['sdpMid'] as String? ?? '';
}

int _extractSdpMLineIndex(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['sdpMLineIndex'] as int? ?? map['sdpMLineIndex'] as int? ?? 0;
}
