import 'package:app/config/env_config.dart';

class DevConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'http://192.168.42.76:8080';

  @override
  String get wsBaseUrl => 'ws://192.168.42.76:8080/ws';

  @override
  bool get enableLogging => true;

  @override
  bool get useMockSignaling => false;
}