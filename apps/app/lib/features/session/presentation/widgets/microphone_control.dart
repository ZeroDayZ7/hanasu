import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MicrophoneControl extends StatelessWidget {
  final bool isMicEnabled;
  final VoidCallback onToggle;

  const MicrophoneControl({
    super.key,
    required this.isMicEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isMicEnabled
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: isMicEnabled ? 20 : 8,
                    spreadRadius: isMicEnabled ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                isMicEnabled ? Icons.mic : Icons.mic_off,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMicEnabled ? l10n.micEnabled : l10n.micMuted,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isMicEnabled
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
            ),
          ),
        ],
      ),
    );
  }
}
