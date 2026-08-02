import 'package:app/core/locale/language_selector_widget.dart';
import 'package:app/core/network/backend_health_provider.dart';
import 'package:app/core/services/clipboard_service_provider.dart';
import 'package:app/core/ui/show_error_snackbar.dart';
import 'package:app/features/room/presentation/widgets/default_room_card.dart';
import 'package:app/features/room/presentation/widgets/health_status_badge.dart';
import 'package:app/features/room/presentation/widgets/room_action_buttons.dart';
import 'package:app/features/room/presentation/widgets/room_header_icon.dart';
import 'package:app/features/room/presentation/widgets/room_input_field.dart';
import 'package:app/features/room/providers/room_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  static const String defaultRoomId = 'general';

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

    final l10n = AppLocalizations.of(context)!;
    final clipboardService = ref.read(clipboardServiceProvider);

    clipboardService.copyToClipboard(
      code,
      message: l10n.codeCopiedSnackBar(code),
    );
  }

  Future<void> _joinRoom([String? customRoomId]) async {
    final targetRoom = customRoomId ?? _pinController.text.trim();
    if (targetRoom.isEmpty) return;

    // Pobieramy instancje z BuildContext i zwijamy klawiaturę PRZED await
    final focusScope = FocusScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    focusScope.unfocus();

    // 1. Sprawdzanie dostępności backendu (Health Check)
    final healthNotifier = ref.read(backendHealthProvider.notifier);
    final status = await healthNotifier.verifyHealth();

    if (status != HealthStatus.healthy) {
      if (!mounted) return;
      showCustomErrorSnackBar(
        messenger: messenger,
        message: l10n.serverUnreachableError,
        actionLabel: l10n.retryAction,
        onRetry: () => _joinRoom(customRoomId),
      );
      return;
    }

    // 2. Nawiązanie połączenia z pokojem
    await ref.read(roomControllerProvider.notifier).saveRoom(targetRoom);

    if (!mounted) return;
    _navigateToSession(targetRoom);
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
      data: (_) => _buildScaffold(context),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
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

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: HealthStatusBadge(),
            ),
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
                          const SizedBox(height: 20),
                          DefaultRoomCard(
                            roomId: RoomScreen.defaultRoomId,
                            onJoin: () => _joinRoom(RoomScreen.defaultRoomId),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 24),
                          Text(
                            l10n.roomInputSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          RoomInputField(
                            controller: _pinController,
                            hintText: l10n.roomInputHint,
                            tooltipText: l10n.copyCodeTooltip,
                            onCopy: () =>
                                _copyToClipboard(_pinController.text.trim()),
                            onSubmitted: (_) => _joinRoom(),
                          ),
                          const SizedBox(height: 20),
                          RoomActionButtons(
                            createButtonText: l10n.createRoomButton,
                            connectButtonText: l10n.connectButton,
                            onCreate: _generateAndFillCode,
                            onConnect: () => _joinRoom(),
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
