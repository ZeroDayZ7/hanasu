import 'env_config.dart';

class DevConfig implements EnvConfig {
  @override
  // Na Android Emulatorze: 10.0.2.2. Na Windows/Tailscale: Twój IP w Tailscale (np. 100.x.y.z)
  String get apiBaseUrl => 'http://10.0.2.2:8080';

  @override
  String get wsBaseUrl => 'ws://10.0.2.2:8080/ws';

  @override
  bool get enableLogging => true;
}
