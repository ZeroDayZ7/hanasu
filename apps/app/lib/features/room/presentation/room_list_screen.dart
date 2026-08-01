import 'package:app/core/locale/language_selector_widget.dart';
import 'package:app/features/room/domain/chat_room.dart';
import 'package:app/features/room/providers/room_controller.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _roomNameController.text.trim();
    if (name.isEmpty) return;

    FocusScope.of(context).unfocus();
    final controller = ref.read(roomControllerProvider.notifier);
    final room = await controller.createRoom(name);
    _roomNameController.clear();

    if (!mounted) return;
    context.push('/session/${room.id}');
  }

  Widget _buildRoomTile(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(room.name),
        subtitle: Text(room.description ?? 'ID: ${room.id}'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.push('/session/${room.id}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roomState = ref.watch(roomControllerProvider);

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _roomNameController,
                decoration: InputDecoration(
                  labelText: l10n.createRoomLabel,
                  hintText: l10n.createRoomHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _createRoom,
                    tooltip: l10n.createRoomButton,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (roomState.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (roomState.errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      roomState.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              else if (roomState.rooms.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.noRoomsMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: roomState.rooms.length,
                    itemBuilder: (context, index) {
                      final room = roomState.rooms[index];
                      return _buildRoomTile(room);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
