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
      _logger.d(
        '[ice_candidates_handler.dart -> addCandidate -> 1.0 -> Remote description ready. Adding candidate directly to stream]',
        module: 'ICE',
      );
      _candidateController.add(candidate);
    } else {
      _logger.d(
        '[ice_candidates_handler.dart -> addCandidate -> 1.1 -> Remote description not set yet. Queuing ICE candidate | Current buffer size: ${_pendingBuffer.length + 1}]',
        module: 'ICE',
      );
      _pendingBuffer.add(candidate);
    }
  }

  /// Sygnalizuje, że SDP RemoteDescription został pomyślnie ustawiony.
  void markRemoteDescriptionReady(RTCPeerConnection peerConnection) {
    _logger.i(
      '[ice_candidates_handler.dart -> markRemoteDescriptionReady -> 1.0 -> Remote description marked ready]',
      module: 'ICE',
    );
    _isRemoteDescriptionSet = true;

    _subscription ??= _candidateController.stream.listen((candidate) async {
      await _addIceCandidateToPeer(peerConnection, candidate);
    });

    if (_pendingBuffer.isNotEmpty) {
      _logger.i(
        '[ice_candidates_handler.dart -> markRemoteDescriptionReady -> 1.1 -> Flushing ${_pendingBuffer.length} pending ICE candidates]',
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
      _logger.d(
        '[ice_candidates_handler.dart -> _addIceCandidateToPeer -> 1.0 -> Applying candidate to PeerConnection]',
        module: 'ICE',
      );
      await peerConnection.addCandidate(candidate);
      _logger.t(
        '[ice_candidates_handler.dart -> _addIceCandidateToPeer -> 1.1 -> Successfully applied ICE candidate]',
        module: 'ICE',
      );
    } catch (e, st) {
      _logger.e(
        '[ice_candidates_handler.dart -> _addIceCandidateToPeer -> ERR -> Failed to add ICE candidate]',
        module: 'ICE',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> dispose() async {
    _logger.d(
      '[ice_candidates_handler.dart -> dispose -> 1.0 -> Disposing IceCandidateQueue]',
      module: 'ICE',
    );
    await _subscription?.cancel();
    _subscription = null;
    _pendingBuffer.clear();
    _isRemoteDescriptionSet = false;
    await _candidateController.close();
  }
}
