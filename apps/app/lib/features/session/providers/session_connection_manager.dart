import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/audio/webrtc_service.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_connection_manager.g.dart';

@Riverpod(keepAlive: true)
Future<SessionConnectionManager> sessionConnectionManager(Ref ref) async {
  final signaling = ref.watch(signalingClientProvider);

  // 1. Definiujemy manager przed await i od razu podpinamy cleanup
  late final SessionConnectionManager manager;

  ref.onDispose(() {
    unawaited(manager.dispose());
  });

  // 2. Oczekujemy na gotowość asynchronicznego providera WebRTC
  final rtcService = await ref.watch(webRtcServiceProvider.future);

  manager = SessionConnectionManager(
    signalingClient: signaling,
    rtcService: rtcService,
  );

  return manager;
}

class SessionConnectionManager {
  final SignalingClient _signalingClient;
  final WebRtcService _rtcService;

  Completer<void>? _operationLock;
  bool _isDisposed = false;

  SessionConnectionManager({
    required SignalingClient signalingClient,
    required WebRtcService rtcService,
  }) : _signalingClient = signalingClient,
       _rtcService = rtcService;

  Future<void> connect(String roomId) async {
    if (_isDisposed) return;

    while (_operationLock != null) {
      await _operationLock!.future;
    }

    _operationLock = Completer<void>();

    try {
      await _rtcService.initialize();
      await _signalingClient.connect(roomId);
    } finally {
      _operationLock?.complete();
      _operationLock = null;
    }
  }

  Future<void> disconnect() async {
    while (_operationLock != null) {
      await _operationLock!.future;
    }

    _operationLock = Completer<void>();

    try {
      await _signalingClient.disconnect();
      await _rtcService.closeConnection();
    } finally {
      _operationLock?.complete();
      _operationLock = null;
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await disconnect();
  }
}
