import 'dart:async';
import 'dart:io';

import 'package:app/core/audio/ice_candidates_handler.dart';
import 'package:app/core/audio/sdp_negotiation.dart';
import 'package:app/core/audio/webrtc_config.dart';
import 'package:app/core/audio/webrtc_stats_monitor.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> initialize() async {
    _logger.i('Initializing WebRtcService...', module: 'WebRTC');

    // 1. Inicjalizacja profesjonalnej sesji Audio VoIP przed przechwyceniem mikrofonu
    await _configureAudioSession();

    // 2. Subskrypcja zdarzeń sygnalizacyjnych
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

  Future<void> setSpeakerphoneOn(bool enable) async {
    // Przełączanie głośnika ma sens tylko na urządzeniach mobilnych
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _logger.i(
        'Speakerphone toggle ignored on non-mobile platform',
        module: 'WebRTC',
      );
      return;
    }

    try {
      await Helper.setSpeakerphoneOn(enable);
      _logger.i('Speakerphone output set to: $enable', module: 'WebRTC');
    } catch (e, st) {
      _logger.e(
        'Failed to change speakerphone output',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    final pc = await createPeerConnection(WebRtcConfig.rtcConfiguration);
    _peerConnection = pc;

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

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        ),
      );
      await session.setActive(true);

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Helper.setSpeakerphoneOn(false);
      }

      _logger.i(
        'Audio session configured for Earpiece Voice Communication',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        'Failed to configure Audio Session',
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

    // Dezaktywacja sesji Audio i powrót systemu do normalnego trybu odtwarzania dźwięków
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
      _logger.i('Audio session deactivated', module: 'WebRTC');
    } catch (e) {
      _logger.e('Error deactivating Audio Session', module: 'WebRTC', error: e);
    }
  }
}
