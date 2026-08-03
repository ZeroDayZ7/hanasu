import 'package:app/core/audio/webrtc_service.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_providers.g.dart';

// Ustawiamy keepAlive: true, ponieważ WebRtcService to singleton infrastrukturalny
@Riverpod(keepAlive: true)
Future<Raw<WebRtcService>> webRtcService(Ref ref) async {
  final logger = ref.watch(appLoggerProvider);
  final signalingClient = ref.watch(signalingClientProvider);

  final service = WebRtcService(logger, signalingClient);

  // Zwalnianie zasobów tylko przy wyłączeniu całej aplikacji / unieważnieniu jawne
  ref.onDispose(() {
    service.closeConnection();
  });

  await service.initialize();

  return service;
}
