import 'package:app/features/room/domain/room_code_generator.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_controller.g.dart';

class RoomState {
  final bool isCheckingSession;
  final String activeRoomId;

  const RoomState({this.isCheckingSession = true, this.activeRoomId = ''});

  RoomState copyWith({bool? isCheckingSession, String? activeRoomId}) {
    return RoomState(
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      activeRoomId: activeRoomId ?? this.activeRoomId,
    );
  }
}

@riverpod
class RoomController extends _$RoomController {
  @override
  RoomState build() {
    _checkActiveSession();
    return const RoomState();
  }

  Future<void> _checkActiveSession() async {
    final activeRoomId = await getActiveRoomId();
    if (activeRoomId != null && activeRoomId.isNotEmpty) {
      state = state.copyWith(
        isCheckingSession: false,
        activeRoomId: activeRoomId,
      );
    } else {
      state = state.copyWith(isCheckingSession: false);
    }
  }

  String generateNewCode() {
    return generateRoomCode();
  }

  Future<void> saveRoom(String pin) async {
    await saveActiveRoomId(pin);
    state = state.copyWith(activeRoomId: pin);
  }

  Future<void> clearRoom() async {
    await clearActiveRoomId();
    state = state.copyWith(activeRoomId: '');
  }
}
