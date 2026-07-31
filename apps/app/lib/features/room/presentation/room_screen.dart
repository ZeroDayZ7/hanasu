import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/env_config.dart';

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

  void _joinRoom() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Łączenie z pokojem $pin pod ${EnvConfig.current.wsBaseUrl}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HANASU :: P2P VOICE'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Wpisz kod pokoju, aby połączyć się z rozmówcą',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'np. xyz15',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('POŁĄCZ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
