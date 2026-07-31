import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WindowsAudioRenderer extends StatelessWidget {
  final RTCVideoRenderer remoteRenderer;

  const WindowsAudioRenderer({super.key, required this.remoteRenderer});

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: true,
      child: SizedBox(width: 1, height: 1, child: RTCVideoView(remoteRenderer)),
    );
  }
}
