import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _lastRoomKey = 'last_active_room_id';

Future<void> saveActiveRoomId(String roomId) async {
  await _storage.write(key: _lastRoomKey, value: roomId);
}

Future<String?> getActiveRoomId() async {
  return await _storage.read(key: _lastRoomKey);
}

Future<void> clearActiveRoomId() async {
  await _storage.delete(key: _lastRoomKey);
}
