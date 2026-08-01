import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/room/data/room_repository.dart' as room_repo;
import 'package:app/features/room/domain/chat_room.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_repository_provider.g.dart';

@riverpod
class ChatRoomsNotifier extends _$ChatRoomsNotifier {
  @override
  Future<List<ChatRoom>> build() async {
    final storage = ref.watch(secureStorageProvider);
    return await room_repo.getRooms(storage);
  }

  Future<void> addRoom(String name, {String? description}) async {
    final storage = ref.read(secureStorageProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await room_repo.createRoom(storage, name, description: description);
      return await room_repo.getRooms(storage);
    });
  }

  Future<void> delete(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await room_repo.removeRoom(storage, roomId);
      return await room_repo.getRooms(storage);
    });
  }
}
