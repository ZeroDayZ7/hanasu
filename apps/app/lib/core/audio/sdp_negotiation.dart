import 'package:app/core/audio/sdp_validator.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

Future<void> createAndSendSdpOffer({
  required RTCPeerConnection peerConnection,
  required String targetPeerId,
  required SignalingClient signalingClient,
  required AppLogger logger,
}) async {
  if (targetPeerId.trim().isEmpty) {
    logger.w('Cannot send offer: targetPeerId is empty.', module: 'WebRTC');
    return;
  }

  try {
    final initialState = await peerConnection.getSignalingState();
    if (initialState == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        'PeerConnection is closed. Aborting offer creation.',
        module: 'WebRTC',
      );
      return;
    }

    if (initialState != RTCSignalingState.RTCSignalingStateStable) {
      logger.w(
        'Skipping offer creation. PeerConnection state is $initialState (expected stable).',
        module: 'WebRTC',
      );
      return;
    }

    final description = await peerConnection.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
      'optional': [],
    });

    final stateBeforeSetLocal = await peerConnection.getSignalingState();
    if (stateBeforeSetLocal != RTCSignalingState.RTCSignalingStateStable) {
      logger.w(
        'Signaling state changed to $stateBeforeSetLocal during offer creation. Aborting local description set.',
        module: 'WebRTC',
      );
      return;
    }

    final sdp = description.sdp;
    if (sdp == null || !SdpValidator.isValidSdp(sdp, expectedType: 'offer')) {
      logger.e(
        'Generated local SDP offer failed Zero-Trust validation. Aborting send.',
        module: 'WebRTC',
      );
      return;
    }

    await peerConnection.setLocalDescription(description);

    final finalState = await peerConnection.getSignalingState();
    if (finalState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      logger.d('Sending SDP Offer to -> $targetPeerId', module: 'WebRTC');
      signalingClient.sendOffer(targetPeerId, sdp);
    } else {
      logger.w(
        'Unexpected signaling state $finalState after setLocalDescription. Skipping signal transport.',
        module: 'WebRTC',
      );
    }
  } catch (e, st) {
    logger.e(
      'Failed to create/send offer to $targetPeerId',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}

Future<void> handleOfferAndSendAnswer({
  required RTCPeerConnection peerConnection,
  required String myPeerId,
  required String targetPeerId,
  required String offerSdp,
  required SignalingClient signalingClient,
  required AppLogger logger,
  required Future<void> Function() onRemoteDescriptionSet,
}) async {
  if (targetPeerId.trim().isEmpty || myPeerId.trim().isEmpty) {
    logger.w(
      'Missing valid peer identifiers for incoming offer handling.',
      module: 'WebRTC',
    );
    return;
  }

  if (!SdpValidator.isValidSdp(offerSdp, expectedType: 'offer')) {
    logger.w(
      'Rejected incoming SDP offer from $targetPeerId due to failed Zero-Trust validation.',
      module: 'WebRTC',
    );
    return;
  }

  try {
    final state = await peerConnection.getSignalingState();
    if (state == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        'PeerConnection is closed. Cannot process offer from $targetPeerId.',
        module: 'WebRTC',
      );
      return;
    }

    final isOfferCollision = state != RTCSignalingState.RTCSignalingStateStable;
    final isPolite = myPeerId.compareTo(targetPeerId) < 0;

    if (isOfferCollision) {
      if (!isPolite) {
        logger.w(
          'Offer collision detected in state $state. Impolite peer ignoring incoming offer from $targetPeerId.',
          module: 'WebRTC',
        );
        return;
      }

      logger.i(
        'Offer collision detected in state $state. Polite peer rolling back local description.',
        module: 'WebRTC',
      );

      try {
        await peerConnection.setLocalDescription(
          RTCSessionDescription('', 'rollback'),
        );
      } catch (e) {
        logger.w(
          'Rollback rejected by WebRTC engine (state $state). Attempting forced remote update.',
          module: 'WebRTC',
          error: e,
        );
      }
    }

    final remoteDesc = RTCSessionDescription(offerSdp, 'offer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();

    final stateBeforeAnswer = await peerConnection.getSignalingState();
    if (stateBeforeAnswer !=
        RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
      logger.w(
        'Signaling state changed to $stateBeforeAnswer before creating answer. Aborting negotiation.',
        module: 'WebRTC',
      );
      return;
    }

    final answer = await peerConnection.createAnswer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
      'optional': [],
    });

    final answerSdp = answer.sdp;
    if (answerSdp == null ||
        !SdpValidator.isValidSdp(answerSdp, expectedType: 'answer')) {
      logger.e(
        'Generated local SDP answer failed Zero-Trust validation. Aborting send.',
        module: 'WebRTC',
      );
      return;
    }

    await peerConnection.setLocalDescription(answer);

    logger.d('Sending SDP Answer to -> $targetPeerId', module: 'WebRTC');
    signalingClient.sendAnswer(targetPeerId, answerSdp);
  } catch (e, st) {
    logger.e(
      'Failed to handle offer and send answer to $targetPeerId',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}

Future<void> handleSdpAnswer({
  required RTCPeerConnection peerConnection,
  required String answerSdp,
  required AppLogger logger,
  required Future<void> Function() onRemoteDescriptionSet,
}) async {
  if (!SdpValidator.isValidSdp(answerSdp, expectedType: 'answer')) {
    logger.w(
      'Rejected incoming SDP answer due to failed Zero-Trust validation.',
      module: 'WebRTC',
    );
    return;
  }

  try {
    final state = await peerConnection.getSignalingState();

    if (state == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        'PeerConnection is closed. Cannot apply remote answer.',
        module: 'WebRTC',
      );
      return;
    }

    if (state != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      logger.w(
        'Ignoring SDP answer. PeerConnection is in state $state (expected have-local-offer).',
        module: 'WebRTC',
      );
      return;
    }

    final remoteDesc = RTCSessionDescription(answerSdp, 'answer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();

    logger.i('WebRTC Handshake completed successfully.', module: 'WebRTC');
  } catch (e, st) {
    logger.e(
      'Failed to apply remote SDP answer',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}
