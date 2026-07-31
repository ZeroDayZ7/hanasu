// lib/core/audio/webrtc_service.dart
import 'dart:async';

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
  String? _targetPeerId;

  // Kolejka na kandydatów ICE przybyłych przed ustawieniem Remote Description
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _isRemoteDescriptionSet = false;

  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'mandatory': {
        'echoCancellation': 'true',
        'noiseSuppression': 'true',
        'autoGainControl': 'true',
      },
      'optional': [],
    },
    'video': false,
  };

  WebRtcService(this._logger, this._signalingClient);

  MediaStream? get remoteStream => _remoteStream;

  /// Inicjalizacja nasłuchiwania na zdarzenia sygnalizacyjne z backendu
  void initialize() {
    _logger.i('Initializing WebRtcService...', module: 'WebRTC');

    _eventSubscription = _signalingClient.eventStream.listen((event) async {
      try {
        switch (event) {
          case PeerJoinedEvent(:final peerId):
            _logger.i(
              'Peer joined ($peerId). Preparing WebRTC connection...',
              module: 'WebRTC',
            );
            _targetPeerId = peerId;
            await _createPeerConnection();
            await _createAndSendOffer();
            break;

          case PeerLeftEvent(:final peerId):
            _logger.w(
              'Peer left ($peerId). Closing WebRTC connection.',
              module: 'WebRTC',
            );
            await closeConnection();
            break;

          case OfferReceivedEvent(:final senderId, :final sdp):
            _logger.i(
              'Received offer from $senderId. Creating answer...',
              module: 'WebRTC',
            );
            _targetPeerId = senderId;
            await _createPeerConnection();
            await _handleOfferAndSendAnswer(sdp);
            break;

          case AnswerReceivedEvent(:final senderId, :final sdp):
            _logger.i(
              'Received answer from $senderId. Setting remote description...',
              module: 'WebRTC',
            );
            await _handleAnswer(sdp);
            break;

          case IceCandidateReceivedEvent(
            :final senderId,
            :final candidate,
            :final sdpMid,
            :final sdpMLineIndex,
          ):
            _logger.t(
              'Received ICE candidate from $senderId',
              module: 'WebRTC',
            );
            await _addIceCandidate(candidate, sdpMid, sdpMLineIndex);
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

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    _logger.d('Creating RTCPeerConnection...', module: 'WebRTC');
    _peerConnection = await createPeerConnection(_rtcConfiguration);
    _isRemoteDescriptionSet = false;
    _pendingIceCandidates.clear();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        _mediaConstraints,
      );

      // Domyślnie mikrofon wyciszony (tryb Push-to-Talk)
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = false;
      }

      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
      _logger.i(
        'Local audio track added to PeerConnection (muted initially)',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        'Failed to get user media (microphone access)',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_targetPeerId != null && candidate.candidate != null) {
        _logger.t(
          'Sending local ICE candidate to -> $_targetPeerId',
          module: 'WebRTC',
        );
        _signalingClient.sendIceCandidate(
          _targetPeerId!,
          candidate.candidate!,
          candidate.sdpMid ?? '',
          candidate.sdpMLineIndex ?? 0,
        );
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      _logger.i('Remote audio track received!', module: 'WebRTC');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      _logger.d('ICE Connection State: $state', module: 'WebRTC');
    };
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _targetPeerId == null) return;

    // Zabezpieczenie przed konfliktem ofert (Race condition / Glare)
    final signalingState = await _peerConnection!.getSignalingState();
    if (signalingState != RTCSignalingState.RTCSignalingStateStable) {
      _logger.w(
        'Skipping offer creation. PeerConnection not in stable state ($signalingState)',
        module: 'WebRTC',
      );
      return;
    }

    try {
      final description = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(description);

      _logger.d('Sending SDP Offer to -> $_targetPeerId', module: 'WebRTC');
      _signalingClient.sendOffer(_targetPeerId!, description.sdp!);
    } catch (e, st) {
      _logger.e(
        'Failed to create/send offer',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _handleOfferAndSendAnswer(String sdp) async {
    if (_peerConnection == null || _targetPeerId == null) return;

    try {
      final remoteDesc = RTCSessionDescription(sdp, 'offer');
      await _peerConnection!.setRemoteDescription(remoteDesc);
      _isRemoteDescriptionSet = true;

      // Przetwarzanie spiętrzonych kandydatów ICE
      await _processPendingIceCandidates();

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _logger.d('Sending SDP Answer to -> $_targetPeerId', module: 'WebRTC');
      _signalingClient.sendAnswer(_targetPeerId!, answer.sdp!);
    } catch (e, st) {
      _logger.e(
        'Failed to handle offer and send answer',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _handleAnswer(String sdp) async {
    if (_peerConnection == null) return;

    try {
      final remoteDesc = RTCSessionDescription(sdp, 'answer');
      await _peerConnection!.setRemoteDescription(remoteDesc);
      _isRemoteDescriptionSet = true;

      // Przetwarzanie spiętrzonych kandydatów ICE
      await _processPendingIceCandidates();

      _logger.i('WebRTC Handshake complete!', module: 'WebRTC');
    } catch (e, st) {
      _logger.e(
        'Failed to handle answer',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _addIceCandidate(
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) async {
    if (_peerConnection == null) return;

    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);

    // Jeśli zestawienia opisu zdalnego jeszcze nie ukończono, buforujemy kandydata
    if (!_isRemoteDescriptionSet) {
      _logger.d(
        'Remote description not set yet. Queuing ICE candidate...',
        module: 'WebRTC',
      );
      _pendingIceCandidates.add(rtcCandidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(rtcCandidate);
    } catch (e, st) {
      _logger.e(
        'Failed to add ICE candidate',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _processPendingIceCandidates() async {
    if (_pendingIceCandidates.isEmpty || _peerConnection == null) return;

    _logger.d(
      'Processing ${_pendingIceCandidates.length} queued ICE candidates...',
      module: 'WebRTC',
    );
    for (final candidate in _pendingIceCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e, st) {
        _logger.e(
          'Failed to process queued ICE candidate',
          module: 'WebRTC',
          error: e,
          stackTrace: st,
        );
      }
    }
    _pendingIceCandidates.clear();
  }

  /// Sterowanie mikrofonem
  void setMicrophoneMuted(bool muted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
      _logger.i('Microphone muted status set to: $muted', module: 'WebRTC');
    }
  }

  /// Sprzątanie zasobów
  Future<void> closeConnection() async {
    _logger.i(
      'Closing WebRTC connection and clearing resources...',
      module: 'WebRTC',
    );
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    _pendingIceCandidates.clear();
    _isRemoteDescriptionSet = false;

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    _targetPeerId = null;
  }
}
