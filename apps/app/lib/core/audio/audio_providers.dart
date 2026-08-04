import 'package:app/core/audio/webrtc_service.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_providers.g.dart';

@Riverpod(keepAlive: true)
Future<Raw<WebRtcService>> webRtcService(Ref ref) async {
  final logger = ref.watch(appLoggerProvider);
  final signalingClient = ref.watch(signalingClientProvider);

  final service = WebRtcService(logger, signalingClient);

  ref.onDispose(() {
    service.closeConnection();
  });

  await service.initialize();

  return service;
}
