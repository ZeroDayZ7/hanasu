// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BackendHealth)
final backendHealthProvider = BackendHealthProvider._();

final class BackendHealthProvider
    extends $AsyncNotifierProvider<BackendHealth, HealthStatus> {
  BackendHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendHealthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendHealthHash();

  @$internal
  @override
  BackendHealth create() => BackendHealth();
}

String _$backendHealthHash() => r'4c2e814e8a8deed12fc2cabf2e87f2574101643e';

abstract class _$BackendHealth extends $AsyncNotifier<HealthStatus> {
  FutureOr<HealthStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HealthStatus>, HealthStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HealthStatus>, HealthStatus>,
              AsyncValue<HealthStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
