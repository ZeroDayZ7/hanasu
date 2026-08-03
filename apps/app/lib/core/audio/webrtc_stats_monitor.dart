import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

Timer? startRtpStatsMonitoring({
  required RTCPeerConnection? peerConnection,
  Duration interval = const Duration(seconds: 2),
}) {
  return Timer.periodic(interval, (_) async {
    if (peerConnection == null) return;

    try {
      await peerConnection.getStats();
    } catch (_) {
      // Ignorujemy ew. błędy odczytu statystyk po zamknięciu połączenia
    }
  });
}