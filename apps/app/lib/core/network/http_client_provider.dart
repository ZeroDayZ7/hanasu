import 'package:app/config/env_config.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_client_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final options = BaseOptions(
    baseUrl: EnvConfig.current.apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: const {'Content-Type': 'application/json'},
  );

  return Dio(options);
}

// Samodzielna funkcja realizująca bezpośredni sprawdzian endpointu /health
Future<bool> checkBackendHealth(Dio dio) async {
  try {
    final response = await dio.get('/health');
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
