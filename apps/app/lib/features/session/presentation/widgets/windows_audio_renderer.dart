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
    await _renderer.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remoteStream = ref.watch(
      sessionControllerProvider(widget.roomId).select((s) => s.remoteStream),
    );

    if (_isInitialized && _renderer.srcObject != remoteStream) {
      _renderer.srcObject = remoteStream;
    }

    if (!_isInitialized || remoteStream == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(width: 1, height: 1, child: RTCVideoView(_renderer));
  }
}
