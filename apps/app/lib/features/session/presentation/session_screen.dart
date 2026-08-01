import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/features/session/presentation/widgets/chat_message_list.dart';
import 'package:app/features/session/presentation/widgets/microphone_control.dart';
import 'package:app/features/session/presentation/widgets/session_status_bar.dart';
import 'package:app/features/session/presentation/widgets/windows_audio_renderer.dart';
import 'package:app/features/session/providers/session_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String roomId;

  const SessionScreen({super.key, required this.roomId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late final RTCVideoRenderer _remoteRenderer;
  bool _isRendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _remoteRenderer = RTCVideoRenderer();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
    if (!mounted) return;

    final webRtcService = ref.read(webRtcServiceProvider);
    setState(() {
      _remoteRenderer.srcObject = webRtcService.remoteStream;
      _isRendererInitialized = true;
    });
  }

  @override
  void dispose() {
    if (_isRendererInitialized) {
      _remoteRenderer.dispose().catchError((_) {});
    }
    super.dispose();
  }

  String _getStatusText(
    SignalingState state,
    String? peerId,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      SignalingState.disconnected => l10n.statusDisconnected,
      SignalingState.connecting => l10n.statusConnecting,
      SignalingState.connected =>
        peerId != null
            ? l10n.statusConnectedWithPeer(peerId)
            : l10n.statusWaitingForPeer,
      SignalingState.error => l10n.statusError,
    };
  }

  Color _getStatusColor(SignalingState state, String? peerId) {
    return switch (state) {
      SignalingState.disconnected => Colors.grey,
      SignalingState.connecting => Colors.orangeAccent,
      SignalingState.connected =>
        peerId != null ? Colors.greenAccent : Colors.lightBlueAccent,
      SignalingState.error => Colors.redAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionProvider = sessionControllerProvider(widget.roomId);

    // Automatyczne wyjście z ekranu w przypadku rozłączenia sesji przez serwer/peera
    ref.listen(sessionProvider, (previous, next) {
      if (next.currentState == SignalingState.disconnected &&
          previous?.currentState != SignalingState.disconnected) {
        if (context.mounted && context.canPop()) {
          context.pop();
        }
      }
    });

    final sessionState = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roomTitle(widget.roomId)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await controller.leaveRoom();
              if (context.mounted && context.canPop()) {
                context.pop();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isRendererInitialized)
            WindowsAudioRenderer(remoteRenderer: _remoteRenderer),
          Column(
            children: [
              SessionStatusBar(
                currentState: sessionState.currentState,
                peerId: sessionState.peerId,
                getStatusText: (state, peerId) =>
                    _getStatusText(state, peerId, l10n),
                getStatusColor: _getStatusColor,
              ),
              Expanded(child: ChatMessageList(messages: sessionState.messages)),
              MicrophoneControl(
                isMicEnabled: sessionState.isMicEnabled,
                onToggle: controller.toggleMicrophone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
