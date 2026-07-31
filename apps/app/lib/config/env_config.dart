abstract class EnvConfig {
  String get apiBaseUrl;
  String get wsBaseUrl;
  bool get enableLogging;
  bool get useMockSignaling;

  static late EnvConfig current;
}