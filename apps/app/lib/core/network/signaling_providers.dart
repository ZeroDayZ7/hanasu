import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/network/mock_signaling_client.dart';
import 'package:app/core/network/signaling_client.dart';
import 'package:app/core/network/ws_signaling_client.dart';

const bool useMockSignaling = true;

SignalingClient createSignalingClient() {
  if (useMockSignaling) {
    return MockSignalingClient();
  }
  return WsSignalingClient();
}

final signalingClientProvider = Provider<SignalingClient>((ref) {
  final client = createSignalingClient();
  ref.onDispose(() => client.disconnect());
  return client;
});
