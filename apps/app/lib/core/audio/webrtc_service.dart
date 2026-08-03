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

  WebRtcService(this._logger, this._signalingClient);

  MediaStream? get remoteStream => _remoteStream;

  Future<void> initialize() async {
    _logger.i(
      '[webrtc_service.dart -> initialize -> 1.0 -> Start initialization]',
      module: 'WebRTC',
    );

    _logger.d(
      '[webrtc_service.dart -> initialize -> 1.1 -> Configuring Audio Session]',
      module: 'WebRTC',
    );
    await _configureAudioSession();

    _logger.d(
      '[webrtc_service.dart -> initialize -> 1.2 -> Initializing Local Audio Stream]',
      module: 'WebRTC',
    );
    await _initLocalAudioStream();

    _logger.d(
      '[webrtc_service.dart -> initialize -> 1.3 -> Subscribing to Signaling Events]',
      module: 'WebRTC',
    );
    _subscribeToSignalingEvents();

    _logger.i(
      '[webrtc_service.dart -> initialize -> 1.4 -> Initialization complete]',
      module: 'WebRTC',
    );
  }

  Future<void> _initLocalAudioStream() async {
    if (_localStream != null) {
      _logger.d(
        '[webrtc_service.dart -> _initLocalAudioStream -> 1.0 -> Local stream already exists, skipping]',
        module: 'WebRTC',
      );
      return;
    }

    try {
      _logger.d(
        '[webrtc_service.dart -> _initLocalAudioStream -> 1.1 -> Requesting getUserMedia]',
        module: 'WebRTC',
      );
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRtcConfig.audioConstraints,
      );

      _logger.d(
        '[webrtc_service.dart -> _initLocalAudioStream -> 1.2 -> Enabling audio tracks]',
        module: 'WebRTC',
      );
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
      _logger.i(
        '[webrtc_service.dart -> _initLocalAudioStream -> 1.3 -> Local stream acquired successfully]',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        '[webrtc_service.dart -> _initLocalAudioStream -> ERR -> Failed to acquire local audio stream]',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _subscribeToSignalingEvents() {
    _logger.d(
      '[webrtc_service.dart -> _subscribeToSignalingEvents -> 1.0 -> Cancelling existing subscription if any]',
      module: 'WebRTC',
    );
    _eventSubscription?.cancel();

    _eventSubscription = _signalingClient.eventStream.listen((event) async {
      try {
        final myPeerId = _signalingClient.peerId;
        _logger.d(
          '[webrtc_service.dart -> _subscribeToSignalingEvents -> 1.1 -> Event received: ${event.runtimeType} | myPeerId: $myPeerId]',
          module: 'WebRTC',
        );

        switch (event) {
          case RoomJoinedEvent(:final myPeerId):
            _logger.i(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 1.2 -> RoomJoinedEvent received | myPeerId: $myPeerId]',
              module: 'WebRTC',
            );
            break;

          case PeerJoinedEvent(:final peerId):
            _logger.i(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.0 -> PeerJoinedEvent for target: $peerId]',
              module: 'WebRTC',
            );
            if (peerId == myPeerId) {
              _logger.d(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.1 -> Ignored PeerJoinedEvent for self]',
                module: 'WebRTC',
              );
              return;
            }

            _targetPeerId = peerId;
            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.2 -> Ensuring PeerConnection is active]',
              module: 'WebRTC',
            );
            final pc = await _ensurePeerConnection();

            final currentMyId = _signalingClient.peerId;
            final isInitiator = currentMyId != null && currentMyId.isNotEmpty
                ? currentMyId.compareTo(peerId) > 0
                : false;

            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.4 -> Role Evaluation | currentMyId: $currentMyId, targetPeerId: $peerId, isInitiator: $isInitiator]',
              module: 'WebRTC',
            );

            if (isInitiator) {
              _logger.i(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.5 -> Impolite peer (Initiator) triggering SDP Offer]',
                module: 'WebRTC',
              );
              await _triggerOffer(pc);
            } else {
              _logger.i(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 2.5 -> Polite peer waiting for remote SDP offer from $peerId]',
                module: 'WebRTC',
              );
            }
            break;

          case PeerLeftEvent(:final peerId):
            _logger.i(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 3.0 -> PeerLeftEvent for target: $peerId]',
              module: 'WebRTC',
            );
            if (_targetPeerId == peerId) {
              _logger.d(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 3.1 -> Target peer left. Closing connection]',
                module: 'WebRTC',
              );
              await closeConnection();
            }
            break;

          case OfferReceivedEvent(:final senderId, :final sdp):
            _logger.i(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 4.0 -> OfferReceivedEvent from sender: $senderId]',
              module: 'WebRTC',
            );
            if (senderId == myPeerId) {
              _logger.d(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 4.1 -> Ignored self-sent offer]',
                module: 'WebRTC',
              );
              return;
            }

            _targetPeerId = senderId;
            final pc = await _ensurePeerConnection();

            final currentMyId = (myPeerId != null && myPeerId.isNotEmpty)
                ? myPeerId
                : 'local_peer';

            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 4.4 -> Delegating to handleOfferAndSendAnswer]',
              module: 'WebRTC',
            );
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
            _logger.i(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 5.0 -> AnswerReceivedEvent from sender: $senderId]',
              module: 'WebRTC',
            );
            if (senderId == myPeerId || _peerConnection == null) {
              _logger.d(
                '[webrtc_service.dart -> _subscribeToSignalingEvents -> 5.1 -> Ignored AnswerReceivedEvent (self-sent or null PC)]',
                module: 'WebRTC',
              );
              return;
            }

            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 5.2 -> Delegating to handleSdpAnswer]',
              module: 'WebRTC',
            );
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
            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 6.0 -> IceCandidateReceivedEvent from: $senderId]',
              module: 'WebRTC',
            );
            if (senderId == myPeerId) return;

            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 6.1 -> Enqueuing ICE Candidate]',
              module: 'WebRTC',
            );
            _iceQueue?.addCandidate(
              RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
            );
            break;

          default:
            _logger.d(
              '[webrtc_service.dart -> _subscribeToSignalingEvents -> 7.0 -> Unhandled event: ${event.runtimeType}]',
              module: 'WebRTC',
            );
            break;
        }
      } catch (e, st) {
        _logger.e(
          '[webrtc_service.dart -> _subscribeToSignalingEvents -> ERR -> Error processing signaling event]',
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
    _logger.d(
      '[webrtc_service.dart -> _createPeerConnectionInternal -> 1.1 -> Re-configuring audio session]',
      module: 'WebRTC',
    );
    await _configureAudioSession();

    _logger.d(
      '[webrtc_service.dart -> _createPeerConnectionInternal -> 1.2 -> Creating WebRTC PeerConnection]',
      module: 'WebRTC',
    );
    final pc = await createPeerConnection(WebRtcConfig.rtcConfiguration);
    _peerConnection = pc;

    _iceQueue = IceCandidateQueue(_logger);

    _logger.d(
      '[webrtc_service.dart -> _createPeerConnectionInternal -> 1.3 -> Setting up listeners and attaching local audio]',
      module: 'WebRTC',
    );
    _setupPeerConnectionListeners(pc);
    await _attachLocalAudioStream(pc);

    return pc;
  }

  void setMicrophoneMuted(bool muted) {
    if (_localStream == null) return;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !muted;
    }
    _logger.i(
      '[webrtc_service.dart -> setMicrophoneMuted -> 1.0 -> Local audio track state: enabled = ${!muted}]',
      module: 'WebRTC',
    );
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _logger.i(
        '[webrtc_service.dart -> setSpeakerphoneOn -> 1.0 -> Speakerphone toggle ignored on non-mobile platform]',
        module: 'WebRTC',
      );
      return;
    }

    try {
      await Helper.setSpeakerphoneOn(enable);
      _logger.i(
        '[webrtc_service.dart -> setSpeakerphoneOn -> 1.1 -> Speakerphone output set to: $enable]',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        '[webrtc_service.dart -> setSpeakerphoneOn -> ERR -> Failed to change speakerphone output]',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _resetPeerConnection({bool keepLocalStream = false}) async {
    _logger.d(
      '[webrtc_service.dart -> _resetPeerConnection -> 1.0 -> Starting reset process (keepLocalStream: $keepLocalStream)]',
      module: 'WebRTC',
    );

    _statsTimer?.cancel();
    _statsTimer = null;

    await _iceQueue?.dispose();
    _iceQueue = null;

    if (!keepLocalStream && _localStream != null) {
      _logger.d(
        '[webrtc_service.dart -> _resetPeerConnection -> 1.1 -> Disposing local stream]',
        module: 'WebRTC',
      );
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      _logger.d(
        '[webrtc_service.dart -> _resetPeerConnection -> 1.2 -> Closing and disposing PeerConnection]',
        module: 'WebRTC',
      );
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _remoteStream = null;
    _logger.d(
      '[webrtc_service.dart -> _resetPeerConnection -> 1.3 -> Reset completed]',
      module: 'WebRTC',
    );
  }

  Future<void> _triggerOffer(RTCPeerConnection pc) async {
    _logger.d(
      '[webrtc_service.dart -> _triggerOffer -> 1.0 -> Attempting to trigger offer | targetPeerId: $_targetPeerId]',
      module: 'WebRTC',
    );
    if (_targetPeerId == null) {
      _logger.w(
        '[webrtc_service.dart -> _triggerOffer -> 1.1 -> Aborted trigger: TargetPeerId is null]',
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
    _logger.d(
      '[webrtc_service.dart -> _onRemoteDescriptionSet -> 1.0 -> Remote description applied successfully. Marking ICE queue ready]',
      module: 'WebRTC',
    );
    if (_peerConnection != null) {
      _iceQueue?.markRemoteDescriptionReady(_peerConnection!);
    }
  }

  Future<void> _attachLocalAudioStream(RTCPeerConnection pc) async {
    try {
      _logger.d(
        '[webrtc_service.dart -> _attachLocalAudioStream -> 1.0 -> Attaching local tracks]',
        module: 'WebRTC',
      );
      if (_localStream == null) {
        await _initLocalAudioStream();
      }

      if (_localStream == null || _peerConnection != pc) {
        _logger.w(
          '[webrtc_service.dart -> _attachLocalAudioStream -> 1.1 -> Stream null or PC mismatch]',
          module: 'WebRTC',
        );
        return;
      }

      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
      _logger.d(
        '[webrtc_service.dart -> _attachLocalAudioStream -> 1.2 -> Local tracks attached successfully]',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        '[webrtc_service.dart -> _attachLocalAudioStream -> ERR -> Error attaching local audio stream]',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      _logger.d(
        '[webrtc_service.dart -> _configureAudioSession -> 1.0 -> Requesting AudioSession instance]',
        module: 'WebRTC',
      );
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
        '[webrtc_service.dart -> _configureAudioSession -> 1.1 -> Audio session configured for Earpiece Voice Communication]',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        '[webrtc_service.dart -> _configureAudioSession -> ERR -> Failed to configure Audio Session]',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _setupPeerConnectionListeners(RTCPeerConnection pc) {
    _logger.d(
      '[webrtc_service.dart -> _setupPeerConnectionListeners -> 1.0 -> Setting up listeners]',
      module: 'WebRTC',
    );

    pc.onIceConnectionState = (state) {
      _logger.d(
        '[webrtc_service.dart -> _setupPeerConnectionListeners -> 1.1 -> ICE Connection State changed: $state]',
        module: 'WebRTC',
      );
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
      _logger.d(
        '[webrtc_service.dart -> _setupPeerConnectionListeners -> 1.2 -> Local ICE Candidate generated: ${candidate.candidate}]',
        module: 'WebRTC',
      );
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
      _logger.d(
        '[webrtc_service.dart -> _setupPeerConnectionListeners -> 1.3 -> Remote track received: ${event.track.kind}]',
        module: 'WebRTC',
      );
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
      }
    };
  }

  Future<void> closeConnection() async {
    _logger.i(
      '[webrtc_service.dart -> closeConnection -> 1.0 -> Closing connection]',
      module: 'WebRTC',
    );
    await _resetPeerConnection(keepLocalStream: false);
    _targetPeerId = null;

    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
      _logger.i(
        '[webrtc_service.dart -> closeConnection -> 1.1 -> Audio session deactivated]',
        module: 'WebRTC',
      );
    } catch (e) {
      _logger.e(
        '[webrtc_service.dart -> closeConnection -> ERR -> Error deactivating Audio Session]',
        module: 'WebRTC',
        error: e,
      );
    }
  }

  Future<void> dispose() async {
    _logger.i(
      '[webrtc_service.dart -> dispose -> 1.0 -> Disposing service]',
      module: 'WebRTC',
    );
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await closeConnection();
  }
}
