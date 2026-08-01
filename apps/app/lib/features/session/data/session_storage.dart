import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_storage.g.dart';

const _lastRoomKey = 'last_active_room_id';

@riverpod
Future<String?> lastActiveRoomId(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return getActiveRoomId(storage);
}

// Samodzielne funkcje operacyjne
Future<void> saveActiveRoomId(
  FlutterSecureStorage storage,
  String roomId,
) async {
  await storage.write(key: _lastRoomKey, value: roomId);
}

Future<String?> getActiveRoomId(FlutterSecureStorage storage) async {
  return await storage.read(key: _lastRoomKey);
}

Future<void> clearActiveRoomId(FlutterSecureStorage storage) async {
  await storage.delete(key: _lastRoomKey);
}
