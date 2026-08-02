import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MicrophoneControl extends StatelessWidget {
  final bool isMicEnabled;
  final bool isSpeakerphoneEnabled;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeakerphone;

  const MicrophoneControl({
    super.key,
    required this.isMicEnabled,
    required this.isSpeakerphoneEnabled,
    required this.onToggleMic,
    required this.onToggleSpeakerphone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final micColor = isMicEnabled
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    final speakerColor = isSpeakerphoneEnabled
        ? const Color(0xFF3B82F6)
        : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Przycisk Mikrofonu
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggleMic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: micColor,
                    boxShadow: [
                      BoxShadow(
                        color: micColor.withValues(alpha: 0.4),
                        blurRadius: isMicEnabled ? 16 : 8,
                        spreadRadius: isMicEnabled ? 3 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMicEnabled ? Icons.mic : Icons.mic_off,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMicEnabled ? l10n.micEnabled : l10n.micMuted,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMicEnabled
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
              ),
            ],
          ),

          // Przycisk Głośnika
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggleSpeakerphone,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: speakerColor,
                    boxShadow: [
                      BoxShadow(
                        color: speakerColor.withValues(alpha: 0.4),
                        blurRadius: isSpeakerphoneEnabled ? 16 : 8,
                        spreadRadius: isSpeakerphoneEnabled ? 3 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSpeakerphoneEnabled
                        ? Icons.volume_up
                        : Icons.phone_in_talk,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSpeakerphoneEnabled ? 'Głośnik' : 'Słuchawka',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSpeakerphoneEnabled
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
