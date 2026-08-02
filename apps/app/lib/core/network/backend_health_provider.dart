import 'package:app/core/network/http_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backend_health_provider.g.dart';

enum HealthStatus { checking, healthy, unreachable }

@Riverpod(keepAlive: true)
class BackendHealth extends _$BackendHealth {
  @override
  Future<HealthStatus> build() async {
    return await verifyHealth();
  }

  Future<HealthStatus> verifyHealth() async {
    state = const AsyncValue.data(HealthStatus.checking);
    final dio = ref.read(dioClientProvider);
    final isHealthy = await checkBackendHealth(dio);

    final status = isHealthy ? HealthStatus.healthy : HealthStatus.unreachable;
    state = AsyncValue.data(status);
    return status;
  }
}
