import 'env_config.dart';

class ProdConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'https://hanasu.tailnet-name.ts.net';

  @override
  String get wsBaseUrl => 'wss://hanasu.tailnet-name.ts.net/ws';

  @override
  bool get enableLogging => false;
}
