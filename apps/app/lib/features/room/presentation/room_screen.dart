import 'package:app/core/locale/language_selector_widget.dart';
import 'package:app/features/room/domain/room_code_generator.dart';
import 'package:app/features/session/data/session_storage.dart';
import 'package:app/features/session/presentation/session_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _generateAndFillCode() {
    final newCode = generateRoomCode();
    _pinController.text = newCode;
    _copyToClipboard(newCode);
  }

  void _copyToClipboard(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.codeCopiedSnackBar(code))));
  }

  Future<void> _joinRoom() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    await saveActiveRoomId(pin);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => SessionScreen(roomId: pin)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageSelectorWidget(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.graphic_eq, size: 80, color: Color(0xFF6366F1)),
            const SizedBox(height: 32),
            Text(
              l10n.roomInputSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: l10n.roomInputHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  tooltip: l10n.copyCodeTooltip,
                  onPressed: () => _copyToClipboard(_pinController.text.trim()),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _generateAndFillCode,
                    child: Text(
                      l10n.createRoomButton,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _joinRoom,
                    child: Text(
                      l10n.connectButton,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
