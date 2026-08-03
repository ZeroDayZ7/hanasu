import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/ws_signaling_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signaling_providers.g.dart';

@Riverpod(keepAlive: true)
SignalingClient signalingClient(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  final client = WsSignalingClient(logger);

  ref.onDispose(() {
    logger.d('Disposing SignalingClient instance', module: 'Signaling');
    client.disconnect();
  });

  return client;
}