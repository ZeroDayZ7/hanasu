import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Dodaje kandydata ICE lub zakolejkowuje go, jeśli połączenie nie jest jeszcze gotowe
Future<void> processOrQueueIceCandidate({
  required RTCPeerConnection? peerConnection,
  required RTCIceCandidate candidate,
  required bool isRemoteDescriptionSet,
  required List<RTCIceCandidate> pendingQueue,
  required AppLogger logger,
}) async {
  if (peerConnection == null) return;

  if (!isRemoteDescriptionSet) {
    logger.d(
      'Remote description not set. Queuing ICE candidate.',
      module: 'WebRTC',
    );
    pendingQueue.add(candidate);
    return;
  }

  try {
    await peerConnection.addCandidate(candidate);
    logger.t('Successfully added ICE candidate', module: 'WebRTC');
  } catch (e, st) {
    logger.e(
      'Failed to add ICE candidate',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}

/// Aplikuje zakolejkowanych kandydatów po ustawieniu RemoteDescription
Future<void> flushPendingIceCandidates({
  required RTCPeerConnection? peerConnection,
  required List<RTCIceCandidate> pendingQueue,
  required AppLogger logger,
}) async {
  if (pendingQueue.isEmpty || peerConnection == null) return;

  logger.d(
    'Processing ${pendingQueue.length} queued ICE candidates...',
    module: 'WebRTC',
  );
  for (final candidate in List<RTCIceCandidate>.from(pendingQueue)) {
    try {
      await peerConnection.addCandidate(candidate);
    } catch (e, st) {
      logger.e(
        'Failed to process queued ICE candidate',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }
  pendingQueue.clear();
}
