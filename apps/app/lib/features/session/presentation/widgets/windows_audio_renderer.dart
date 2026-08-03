import 'package:app/features/session/providers/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WindowsAudioRenderer extends ConsumerStatefulWidget {
  final String roomId;

  const WindowsAudioRenderer({super.key, required this.roomId});

  @override
  ConsumerState<WindowsAudioRenderer> createState() =>
      _WindowsAudioRendererState();
}

class _WindowsAudioRendererState extends ConsumerState<WindowsAudioRenderer> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    try {
      await _renderer.initialize();
      if (!mounted) {
        // Jeśli widget został odmontowany w trakcie inicjalizacji natywnej,
        // zwalniamy renderer bezpiecznie po zakończeniu jego tworzenia.
        await _safeDisposeRenderer();
        return;
      }
      setState(() {
        _isInitialized = true;
      });

      // Ustawienie strumienia jeśli był już dostępny przed zakończeniem inicjalizacji
      final currentStream = ref.read(
        sessionControllerProvider(widget.roomId).select((s) => s.remoteStream),
      );
      if (currentStream != null) {
        _renderer.srcObject = currentStream;
      }
    } catch (_) {
      // Ignorujemy ew. błędy natywne przy przedwczesnym zniszczeniu
    }
  }

  Future<void> _safeDisposeRenderer() async {
    try {
      _renderer.srcObject = null;
      await _renderer.dispose();
    } catch (_) {
      // Przechwytujemy NullPointerException z natywnej wtyczki Androida
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _safeDisposeRenderer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reagujemy na zmianę strumienia w sposób reaktywny
    ref.listen(
      sessionControllerProvider(widget.roomId).select((s) => s.remoteStream),
      (previous, next) {
        if (_isInitialized && _renderer.srcObject != next) {
          _renderer.srcObject = next;
        }
      },
    );

    final remoteStream = ref.watch(
      sessionControllerProvider(widget.roomId).select((s) => s.remoteStream),
    );

    if (!_isInitialized || remoteStream == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(width: 1, height: 1, child: RTCVideoView(_renderer));
  }
}
