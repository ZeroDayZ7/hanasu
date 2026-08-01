import 'dart:async';

import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

Timer? startRtpStatsMonitoring({
  required RTCPeerConnection? peerConnection,
  required AppLogger logger,
  Duration interval = const Duration(seconds: 2),
}) {
  return Timer.periodic(interval, (_) async {
    if (peerConnection == null) return;

    try {
      final stats = await peerConnection.getStats();
      for (final report in stats) {
        if (report.type == 'inbound-rtp' && report.values['kind'] == 'audio') {
          logger.i(
            '[RTP INBOUND AUDIO] Bytes: ${report.values['bytesReceived']} | Packets: ${report.values['packetsReceived']}',
            module: 'WebRTC',
          );
        }
        if (report.type == 'outbound-rtp' && report.values['kind'] == 'audio') {
          logger.i(
            '[RTP OUTBOUND AUDIO] Bytes: ${report.values['bytesSent']} | Packets: ${report.values['packetsSent']}',
            module: 'WebRTC',
          );
        }
      }
    } catch (e) {
      logger.w('Failed to get RTC stats: $e', module: 'WebRTC');
    }
  });
}
