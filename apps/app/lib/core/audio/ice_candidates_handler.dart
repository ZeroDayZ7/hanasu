import 'dart:async';

import 'package:app/core/logger/app_logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Reaktywny zarządca buforowania i aplikowania kandydatów ICE.
final class IceCandidateQueue {
  final AppLogger _logger;

  final _candidateController = StreamController<RTCIceCandidate>.broadcast();
  StreamSubscription<RTCIceCandidate>? _subscription;

  final List<RTCIceCandidate> _pendingBuffer = [];
  bool _isRemoteDescriptionSet = false;

  IceCandidateQueue(this._logger);

  /// Rejestruje przychodzący kandydat ICE – buforuje go lub od razu przekazuje do strumienia.
  void addCandidate(RTCIceCandidate candidate) {
    if (_isRemoteDescriptionSet) {
      _candidateController.add(candidate);
    } else {
      _logger.d(
        'Remote description not set yet. Queuing ICE candidate.',
        module: 'ICE',
      );
      _pendingBuffer.add(candidate);
    }
  }

  /// Sygnalizuje, że SDP RemoteDescription został pomyślnie ustawiony.
  /// Subskrybuje do strumienia i natychmiastowo wypluwa zbuforowane kandydaty.
  void markRemoteDescriptionReady(RTCPeerConnection peerConnection) {
    _isRemoteDescriptionSet = true;

    // Nasłuchuj na przyszłe kandydaty ICE i aplikuj je od razu
    _subscription ??= _candidateController.stream.listen((candidate) async {
      await _addIceCandidateToPeer(peerConnection, candidate);
    });

    // Wypłucz dotychczas zbuforowane kandydaty z kolejki
    if (_pendingBuffer.isNotEmpty) {
      _logger.i(
        'Flushing ${_pendingBuffer.length} pending ICE candidates.',
        module: 'ICE',
      );
      final queued = List<RTCIceCandidate>.from(_pendingBuffer);
      _pendingBuffer.clear();

      for (final candidate in queued) {
        _candidateController.add(candidate);
      }
    }
  }

  Future<void> _addIceCandidateToPeer(
    RTCPeerConnection peerConnection,
    RTCIceCandidate candidate,
  ) async {
    try {
      await peerConnection.addCandidate(candidate);
      _logger.t('Successfully applied ICE candidate.', module: 'ICE');
    } catch (e, st) {
      _logger.e(
        'Failed to add ICE candidate',
        module: 'ICE',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Czyści stan kolejki i zamyka subskrypcję.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _pendingBuffer.clear();
    _isRemoteDescriptionSet = false;
    await _candidateController.close();
  }
}
