import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Tworzy i wysyła ofertę SDP (Offerer)
Future<void> createAndSendSdpOffer({
  required RTCPeerConnection peerConnection,
  required String targetPeerId,
  required SignalingClient signalingClient,
  required AppLogger logger,
}) async {
  final state = await peerConnection.getSignalingState();
  if (state != RTCSignalingState.RTCSignalingStateStable) {
    logger.w('Skipping offer creation. State is $state', module: 'WebRTC');
    return;
  }

  try {
    final description = await peerConnection.createOffer();
    if (await peerConnection.getSignalingState() !=
        RTCSignalingState.RTCSignalingStateStable) {
      logger.w(
        'Signaling state changed while creating offer. Aborting.',
        module: 'WebRTC',
      );
      return;
    }

    await peerConnection.setLocalDescription(description);
    logger.d('Sending SDP Offer to -> $targetPeerId', module: 'WebRTC');
    signalingClient.sendOffer(targetPeerId, description.sdp!);
  } catch (e, st) {
    logger.e(
      'Failed to create/send offer',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}

/// Przetwarza otrzymaną ofertę i odsyła odpowiedź Answer
Future<void> handleOfferAndSendAnswer({
  required RTCPeerConnection peerConnection,
  required String targetPeerId,
  required String offerSdp,
  required SignalingClient signalingClient,
  required AppLogger logger,
  required Future<void> Function() onRemoteDescriptionSet,
}) async {
  try {
    final remoteDesc = RTCSessionDescription(offerSdp, 'offer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    logger.d('Sending SDP Answer to -> $targetPeerId', module: 'WebRTC');
    signalingClient.sendAnswer(targetPeerId, answer.sdp!);
  } catch (e, st) {
    logger.e(
      'Failed to handle offer and send answer',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}

/// Przetwarza odebraną odpowiedź Answer
Future<void> handleSdpAnswer({
  required RTCPeerConnection peerConnection,
  required String answerSdp,
  required AppLogger logger,
  required Future<void> Function() onRemoteDescriptionSet,
}) async {
  try {
    final remoteDesc = RTCSessionDescription(answerSdp, 'answer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();
    logger.i('WebRTC Handshake complete!', module: 'WebRTC');
  } catch (e, st) {
    logger.e(
      'Failed to handle answer',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}
