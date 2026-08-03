import 'dart:convert';

import 'package:app/core/network/signaling_client.dart';

/// Parsuje pojedynczy ciąg znaków (może zawierać wiele obiektów połączonych `\n`)
/// i zwraca listę rozpoznanych zdarzeń [SignalingEvent].
List<SignalingEvent> parseSignalingMessages(String raw) {
  final events = <SignalingEvent>[];

  // Obsługa wielu ramek JSON przesłanych w jednym strumieniu (rozdzielonych \n)
  final lines = raw.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    try {
      final map = jsonDecode(trimmed) as Map<String, dynamic>;
      final event = _parseSingleMessage(map);
      if (event != null) {
        events.add(event);
      }
    } catch (_) {
      // Ignorujemy niepoprawne lub uszkodzone pakiety JSON
    }
  }

  return events;
}

/// Główny parser dla pojedynczej mapy JSON.
SignalingEvent? parseSignalingMessage(String raw) {
  final events = parseSignalingMessages(raw);
  return events.isNotEmpty ? events.first : null;
}

SignalingEvent? _parseSingleMessage(Map<String, dynamic> map) {
  final type = map['type'] as String?;

  return switch (type) {
    'room_joined' => RoomJoinedEvent(_extractPeerId(map)),
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
}

// Private helpers do czyszczenia wyciągania zagnieżdżonych pól payloadu

String _extractPeerId(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  return payload?['peer_id'] as String? ??
      payload?['my_peer_id'] as String? ??
      map['peer_id'] as String? ??
      map['my_peer_id'] as String? ??
      map['sender'] as String? ??
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
  return payload?['sdpMid'] as String? ??
      payload?['sdp_mid'] as String? ??
      map['sdpMid'] as String? ??
      map['sdp_mid'] as String? ??
      '';
}

int _extractSdpMLineIndex(Map<String, dynamic> map) {
  final payload = map['payload'] as Map<String, dynamic>?;
  final val =
      payload?['sdpMLineIndex'] ??
      payload?['sdp_m_line_index'] ??
      map['sdpMLineIndex'] ??
      map['sdp_m_line_index'];

  if (val is num) {
    return val.toInt();
  }
  return 0;
}
