import 'package:app/core/logger/logger_provider.dart';
import 'package:app/features/session/data/chat_websocket_client.dart';
import 'package:app/features/session/data/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatWebSocketClientProvider = Provider<ChatWebSocketClient>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ChatWebSocketClient(logger);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final client = ref.watch(chatWebSocketClientProvider);
  final logger = ref.watch(appLoggerProvider);
  return SessionRepository(client, logger);
});
