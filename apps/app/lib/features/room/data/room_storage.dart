import 'dart:convert';

import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/room/domain/chat_room.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_storage.g.dart';

const _savedRoomsKey = 'saved_chat_rooms';
const _activeRoomIdKey = 'active_chat_room_id';

@riverpod
Future<List<ChatRoom>> savedRooms(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return loadRooms(storage);
}

@riverpod
Future<String?> activeRoomId(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return loadActiveRoomId(storage);
}

// Samodzielne funkcje operacyjne
Future<List<ChatRoom>> loadRooms(FlutterSecureStorage storage) async {
  final raw = await storage.read(key: _savedRoomsKey);
  if (raw == null || raw.isEmpty) {
    return const [];
  }

  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((item) => ChatRoom.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

Future<void> saveRooms(
  FlutterSecureStorage storage,
  List<ChatRoom> rooms,
) async {
  final raw = jsonEncode(rooms.map((room) => room.toJson()).toList());
  await storage.write(key: _savedRoomsKey, value: raw);
}

Future<ChatRoom> saveRoom(FlutterSecureStorage storage, ChatRoom room) async {
  final rooms = await loadRooms(storage);
  final index = rooms.indexWhere((item) => item.id == room.id);

  if (index >= 0) {
    rooms[index] = room;
  } else {
    rooms.add(room);
  }

  await saveRooms(storage, rooms);
  return room;
}

Future<void> deleteRoom(FlutterSecureStorage storage, String roomId) async {
  final rooms = await loadRooms(storage);
  final updated = rooms.where((room) => room.id != roomId).toList();
  await saveRooms(storage, updated);
}

Future<ChatRoom?> loadRoom(FlutterSecureStorage storage, String roomId) async {
  final rooms = await loadRooms(storage);
  for (final room in rooms) {
    if (room.id == roomId) {
      return room;
    }
  }
  return null;
}

Future<void> saveActiveRoomId(
  FlutterSecureStorage storage,
  String roomId,
) async {
  await storage.write(key: _activeRoomIdKey, value: roomId);
}

Future<String?> loadActiveRoomId(FlutterSecureStorage storage) async {
  return await storage.read(key: _activeRoomIdKey);
}

Future<void> clearActiveRoomId(FlutterSecureStorage storage) async {
  await storage.delete(key: _activeRoomIdKey);
}
