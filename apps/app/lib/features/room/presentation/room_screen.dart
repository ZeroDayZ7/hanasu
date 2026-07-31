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
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  /// Sprawdza, czy w pamięci podręcznej urządzenie ma zapisaną aktywną sesję pokoju.
  Future<void> _checkActiveSession() async {
    final activeRoomId = await getActiveRoomId();
    if (!mounted) return;

    if (activeRoomId != null && activeRoomId.isNotEmpty) {
      _navigateToSession(activeRoomId);
    } else {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _generateAndFillCode() {
    FocusScope.of(context).unfocus();
    final newCode = generateRoomCode();
    _pinController.text = newCode;
    _copyToClipboard(newCode);
  }

  void _copyToClipboard(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.codeCopiedSnackBar(code))));
  }

  Future<void> _joinRoom() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    FocusScope.of(context).unfocus();

    await saveActiveRoomId(pin);

    if (!mounted) return;
    _navigateToSession(pin);
  }

  void _navigateToSession(String roomId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => SessionScreen(roomId: roomId),
          ),
        )
        .then((_) {
          // Po powrocie z ekranu sesji (np. kliknięcie w ikonę wyjścia / rozłączenie)
          // upewniamy się, że użytkownik pozostaje na widoku wpisywania kodu pokoju.
          if (mounted) {
            setState(() {
              _isCheckingSession = false;
              _pinController.clear();
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Ekran ładowania podczas weryfikacji aktywnej sesji
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: LanguageSelectorWidget(),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.graphic_eq,
                            size: 80,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            l10n.roomInputSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _pinController,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.roomInputHint,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.white70,
                                ),
                                tooltip: l10n.copyCodeTooltip,
                                onPressed: () => _copyToClipboard(
                                  _pinController.text.trim(),
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _joinRoom(),
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
