import 'package:app/core/audio/webrtc_service.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_providers.g.dart';

@riverpod
Future<Raw<WebRtcService>> webRtcService(Ref ref) async {
  final logger = ref.watch(appLoggerProvider);
  final signalingClient = ref.watch(signalingClientProvider);

  final service = WebRtcService(logger, signalingClient);

  // Awaitujemy pełną konfigurację sesji audio i subskrypcji WebRTC
  await service.initialize();

  // Zapewniamy wyczyszczenie zasobów przy opuszczeniu ekranu / unieważnieniu providera
  ref.onDispose(() {
    service.closeConnection();
  });

  return service;
}