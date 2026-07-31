// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signaling_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signalingClient)
final signalingClientProvider = SignalingClientProvider._();

final class SignalingClientProvider
    extends
        $FunctionalProvider<SignalingClient, SignalingClient, SignalingClient>
    with $Provider<SignalingClient> {
  SignalingClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signalingClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signalingClientHash();

  @$internal
  @override
  $ProviderElement<SignalingClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignalingClient create(Ref ref) {
    return signalingClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignalingClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignalingClient>(value),
    );
  }
}

String _$signalingClientHash() => r'12a8f305545067e82ad4a9e116aaed317ff50117';
