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
  logger.d(
    '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.0 -> Initiating offer creation for target: $targetPeerId]',
    module: 'WebRTC',
  );

  if (targetPeerId.trim().isEmpty) {
    logger.w(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.1 -> Cannot send offer: targetPeerId is empty]',
      module: 'WebRTC',
    );
    return;
  }

  try {
    final initialState = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.2 -> PeerConnection initial signaling state: $initialState]',
      module: 'WebRTC',
    );

    if (initialState == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.3 -> PeerConnection is closed. Aborting offer creation]',
        module: 'WebRTC',
      );
      return;
    }

    if (initialState != RTCSignalingState.RTCSignalingStateStable) {
      logger.w(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.4 -> Skipping offer creation. PeerConnection state is $initialState (expected stable)]',
        module: 'WebRTC',
      );
      return;
    }

    logger.d(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.5 -> Calling peerConnection.createOffer]',
      module: 'WebRTC',
    );
    final description = await peerConnection.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
      'optional': [],
    });

    final stateBeforeSetLocal = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.6 -> Signaling state before setLocalDescription: $stateBeforeSetLocal]',
      module: 'WebRTC',
    );

    if (stateBeforeSetLocal != RTCSignalingState.RTCSignalingStateStable) {
      logger.w(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.7 -> Signaling state changed to $stateBeforeSetLocal during offer creation. Aborting local description set]',
        module: 'WebRTC',
      );
      return;
    }

    final sdp = description.sdp;
    if (sdp == null || !SdpValidator.isValidSdp(sdp, expectedType: 'offer')) {
      logger.e(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> ERR -> Generated local SDP offer failed Zero-Trust validation. Aborting send]',
        module: 'WebRTC',
      );
      return;
    }

    logger.d(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.8 -> Applying setLocalDescription (offer)]',
      module: 'WebRTC',
    );
    await peerConnection.setLocalDescription(description);

    final finalState = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> 1.9 -> Final signaling state: $finalState]',
      module: 'WebRTC',
    );

    if (finalState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      logger.i(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> 2.0 -> Sending SDP Offer via signaling to -> $targetPeerId]',
        module: 'WebRTC',
      );
      signalingClient.sendOffer(targetPeerId, sdp);
    } else {
      logger.w(
        '[sdp_negotiation.dart -> createAndSendSdpOffer -> 2.1 -> Unexpected signaling state $finalState after setLocalDescription. Skipping signal transport]',
        module: 'WebRTC',
      );
    }
  } catch (e, st) {
    logger.e(
      '[sdp_negotiation.dart -> createAndSendSdpOffer -> ERR -> Failed to create/send offer to $targetPeerId]',
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
  logger.d(
    '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.0 -> Handling incoming offer from: $targetPeerId]',
    module: 'WebRTC',
  );

  if (targetPeerId.trim().isEmpty || myPeerId.trim().isEmpty) {
    logger.w(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.1 -> Missing valid peer identifiers for incoming offer handling]',
      module: 'WebRTC',
    );
    return;
  }

  if (!SdpValidator.isValidSdp(offerSdp, expectedType: 'offer')) {
    logger.w(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.2 -> Rejected incoming SDP offer from $targetPeerId due to failed Zero-Trust validation]',
      module: 'WebRTC',
    );
    return;
  }

  try {
    final state = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.3 -> Current signaling state: $state]',
      module: 'WebRTC',
    );

    if (state == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.4 -> PeerConnection is closed. Cannot process offer from $targetPeerId]',
        module: 'WebRTC',
      );
      return;
    }

    final isOfferCollision = state != RTCSignalingState.RTCSignalingStateStable;
    final isPolite = myPeerId.compareTo(targetPeerId) < 0;

    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.5 -> Collision state: $isOfferCollision | isPolite: $isPolite]',
      module: 'WebRTC',
    );

    if (isOfferCollision) {
      if (!isPolite) {
        logger.w(
          '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.6 -> Offer collision in state $state. Impolite peer ignoring incoming offer from $targetPeerId]',
          module: 'WebRTC',
        );
        return;
      }

      logger.i(
        '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.6 -> Offer collision in state $state. Polite peer rolling back local description]',
        module: 'WebRTC',
      );

      try {
        await peerConnection.setLocalDescription(
          RTCSessionDescription('', 'rollback'),
        );
        logger.d(
          '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.7 -> Rollback successful]',
          module: 'WebRTC',
        );
      } catch (e) {
        logger.w(
          '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.7 -> Rollback rejected by WebRTC engine (state $state). Attempting forced remote update]',
          module: 'WebRTC',
          error: e,
        );
      }
    }

    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.8 -> Setting Remote Description (offer)]',
      module: 'WebRTC',
    );
    final remoteDesc = RTCSessionDescription(offerSdp, 'offer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();

    final stateBeforeAnswer = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 1.9 -> Signaling state before answer creation: $stateBeforeAnswer]',
      module: 'WebRTC',
    );

    if (stateBeforeAnswer !=
        RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
      logger.w(
        '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 2.0 -> Signaling state changed to $stateBeforeAnswer before creating answer. Aborting negotiation]',
        module: 'WebRTC',
      );
      return;
    }

    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 2.1 -> Calling peerConnection.createAnswer]',
      module: 'WebRTC',
    );
    final answer = await peerConnection.createAnswer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
      'optional': [],
    });

    final answerSdp = answer.sdp;
    if (answerSdp == null ||
        !SdpValidator.isValidSdp(answerSdp, expectedType: 'answer')) {
      logger.e(
        '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> ERR -> Generated local SDP answer failed Zero-Trust validation. Aborting send]',
        module: 'WebRTC',
      );
      return;
    }

    logger.d(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 2.2 -> Applying setLocalDescription (answer)]',
      module: 'WebRTC',
    );
    await peerConnection.setLocalDescription(answer);

    logger.i(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> 2.3 -> Sending SDP Answer via signaling to -> $targetPeerId]',
      module: 'WebRTC',
    );
    signalingClient.sendAnswer(targetPeerId, answerSdp);
  } catch (e, st) {
    logger.e(
      '[sdp_negotiation.dart -> handleOfferAndSendAnswer -> ERR -> Failed to handle offer and send answer to $targetPeerId]',
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
  logger.d(
    '[sdp_negotiation.dart -> handleSdpAnswer -> 1.0 -> Handling incoming SDP answer]',
    module: 'WebRTC',
  );

  if (!SdpValidator.isValidSdp(answerSdp, expectedType: 'answer')) {
    logger.w(
      '[sdp_negotiation.dart -> handleSdpAnswer -> 1.1 -> Rejected incoming SDP answer due to failed Zero-Trust validation]',
      module: 'WebRTC',
    );
    return;
  }

  try {
    final state = await peerConnection.getSignalingState();
    logger.d(
      '[sdp_negotiation.dart -> handleSdpAnswer -> 1.2 -> Current signaling state: $state]',
      module: 'WebRTC',
    );

    if (state == RTCSignalingState.RTCSignalingStateClosed) {
      logger.w(
        '[sdp_negotiation.dart -> handleSdpAnswer -> 1.3 -> PeerConnection is closed. Cannot apply remote answer]',
        module: 'WebRTC',
      );
      return;
    }

    if (state != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      logger.w(
        '[sdp_negotiation.dart -> handleSdpAnswer -> 1.4 -> Ignoring SDP answer. PeerConnection is in state $state (expected have-local-offer)]',
        module: 'WebRTC',
      );
      return;
    }

    logger.d(
      '[sdp_negotiation.dart -> handleSdpAnswer -> 1.5 -> Applying setRemoteDescription (answer)]',
      module: 'WebRTC',
    );
    final remoteDesc = RTCSessionDescription(answerSdp, 'answer');
    await peerConnection.setRemoteDescription(remoteDesc);
    await onRemoteDescriptionSet();

    logger.i(
      '[sdp_negotiation.dart -> handleSdpAnswer -> 1.6 -> WebRTC Handshake completed successfully]',
      module: 'WebRTC',
    );
  } catch (e, st) {
    logger.e(
      '[sdp_negotiation.dart -> handleSdpAnswer -> ERR -> Failed to apply remote SDP answer]',
      module: 'WebRTC',
      error: e,
      stackTrace: st,
    );
  }
}
