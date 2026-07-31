import 'package:app/core/network/signaling_client.dart';
import 'package:flutter/material.dart';

class SessionStatusBar extends StatelessWidget {
  final SignalingState currentState;
  final String? peerId;
  final String Function(SignalingState state, String? peerId) getStatusText;
  final Color Function(SignalingState state, String? peerId) getStatusColor;

  const SessionStatusBar({
    super.key,
    required this.currentState,
    required this.peerId,
    required this.getStatusText,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(currentState, peerId);
    return Container(
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
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            getStatusText(currentState, peerId),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
