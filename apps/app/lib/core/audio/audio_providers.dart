// lib/core/audio/audio_providers.dart
import 'package:app/core/audio/webrtc_service.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_providers.g.dart';

@Riverpod(keepAlive: true)
WebRtcService webRtcService(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  final signalingClient = ref.watch(signalingClientProvider);

  final service = WebRtcService(logger, signalingClient);
  service.initialize();

  ref.onDispose(() {
    service.closeConnection();
  });

  return service;
}
