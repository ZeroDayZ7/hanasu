import 'dart:async';

import 'package:app/core/audio/ice_candidates_handler.dart';
import 'package:app/core/audio/sdp_negotiation.dart';
import 'package:app/core/audio/webrtc_config.dart';
import 'package:app/core/audio/webrtc_stats_monitor.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final class WebRtcService {
  final AppLogger _logger;
  final SignalingClient _signalingClient;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  StreamSubscription<SignalingEvent>? _eventSubscription;
  Timer? _statsTimer;
  String? _targetPeerId;

  // Izolowana, reaktywna kolejka dla kandydatów ICE
  IceCandidateQueue? _iceQueue;

  WebRtcService(this._logger, this._signalingClient);

  MediaStream? get remoteStream => _remoteStream;

  void initialize() {
    _logger.i('Initializing WebRtcService...', module: 'WebRTC');

    _eventSubscription = _signalingClient.eventStream.listen((event) async {
      try {
        switch (event) {
          case PeerJoinedEvent(:final peerId):
            _targetPeerId = peerId;
            if (_peerConnection == null) {
              await _createPeerConnection();
              await _triggerOffer();
            }
            break;

          case PeerLeftEvent():
            await closeConnection();
            break;

          case OfferReceivedEvent(:final senderId, :final sdp):
            _targetPeerId = senderId;
            if (_peerConnection == null) await _createPeerConnection();
            await handleOfferAndSendAnswer(
              peerConnection: _peerConnection!,
              targetPeerId: _targetPeerId!,
              offerSdp: sdp,
              signalingClient: _signalingClient,
              logger: _logger,
              onRemoteDescriptionSet: _onRemoteDescriptionSet,
            );
            break;

          case AnswerReceivedEvent(:final sdp):
            if (_peerConnection == null) return;
            await handleSdpAnswer(
              peerConnection: _peerConnection!,
              answerSdp: sdp,
              logger: _logger,
              onRemoteDescriptionSet: _onRemoteDescriptionSet,
            );
            break;

          case IceCandidateReceivedEvent(
            :final candidate,
            :final sdpMid,
            :final sdpMLineIndex,
          ):
            // Zamiast mutowania tablicy, przekazujemy do izolowanej kolejki
            _iceQueue?.addCandidate(
              RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
            );
            break;

          default:
            break;
        }
      } catch (e, st) {
        _logger.e(
          'Error processing event',
          module: 'WebRTC',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  void setMicrophoneMuted(bool muted) {
    if (_localStream == null) return;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !muted;
    }
    _logger.i('Local audio track state: enabled = ${!muted}', module: 'WebRTC');
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    final pc = await createPeerConnection(WebRtcConfig.rtcConfiguration);
    _peerConnection = pc;

    // Reset kolejki dla nowego połączenia P2P
    await _iceQueue?.dispose();
    _iceQueue = IceCandidateQueue(_logger);

    _setupPeerConnectionListeners(pc);
    await _attachLocalAudioStream(pc);
  }

  Future<void> _triggerOffer() async {
    if (_peerConnection == null || _targetPeerId == null) return;

    await createAndSendSdpOffer(
      peerConnection: _peerConnection!,
      targetPeerId: _targetPeerId!,
      signalingClient: _signalingClient,
      logger: _logger,
    );
  }

  Future<void> _onRemoteDescriptionSet() async {
    if (_peerConnection != null) {
      _iceQueue?.markRemoteDescriptionReady(_peerConnection!);
    }
  }

  Future<void> _attachLocalAudioStream(RTCPeerConnection pc) async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRtcConfig.audioConstraints,
      );

      if (_peerConnection != pc) return;

      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }

      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    } catch (e, st) {
      _logger.e(
        'Microphone access error',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _setupPeerConnectionListeners(RTCPeerConnection pc) {
    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _statsTimer?.cancel();
        _statsTimer = startRtpStatsMonitoring(
          peerConnection: pc,
          logger: _logger,
        );
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _statsTimer?.cancel();
      }
    };

    pc.onIceCandidate = (candidate) {
      if (_targetPeerId != null && candidate.candidate?.isNotEmpty == true) {
        _signalingClient.sendIceCandidate(
          _targetPeerId!,
          candidate.candidate!,
          candidate.sdpMid ?? '',
          candidate.sdpMLineIndex ?? 0,
        );
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) _remoteStream = event.streams[0];
      if (event.track.kind == 'audio') event.track.enabled = true;
    };
  }

  Future<void> closeConnection() async {
    _statsTimer?.cancel();
    _statsTimer = null;

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    await _iceQueue?.dispose();
    _iceQueue = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    _targetPeerId = null;
  }
}
