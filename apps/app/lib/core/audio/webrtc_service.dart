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
  Timer? _statsTimer;
  String? _targetPeerId;

  // Kolejka na kandydatów ICE przybyłych przed ustawieniem Remote Description
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _isRemoteDescriptionSet = false;

  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelay',
        'credential': 'openrelay',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelay',
        'credential': 'openrelay',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all',
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'mandatory': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
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
              '[Signaling] Peer joined ($peerId). Target peer set.',
              module: 'WebRTC',
            );
            _targetPeerId = peerId;

            // Inicjuj połączenie tylko jeśli nie jest już w trakcie tworzenia/utworzone
            if (_peerConnection == null) {
              _logger.i(
                '[Signaling] Initiating connection as Offerer...',
                module: 'WebRTC',
              );
              await _createPeerConnection();
              await _createAndSendOffer();
            }
            break;

          case PeerLeftEvent(:final peerId):
            _logger.w(
              '[Signaling] Peer left ($peerId). Closing WebRTC connection.',
              module: 'WebRTC',
            );
            await closeConnection();
            break;

          case OfferReceivedEvent(:final senderId, :final sdp):
            _logger.i(
              '[Signaling] Received offer from $senderId. Creating answer...',
              module: 'WebRTC',
            );
            _targetPeerId = senderId;

            // Tworzymy PeerConnection TYLKO jeśli jeszcze nie istnieje
            if (_peerConnection == null) {
              await _createPeerConnection();
            }

            await _handleOfferAndSendAnswer(sdp);
            break;

          case AnswerReceivedEvent(:final senderId, :final sdp):
            _logger.i(
              '[Signaling] Received answer from $senderId. Setting remote description...',
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
              '[Signaling] Received ICE candidate from $senderId',
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
    if (_peerConnection != null) {
      _logger.d(
        'RTCPeerConnection already exists. Skipping creation.',
        module: 'WebRTC',
      );
      return;
    }

    _logger.d('Creating RTCPeerConnection...', module: 'WebRTC');
    final pc = await createPeerConnection(_rtcConfiguration);
    _peerConnection = pc;
    _isRemoteDescriptionSet = false;
    _pendingIceCandidates.clear();

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      _logger.i(
        '[ICE State] ICE Connection State changed to: $state',
        module: 'WebRTC',
      );
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _startStatsMonitoring();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _stopStatsMonitoring();
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      _logger.i(
        '[Peer State] Connection State changed to: $state',
        module: 'WebRTC',
      );
    };

    _peerConnection!.onSignalingState = (RTCSignalingState state) {
      _logger.d('[Signaling State] State changed to: $state', module: 'WebRTC');
    };

    try {
      _logger.d(
        'Requesting local media stream (Microphone)...',
        module: 'WebRTC',
      );
      _localStream = await navigator.mediaDevices.getUserMedia(
        _mediaConstraints,
      );

      // ZABEZPIECZENIE: Jeśli w trakcie pobierania mikrofonu połączenie zostało zamknięte
      if (_peerConnection != pc || _peerConnection == null) {
        _logger.w(
          'PeerConnection was disposed while waiting for media. Aborting.',
          module: 'WebRTC',
        );
        return;
      }

      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
        _logger.i(
          '[Local Audio Track] ID: ${track.id}, Enabled: ${track.enabled}, Muted: ${track.muted}',
          module: 'WebRTC',
        );
      }

      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
      _logger.i(
        'Local audio track added to PeerConnection (Active by default)',
        module: 'WebRTC',
      );
    } catch (e, st) {
      _logger.e(
        'Failed to get user media (microphone access denied or unavailable)',
        module: 'WebRTC',
        error: e,
        stackTrace: st,
      );
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_targetPeerId != null &&
          candidate.candidate != null &&
          candidate.candidate!.isNotEmpty) {
        _logger.t(
          '[ICE Gathering] Local candidate generated -> ${candidate.candidate}',
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
      _logger.i(
        '[Track Event] Remote track received! Kind: ${event.track.kind}, ID: ${event.track.id}',
        module: 'WebRTC',
      );

      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _logger.i(
          '[Remote Stream] Stream ID: ${_remoteStream!.id}',
          module: 'WebRTC',
        );
      }

      if (event.track.kind == 'audio') {
        event.track.enabled = true;

        // Helper.setSpeakerphoneOn(true);

        _logger.i(
          '[Remote Audio Track] Configured. Enabled: ${event.track.enabled}, Muted: ${event.track.muted}',
          module: 'WebRTC',
        );

        event.track.onMute = () {
          _logger.w(
            '[Remote Audio Track] Audio stream WAS MUTED by remote side or network!',
            module: 'WebRTC',
          );
        };

        event.track.onUnMute = () {
          _logger.i(
            '[Remote Audio Track] Audio stream WAS UNMUTED - Audio flowing!',
            module: 'WebRTC',
          );
        };
      }
    };
  }

  /// Monitorowanie pakietów RTP w czasie rzeczywistym
  void _startStatsMonitoring() {
    _stopStatsMonitoring();
    _logger.i(
      'Starting periodic Audio RTP Stats monitoring (every 2s)...',
      module: 'WebRTC',
    );

    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_peerConnection == null) return;

      try {
        final stats = await _peerConnection!.getStats();
        for (final report in stats) {
          // Odbierany dźwięk
          if (report.type == 'inbound-rtp' &&
              report.values['kind'] == 'audio') {
            final bytesReceived = report.values['bytesReceived'];
            final packetsReceived = report.values['packetsReceived'];
            final packetsLost = report.values['packetsLost'];
            final jitter = report.values['jitter'];

            _logger.i(
              '[RTP INBOUND AUDIO] Bytes: $bytesReceived | Packets: $packetsReceived | Lost: $packetsLost | Jitter: $jitter',
              module: 'WebRTC',
            );
          }

          // Wysyłany dźwięk
          if (report.type == 'outbound-rtp' &&
              report.values['kind'] == 'audio') {
            final bytesSent = report.values['bytesSent'];
            final packetsSent = report.values['packetsSent'];

            _logger.i(
              '[RTP OUTBOUND AUDIO] Bytes: $bytesSent | Packets: $packetsSent',
              module: 'WebRTC',
            );
          }
        }
      } catch (e) {
        _logger.w('Failed to get RTC stats: $e', module: 'WebRTC');
      }
    });
  }

  void _stopStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _targetPeerId == null) return;

    final signalingState = await _peerConnection!.getSignalingState();

    // Tworzymy ofertę TYLKO wtedy, gdy jesteśmy w czystym stanie Stable
    if (signalingState != RTCSignalingState.RTCSignalingStateStable) {
      _logger.w(
        'Skipping offer creation. PeerConnection not in stable state ($signalingState)',
        module: 'WebRTC',
      );
      return;
    }

    try {
      final description = await _peerConnection!.createOffer();

      // Ponowne sprawdzenie stanu przed ustawieniem opisu
      if (await _peerConnection!.getSignalingState() !=
          RTCSignalingState.RTCSignalingStateStable) {
        _logger.w(
          'Signaling state changed while creating offer. Aborting offer.',
          module: 'WebRTC',
        );
        return;
      }

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

      _logger.d(
        'Remote Description (Offer) set successfully.',
        module: 'WebRTC',
      );
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

      _logger.d(
        'Remote Description (Answer) set successfully.',
        module: 'WebRTC',
      );
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
      _logger.t(
        'Successfully added ICE candidate to PeerConnection',
        module: 'WebRTC',
      );
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
    _stopStatsMonitoring();

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
