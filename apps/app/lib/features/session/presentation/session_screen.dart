import 'package:app/features/session/presentation/widgets/chat_message_list.dart';
import 'package:app/features/session/presentation/widgets/microphone_control.dart';
import 'package:app/features/session/presentation/widgets/session_status_bar.dart';
import 'package:app/features/session/presentation/widgets/windows_audio_renderer.dart';
import 'package:app/features/session/providers/session_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionScreen extends ConsumerWidget {
  final String roomId;

  const SessionScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionProvider = sessionControllerProvider(roomId);
    final sessionState = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roomTitle(roomId)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WindowsAudioRenderer(roomId: roomId),
          Column(
            children: [
              SessionStatusBar(
                currentState: sessionState.currentState,
                peerId: sessionState.peerId,
              ),
              Expanded(child: ChatMessageList(roomId: roomId)),
              MicrophoneControl(
                isMicEnabled: sessionState.isMicEnabled,
                isSpeakerphoneEnabled: sessionState.isSpeakerphoneEnabled,
                onToggleMic: controller.toggleMicrophone,
                onToggleSpeakerphone: controller.toggleSpeakerphone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
