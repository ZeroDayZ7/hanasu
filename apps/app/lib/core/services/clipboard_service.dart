import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'clipboard_service_provider.dart';

class ClipboardService {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  const ClipboardService({
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) : _scaffoldMessengerKey = scaffoldMessengerKey;

  Future<void> copyToClipboard(String text, {required String message}) async {
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));

    final messengerState = _scaffoldMessengerKey.currentState;
    if (messengerState != null) {
      messengerState.clearSnackBars();
      messengerState.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
