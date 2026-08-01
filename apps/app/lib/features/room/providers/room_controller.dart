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
class RoomState {
  final bool isLoading;
  final bool isCheckingSession;
  final String activeRoomId;
  final List<ChatRoom> rooms;
  final String? errorMessage;

  const RoomState({
    this.isLoading = true,
    this.isCheckingSession = false,
    this.activeRoomId = '',
    this.rooms = const [],
    this.errorMessage,
  });

  RoomState copyWith({
    bool? isLoading,
    bool? isCheckingSession,
    String? activeRoomId,
    List<ChatRoom>? rooms,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoomState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      rooms: rooms ?? this.rooms,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
class RoomController extends _$RoomController {
  @override
  RoomState build() {
    Future.microtask(() => _loadRooms());
    return const RoomState();
  }

  Future<void> _loadRooms() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final storage = ref.read(secureStorageProvider);

      final results = await Future.wait<dynamic>([
        room_repo.getRooms(storage),
        room_repo.fetchActiveRoomId(storage),
      ]);

      state = state.copyWith(
        isLoading: false,
        rooms: results[0] as List<ChatRoom>,
        activeRoomId: (results[1] as String?) ?? '',
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  String generateNewRoomName() => createDefaultRoomName();
  String generateNewCode() => generateNewRoomCode();

  Future<ChatRoom> createRoom(String name, {String? description}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final storage = ref.read(secureStorageProvider);
      final room = await room_repo.createRoom(
        storage,
        name,
        description: description,
      );

      state = state.copyWith(isLoading: false, rooms: [...state.rooms, room]);
      return room;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> saveRoom(String pin) async {
    state = state.copyWith(isCheckingSession: true, clearError: true);
    try {
      await saveActiveRoom(pin);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      state = state.copyWith(isCheckingSession: false);
    }
  }

  Future<void> saveActiveRoom(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    await room_repo.saveActiveRoom(storage, roomId);
    state = state.copyWith(activeRoomId: roomId);
  }

  Future<void> clearRoom() => clearActiveRoom();

  Future<void> clearActiveRoom() async {
    final storage = ref.read(secureStorageProvider);
    await room_repo.clearActiveRoom(storage);
    state = state.copyWith(activeRoomId: '');
  }

  Future<void> deleteRoom(String roomId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final storage = ref.read(secureStorageProvider);
      await room_repo.removeRoom(storage, roomId);

      state = state.copyWith(
        isLoading: false,
        rooms: state.rooms.where((room) => room.id != roomId).toList(),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
