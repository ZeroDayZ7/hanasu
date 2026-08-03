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

  IceCandidateQueue? _iceQueue;
  Completer<RTCPeerConnection>? _peerConnectionCompleter;

  bool _isInitializing = false;
  bool _isInitialized = false;

  WebRtcService(this._logger, this._signalingClient);

  MediaStream? get remoteStream => _remoteStream;

  Future<void> initialize() async {
    if (_isInitializing || _isInitialized) return;

    _isInitializing = true;

    try {
      await _configureAudioSession();
      await _initLocalAudioStream();
      _subscribeToSignalingEvents();

      _isInitialized = true;
      _logger.i('WebRTC initialized successfully', module: 'WebRTC');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initLocalAudioStream() async {
    if (_localStream != null) return;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRtcConfig.audioConstraints,
      );

      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
    } catch (e, st) {
      _logger.e(
        'Failed to acquire local audio stream',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _subscribeToSignalingEvents() {
    _eventSubscription?.cancel();

    _eventSubscription = _signalingClient.eventStream.listen((event) async {
      try {
        final myPeerId = _signalingClient.peerId;

        switch (event) {
          case RoomJoinedEvent():
            break;

          case PeerJoinedEvent(:final peerId):
            if (peerId == myPeerId) return;

            _targetPeerId = peerId;
            final pc = await _ensurePeerConnection();

            final currentMyId = _signalingClient.peerId;
            final isInitiator = currentMyId != null && currentMyId.isNotEmpty
                ? currentMyId.compareTo(peerId) > 0
                : false;

            if (isInitiator) {
              await _triggerOffer(pc);
            }
            break;

          case PeerLeftEvent(:final peerId):
            if (_targetPeerId == peerId) {
              await closeConnection();
            }
            break;

          case OfferReceivedEvent(:final senderId, :final sdp):
            if (senderId == myPeerId) return;

            _targetPeerId = senderId;
            final pc = await _ensurePeerConnection();

            final currentMyId = (myPeerId != null && myPeerId.isNotEmpty)
                ? myPeerId
                : 'local_peer';

            await handleOfferAndSendAnswer(
              peerConnection: pc,
              myPeerId: currentMyId,
              targetPeerId: _targetPeerId!,
              offerSdp: sdp,
              signalingClient: _signalingClient,
              logger: _logger,
              onRemoteDescriptionSet: _onRemoteDescriptionSet,
            );
            break;

          case AnswerReceivedEvent(:final senderId, :final sdp):
            if (senderId == myPeerId || _peerConnection == null) return;

            await handleSdpAnswer(
              peerConnection: _peerConnection!,
              answerSdp: sdp,
              logger: _logger,
              onRemoteDescriptionSet: _onRemoteDescriptionSet,
            );
            break;

          case IceCandidateReceivedEvent(
            :final senderId,
            :final candidate,
            :final sdpMid,
            :final sdpMLineIndex,
          ):
            if (senderId == myPeerId) return;

            _iceQueue?.addCandidate(
              RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
            );
            break;

          default:
            break;
        }
      } catch (e, st) {
        _logger.e(
          'Error processing signaling event: ${event.runtimeType}',
          module: 'WebRTC',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    if (_peerConnection != null) {
      final state = await _peerConnection!.getSignalingState();
      if (state != RTCSignalingState.RTCSignalingStateClosed) {
        return _peerConnection!;
      }
    }

    if (_peerConnectionCompleter != null) {
      return await _peerConnectionCompleter!.future;
    }

    final completer = Completer<RTCPeerConnection>();
    _peerConnectionCompleter = completer;

    try {
      await _resetPeerConnection(keepLocalStream: true);
      final pc = await _createPeerConnectionInternal();
      completer.complete(pc);
      return pc;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _peerConnectionCompleter = null;
    }
  }

  Future<RTCPeerConnection> _createPeerConnectionInternal() async {
    await _configureAudioSession();

    final pc = await createPeerConnection(WebRtcConfig.rtcConfiguration);
    _peerConnection = pc;
    _iceQueue = IceCandidateQueue(_logger);

    _setupPeerConnectionListeners(pc);
    await _attachLocalAudioStream(pc);

    return pc;
  }

  void setMicrophoneMuted(bool muted) {
    if (_localStream == null) return;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      await Helper.setSpeakerphoneOn(enable);
    } catch (e, st) {
      _logger.e(
        'Failed to change speakerphone output',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _resetPeerConnection({bool keepLocalStream = false}) async {
    _statsTimer?.cancel();
    _statsTimer = null;

    await _iceQueue?.dispose();
    _iceQueue = null;

    if (!keepLocalStream && _localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _remoteStream = null;
  }

  Future<void> _triggerOffer(RTCPeerConnection pc) async {
    if (_targetPeerId == null) {
      _logger.w(
        'Aborted trigger offer: TargetPeerId is null',
        module: 'WebRTC',
      );
      return;
    }

    await createAndSendSdpOffer(
      peerConnection: pc,
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
      if (_localStream == null) {
        await _initLocalAudioStream();
      }

      if (_localStream == null || _peerConnection != pc) return;

      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    } catch (e, st) {
      _logger.e(
        'Error attaching local audio stream',
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
        _statsTimer = startRtpStatsMonitoring(peerConnection: pc);
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
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
      }
    };
  }

  Future<void> closeConnection() async {
    await _resetPeerConnection(keepLocalStream: false);
    _targetPeerId = null;
    _isInitialized = false;

    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e, st) {
      _logger.e(
        'Error deactivating Audio Session',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await closeConnection();
  }
}
