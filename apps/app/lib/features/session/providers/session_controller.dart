import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:app/features/session/domain/chat_message.dart';
import 'package:app/features/session/domain/message_status.dart';
import 'package:app/features/session/domain/message_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

// --- 1. IZOLOWANY PROVIDER DLA CZATU I TŁUMACZEŃ ---

@riverpod
class SessionMessagesController extends _$SessionMessagesController {
  @override
  List<ChatMessage> build(String roomId) {
    return const [];
  }

  /// Dodawanie wiadomości systemowej (np. dołączenie/opuszczenie pokoju)
  void addSystemMessage(String text) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      text: text,
      type: MessageType.system,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      source: MessageSource.system,
    );
    state = [...state, msg];
  }

  /// Dodawanie własnej wysłanej wiadomości
  void addMyMessage(String text, {String? authorId, String? authorNick}) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      authorId: authorId ?? '',
      authorNick: authorNick ?? '',
      text: text,
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      source: MessageSource.me,
    );
    state = [...state, msg];
  }

  /// Dodawanie wiadomości odebranej od innego uczestnika
  void addPeerMessage(ChatMessage message) {
    state = [...state, message.copyWith(source: MessageSource.other)];
  }

  /// Aktualizacja stanu wiadomości (np. zmiana statusu na delivered / read lub dodanie translation)
  void updateMessage(ChatMessage updatedMessage) {
    state = [
      for (final msg in state)
        if (msg.id == updatedMessage.id) updatedMessage else msg,
    ];
  }
}

// --- 2. PROVIDER SYGNAŁOWY I ZARZĄDZANIA SESJĄ ---

class SessionState {
  final bool isMicEnabled;
  final SignalingState currentState;
  final String? peerId;

  const SessionState({
    this.isMicEnabled = true,
    this.currentState = SignalingState.disconnected,
    this.peerId,
  });

  SessionState copyWith({
    bool? isMicEnabled,
    SignalingState? currentState,
    String? peerId,
  }) {
    return SessionState(
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      currentState: currentState ?? this.currentState,
      peerId: peerId ?? this.peerId,
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
    
    // Upewniamy się, że serwis WebRTC został w pełni zainicjalizowany (wraz z AudioSession)
    await ref.read(webRtcServiceProvider.future);

    _stateSub = signaling.stateStream.listen((state) {
      _updateSignalingState(state);
    });

    _eventSub = signaling.eventStream.listen((event) {
      final messagesNotifier = ref.read(
        sessionMessagesControllerProvider(roomId).notifier,
      );

      if (event is PeerJoinedEvent) {
        state = state.copyWith(peerId: event.peerId);
        messagesNotifier.addSystemMessage('Peer joined: ${event.peerId}');
      } else if (event is PeerLeftEvent) {
        state = state.copyWith(peerId: null);
        messagesNotifier.addSystemMessage('Peer left the room');
      }
    });

    unawaited(signaling.connect(roomId));
  }

  void _updateSignalingState(SignalingState newState) {
    state = state.copyWith(currentState: newState);
  }

  Future<void> toggleMicrophone() async {
    final newMicState = !state.isMicEnabled;
    state = state.copyWith(isMicEnabled: newMicState);
    
    // Odbieramy instancję serwisu i mutujemy stan mikrofonu
    final rtcService = await ref.read(webRtcServiceProvider.future);
    rtcService.setMicrophoneMuted(!newMicState);
  }

  Future<void> leaveRoom() async {
    final storage = ref.read(secureStorageProvider);
    final signaling = ref.read(signalingClientProvider);

    await signaling.disconnect();
    
    // Zamiast ręcznego wywoływania closeConnection(), unieważniamy provider.
    // Riverpod automatycznie wywoła ref.onDispose() z audio_providers.dart, 
    // zamykając połączenie i czyszcząc sesję audio VoIP.
    ref.invalidate(webRtcServiceProvider);

    await clearActiveRoomId(storage);
  }
}
