// apps/app/lib/features/session/presentation/session_screen.dart
import 'dart:async';

import 'package:app/core/audio/audio_providers.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/signaling_providers.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:app/features/session/domain/chat_message.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String roomId;

  const SessionScreen({super.key, required this.roomId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  bool _isTalking = false;
  SignalingState _currentState = SignalingState.disconnected;
  String? _peerId;

  final List<ChatMessage> _messages = [];
  StreamSubscription<SignalingState>? _stateSub;
  StreamSubscription<SignalingEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  void _initSession() {
    unawaited(saveActiveRoomId(widget.roomId));

    final signaling = ref.read(signalingClientProvider);
    ref.read(webRtcServiceProvider);

    _stateSub = signaling.stateStream.listen((state) {
      if (mounted) {
        setState(() => _currentState = state);
      }
    });

    _eventSub = signaling.eventStream.listen((event) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      if (event is PeerJoinedEvent) {
        setState(() {
          _peerId = event.peerId;
          _messages.add(
            ChatMessage(
              id: DateTime.now().toIso8601String(),
              text: l10n.peerJoined(event.peerId),
              source: MessageSource.system,
              timestamp: DateTime.now(),
            ),
          );
        });
      } else if (event is PeerLeftEvent) {
        setState(() {
          _peerId = null;
          _messages.add(
            ChatMessage(
              id: DateTime.now().toIso8601String(),
              text: l10n.peerLeft,
              source: MessageSource.system,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });

    unawaited(signaling.connect(widget.roomId));
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  void _onTalkStart() {
    setState(() => _isTalking = true);
    ref.read(webRtcServiceProvider).setMicrophoneMuted(false);
  }

  void _onTalkEnd() {
    setState(() => _isTalking = false);
    ref.read(webRtcServiceProvider).setMicrophoneMuted(true);
  }

  Future<void> _onLeave() async {
    final signaling = ref.read(signalingClientProvider);
    await signaling.disconnect();
    await ref.read(webRtcServiceProvider).closeConnection();
    await clearActiveRoomId();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _getStatusText(AppLocalizations l10n) {
    return switch (_currentState) {
      SignalingState.disconnected => l10n.statusDisconnected,
      SignalingState.connecting => l10n.statusConnecting,
      SignalingState.connected =>
        _peerId != null
            ? l10n.statusConnectedWithPeer(_peerId!)
            : l10n.statusWaitingForPeer,
      SignalingState.error => l10n.statusError,
    };
  }

  Color _getStatusColor() {
    return switch (_currentState) {
      SignalingState.disconnected => Colors.grey,
      SignalingState.connecting => Colors.orangeAccent,
      SignalingState.connected =>
        _peerId != null ? Colors.greenAccent : Colors.lightBlueAccent,
      SignalingState.error => Colors.redAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roomTitle(widget.roomId)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => unawaited(_onLeave()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _getStatusText(l10n),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.source == MessageSource.system) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final isMe = msg.source == MessageSource.me;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (msg.translatedText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              msg.translatedText!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 16),
            child: GestureDetector(
              onTapDown: (_) => _onTalkStart(),
              onTapUp: (_) => _onTalkEnd(),
              onTapCancel: () => _onTalkEnd(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTalking
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF6366F1),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isTalking
                                  ? Colors.redAccent
                                  : const Color(0xFF6366F1))
                              .withValues(alpha: 0.5),
                      blurRadius: _isTalking ? 30 : 10,
                      spreadRadius: _isTalking ? 10 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isTalking ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
