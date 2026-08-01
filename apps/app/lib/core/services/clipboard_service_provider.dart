import 'package:app/core/services/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Globalny klucz do komunikacji ze ScaffoldMessenger bez kontekstu
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});

/// Samodzielna funkcja eksportowana jako Provider (zgodnie ze standardem funkcyjnym)
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final key = ref.watch(scaffoldMessengerKeyProvider);
  return ClipboardService(scaffoldMessengerKey: key);
});