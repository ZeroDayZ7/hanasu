import 'package:flutter/material.dart';

class RoomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String tooltipText;
  final VoidCallback onCopy;
  final ValueChanged<String> onSubmitted;

  const RoomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.tooltipText,
    required this.onCopy,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 4,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.copy, color: Colors.white70),
          tooltip: tooltipText,
          onPressed: onCopy,
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
