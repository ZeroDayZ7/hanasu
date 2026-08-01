import 'package:app/core/locale/language_selector_widget.dart';
import 'package:app/features/room/presentation/widgets/room_action_buttons.dart';
import 'package:app/features/room/presentation/widgets/room_header_icon.dart';
import 'package:app/features/room/presentation/widgets/room_input_field.dart';
import 'package:app/features/room/providers/room_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    FocusScope.of(context).unfocus();
    final controller = ref.read(roomControllerProvider.notifier);
    final newCode = controller.generateNewCode();
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
    await ref.read(roomControllerProvider.notifier).saveRoom(pin);

    if (!mounted) return;
    _navigateToSession(pin);
  }

  void _navigateToSession(String roomId) {
    context.push('/session/$roomId').then((_) async {
      await ref.read(roomControllerProvider.notifier).clearRoom();
      if (mounted) {
        setState(() {
          _pinController.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomControllerProvider);

    return roomAsync.when(
      data: (roomData) => _buildScaffold(context, isCheckingSession: false),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isCheckingSession,
  }) {
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
                          const RoomHeaderIcon(),
                          const SizedBox(height: 32),
                          Text(
                            l10n.roomInputSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 24),
                          RoomInputField(
                            controller: _pinController,
                            hintText: l10n.roomInputHint,
                            tooltipText: l10n.copyCodeTooltip,
                            onCopy: () =>
                                _copyToClipboard(_pinController.text.trim()),
                            onSubmitted: (_) => _joinRoom(),
                          ),
                          const SizedBox(height: 24),
                          RoomActionButtons(
                            createButtonText: l10n.createRoomButton,
                            connectButtonText: l10n.connectButton,
                            onCreate: _generateAndFillCode,
                            onConnect: _joinRoom,
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
