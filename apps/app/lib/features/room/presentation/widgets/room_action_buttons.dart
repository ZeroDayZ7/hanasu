import 'package:flutter/material.dart';

class RoomActionButtons extends StatelessWidget {
  final String createButtonText;
  final String connectButtonText;
  final VoidCallback onCreate;
  final VoidCallback onConnect;

  const RoomActionButtons({
    super.key,
    required this.createButtonText,
    required this.connectButtonText,
    required this.onCreate,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCreate,
            child: Text(
              createButtonText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConnect,
            child: Text(
              connectButtonText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
