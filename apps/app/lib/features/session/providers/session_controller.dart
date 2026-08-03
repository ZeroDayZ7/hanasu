import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:app/features/session/domain/chat_message.dart';
import 'package:app/features/session/domain/message_status.dart';
import 'package:app/features/session/domain/message_type.dart';
import 'package:app/features/session/providers/session_connection_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

@riverpod
class SessionMessagesController extends _$SessionMessagesController {
  @override
  List<ChatMessage> build(String roomId) {
    return const [];
  }

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

  void addPeerMessage(ChatMessage message) {
    state = [...state, message.copyWith(source: MessageSource.other)];
  }

  void updateMessage(ChatMessage updatedMessage) {
    state = [
      for (final msg in state)
        if (msg.id == updatedMessage.id) updatedMessage else msg,
    ];
  }
}

class SessionState {
  final bool isMicEnabled;
  final bool isSpeakerphoneEnabled;
  final SignalingState currentState;
  final String? peerId;
  final MediaStream? remoteStream;

  const SessionState({
    this.isMicEnabled = true,
    this.isSpeakerphoneEnabled = false,
    this.currentState = SignalingState.disconnected,
    this.peerId,
    this.remoteStream,
  });

  SessionState copyWith({
    bool? isMicEnabled,
    bool? isSpeakerphoneEnabled,
    SignalingState? currentState,
    String? peerId,
    MediaStream? remoteStream,
  }) {
    return SessionState(
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isSpeakerphoneEnabled:
          isSpeakerphoneEnabled ?? this.isSpeakerphoneEnabled,
      currentState: currentState ?? this.currentState,
      peerId: peerId ?? this.peerId,
      remoteStream: remoteStream ?? this.remoteStream,
    );
  }
}

@riverpod
class SessionController extends _$SessionController {
  StreamSubscription<SignalingState>? _stateSub;
  StreamSubscription<SignalingEvent>? _eventSub;

  @override
  SessionState build(String roomId) {
    final storage = ref.read(secureStorageProvider);

    final connectionManagerFuture = ref.read(
      sessionConnectionManagerProvider.future,
    );

    ref.onDispose(() {
      _stateSub?.cancel();
      _eventSub?.cancel();
      unawaited(clearActiveRoomId(storage));

      connectionManagerFuture.then(
        (manager) => manager.disconnect(),
        onError: (_) {},
      );
    });

    _initSession(roomId);

    return const SessionState();
  }

  Future<void> _initSession(String roomId) async {
    final storage = ref.read(secureStorageProvider);
    await saveActiveRoomId(storage, roomId);

    if (!ref.mounted) return;

    final signaling = ref.read(signalingClientProvider);

    final connectionManager = await ref.read(
      sessionConnectionManagerProvider.future,
    );

    if (!ref.mounted) return;

    _stateSub?.cancel();
    _stateSub = signaling.stateStream.listen((newState) {
      if (!ref.mounted) return;
      state = state.copyWith(currentState: newState);
    });

    _eventSub?.cancel();
    _eventSub = signaling.eventStream.listen((event) {
      if (!ref.mounted) return;

      final messagesNotifier = ref.read(
        sessionMessagesControllerProvider(roomId).notifier,
      );

      if (event is PeerJoinedEvent) {
        state = state.copyWith(peerId: event.peerId);
        messagesNotifier.addSystemMessage('Peer joined: ${event.peerId}');
      } else if (event is PeerLeftEvent) {
        state = state.copyWith(peerId: null, remoteStream: null);
        messagesNotifier.addSystemMessage('Peer left the room');
      }
    });

    await connectionManager.connect(roomId);
  }

  Future<void> toggleMicrophone() async {
    final newMicState = !state.isMicEnabled;

    final rtcService = await ref.read(webRtcServiceProvider.future);
    if (!ref.mounted) return;

    state = state.copyWith(isMicEnabled: newMicState);
    rtcService.setMicrophoneMuted(!newMicState);
  }

  Future<void> toggleSpeakerphone() async {
    final newSpeakerState = !state.isSpeakerphoneEnabled;

    final rtcService = await ref.read(webRtcServiceProvider.future);
    if (!ref.mounted) return;

    state = state.copyWith(isSpeakerphoneEnabled: newSpeakerState);
    await rtcService.setSpeakerphoneOn(newSpeakerState);
  }
}
