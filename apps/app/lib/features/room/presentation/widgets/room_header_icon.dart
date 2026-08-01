import 'package:app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RoomHeaderIcon extends StatelessWidget {
  const RoomHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.graphic_eq, size: 80, color: context.colors.primary);
  }
}
