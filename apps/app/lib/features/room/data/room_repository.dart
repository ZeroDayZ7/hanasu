import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/room/data/room_storage.dart';
import 'package:app/features/room/domain/chat_room.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_repository.g.dart';

@riverpod
Future<List<ChatRoom>> roomList(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await loadRooms(storage);
}

// Samodzielne funkcje operacyjne
Future<List<ChatRoom>> getRooms(FlutterSecureStorage storage) async {
  return await loadRooms(storage);
}

Future<ChatRoom> createRoom(
  FlutterSecureStorage storage,
  String name, {
  String? description,
}) async {
  final room = ChatRoom(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    description: description,
    createdAt: DateTime.now(),
  );
  return await saveRoom(storage, room);
}

Future<ChatRoom?> getRoomById(
  FlutterSecureStorage storage,
  String roomId,
) async {
  return await loadRoom(storage, roomId);
}

Future<void> removeRoom(FlutterSecureStorage storage, String roomId) async {
  await deleteRoom(storage, roomId);
}

Future<void> saveActiveRoom(FlutterSecureStorage storage, String roomId) async {
  await saveActiveRoomId(storage, roomId);
}

Future<String?> fetchActiveRoomId(FlutterSecureStorage storage) async {
  return await loadActiveRoomId(storage);
}

Future<void> clearActiveRoom(FlutterSecureStorage storage) async {
  await clearActiveRoomId(storage);
}
