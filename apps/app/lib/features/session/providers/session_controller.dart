import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:app/features/session/domain/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

class SessionState {
  final bool isMicEnabled;
  final SignalingState currentState;
  final String? peerId;
  final List<ChatMessage> messages;

  const SessionState({
    this.isMicEnabled = true,
    this.currentState = SignalingState.disconnected,
    this.peerId,
    this.messages = const [],
  });

  SessionState copyWith({
    bool? isMicEnabled,
    SignalingState? currentState,
    String? peerId,
    List<ChatMessage>? messages,
  }) {
    return SessionState(
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      currentState: currentState ?? this.currentState,
      peerId: peerId ?? this.peerId,
      messages: messages ?? this.messages,
    );
  }
}

@riverpod
class SessionController extends _$SessionController {
  StreamSubscription<SignalingState>? _stateSub;
  StreamSubscription<SignalingEvent>? _eventSub;

  @override
  SessionState build(String roomId) {
    _initSession(roomId);
    ref.onDispose(() {
      _stateSub?.cancel();
      _eventSub?.cancel();
    });
    return const SessionState();
  }

  Future<void> _initSession(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    await saveActiveRoomId(storage, roomId);

    final signaling = ref.read(signalingClientProvider);
    ref.read(webRtcServiceProvider);

    _stateSub = signaling.stateStream.listen((state) {
      stateChange(state);
    });

    _eventSub = signaling.eventStream.listen((event) {
      if (event is PeerJoinedEvent) {
        state = state.copyWith(peerId: event.peerId);
        addSystemMessage('Peer joined: ${event.peerId}');
      } else if (event is PeerLeftEvent) {
        state = state.copyWith(peerId: null);
        addSystemMessage('Peer left the room');
      }
    });

    unawaited(signaling.connect(roomId));
  }

  void stateChange(SignalingState newState) {
    state = state.copyWith(currentState: newState);
  }

  void addSystemMessage(String text) {
    final msg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      text: text,
      source: MessageSource.system,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void toggleMicrophone() {
    final newMicState = !state.isMicEnabled;
    state = state.copyWith(isMicEnabled: newMicState);
    ref.read(webRtcServiceProvider).setMicrophoneMuted(!newMicState);
  }

  Future<void> leaveRoom() async {
    final storage = ref.read(secureStorageProvider);
    final signaling = ref.read(signalingClientProvider);
    await signaling.disconnect();
    await ref.read(webRtcServiceProvider).closeConnection();
    await clearActiveRoomId(storage);
  }
}
