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
      switch (event) {
        case PeerJoinedEvent(:final peerId):
          _logger.i(
            'Peer joined ($peerId). Initiating WebRTC offer...',
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
          _logger.t('Received ICE candidate from $senderId', module: 'WebRTC');
          await _addIceCandidate(candidate, sdpMid, sdpMLineIndex);
          break;

        default:
          break;
      }
    });
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    _logger.d('Creating RTCPeerConnection...', module: 'WebRTC');
    _peerConnection = await createPeerConnection(_rtcConfiguration);

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

    final description = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(description);

    _logger.d('Sending SDP Offer to -> $_targetPeerId', module: 'WebRTC');
    _signalingClient.sendOffer(_targetPeerId!, description.sdp!);
  }

  Future<void> _handleOfferAndSendAnswer(String sdp) async {
    if (_peerConnection == null || _targetPeerId == null) return;

    final remoteDesc = RTCSessionDescription(sdp, 'offer');
    await _peerConnection!.setRemoteDescription(remoteDesc);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _logger.d('Sending SDP Answer to -> $_targetPeerId', module: 'WebRTC');
    _signalingClient.sendAnswer(_targetPeerId!, answer.sdp!);
  }

  Future<void> _handleAnswer(String sdp) async {
    if (_peerConnection == null) return;

    final remoteDesc = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(remoteDesc);
    _logger.i('WebRTC Handshake complete!', module: 'WebRTC');
  }

  Future<void> _addIceCandidate(
    String candidate,
    String sdpMid,
    int sdpMLineIndex,
  ) async {
    if (_peerConnection == null) return;

    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    await _peerConnection!.addCandidate(rtcCandidate);
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

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    _targetPeerId = null;
  }
}
