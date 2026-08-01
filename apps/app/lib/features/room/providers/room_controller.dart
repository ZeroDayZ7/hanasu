import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/room/data/room_repository.dart' as room_repo;
import 'package:app/features/room/domain/chat_room.dart';
import 'package:app/features/room/domain/room_code_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_controller.g.dart';

String generateNewRoomCode() => generateRoomCode();
String createDefaultRoomName() => 'Room-${generateRoomCode()}';

@immutable
class RoomData {
  final String activeRoomId;
  final List<ChatRoom> rooms;

  const RoomData({this.activeRoomId = '', this.rooms = const []});

  RoomData copyWith({String? activeRoomId, List<ChatRoom>? rooms}) {
    return RoomData(
      activeRoomId: activeRoomId ?? this.activeRoomId,
      rooms: rooms ?? this.rooms,
    );
  }
}

@riverpod
class RoomController extends _$RoomController {
  @override
  FutureOr<RoomData> build() async {
    final storage = ref.read(secureStorageProvider);

    final results = await Future.wait<dynamic>([
      room_repo.getRooms(storage),
      room_repo.fetchActiveRoomId(storage),
    ]);

    return RoomData(
      rooms: results[0] as List<ChatRoom>,
      activeRoomId: (results[1] as String?) ?? '',
    );
  }

  String generateNewRoomName() => createDefaultRoomName();
  String generateNewCode() => generateNewRoomCode();

  Future<ChatRoom> createRoom(String name, {String? description}) async {
    final storage = ref.read(secureStorageProvider);
    final room = await room_repo.createRoom(
      storage,
      name,
      description: description,
    );

    state = AsyncValue.data(
      state.requireValue.copyWith(rooms: [...state.requireValue.rooms, room]),
    );
    return room;
  }

  Future<void> saveRoom(String pin) async {
    await saveActiveRoom(pin);
  }

  Future<void> saveActiveRoom(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    await room_repo.saveActiveRoom(storage, roomId);
    state = AsyncValue.data(state.requireValue.copyWith(activeRoomId: roomId));
  }

  Future<void> clearRoom() => clearActiveRoom();

  Future<void> clearActiveRoom() async {
    final storage = ref.read(secureStorageProvider);
    await room_repo.clearActiveRoom(storage);
    state = AsyncValue.data(state.requireValue.copyWith(activeRoomId: ''));
  }

  Future<void> deleteRoom(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    await room_repo.removeRoom(storage, roomId);

    state = AsyncValue.data(
      state.requireValue.copyWith(
        rooms: state.requireValue.rooms
            .where((room) => room.id != roomId)
            .toList(),
      ),
    );
  }
}
