import 'package:app/config/env_config.dart';

class ProdConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'http://100.88.179.37:8080';

  @override
  String get wsBaseUrl => 'ws://100.88.179.37:8080/ws';

  @override
  bool get enableLogging => false;

  @override
  bool get useMockSignaling => false;
}
