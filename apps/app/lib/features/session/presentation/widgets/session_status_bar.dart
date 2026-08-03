import 'package:app/core/network/signaling_client.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SessionStatusBar extends StatelessWidget {
  final SignalingState currentState;
  final String? peerId;

  const SessionStatusBar({
    super.key,
    required this.currentState,
    this.peerId,
  });

  Color _getStatusColor() => switch (currentState) {
        SignalingState.disconnected => Colors.grey,
        SignalingState.connecting => Colors.orangeAccent,
        SignalingState.connected => Colors.greenAccent,
        SignalingState.error => Colors.redAccent,
      };

  String _getStatusText(AppLocalizations l10n) => switch (currentState) {
        SignalingState.disconnected => l10n.statusDisconnected,
        SignalingState.connecting => l10n.statusConnecting,
        SignalingState.connected => peerId != null
            ? l10n.statusConnectedWithPeer(peerId!)
            : l10n.statusWaitingForPeer,
        SignalingState.error => l10n.statusError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _getStatusColor().withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(l10n),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}