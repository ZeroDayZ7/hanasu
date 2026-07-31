import 'package:app/config/env_config.dart';

class DevConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'http://10.0.2.2:8080';

  @override
  String get wsBaseUrl => 'ws://10.0.2.2:8080/ws';

  @override
  bool get enableLogging => true;

  @override
  bool get useMockSignaling => true; // Lub false, w zależności od potrzeb deweloperskich
}