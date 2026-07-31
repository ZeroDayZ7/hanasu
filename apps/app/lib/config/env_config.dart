abstract class EnvConfig {
  String get apiBaseUrl;
  String get wsBaseUrl;
  bool get enableLogging;

  static late EnvConfig current;
}
