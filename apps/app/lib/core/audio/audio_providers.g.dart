// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webRtcService)
final webRtcServiceProvider = WebRtcServiceProvider._();

final class WebRtcServiceProvider
    extends $FunctionalProvider<WebRtcService, WebRtcService, WebRtcService>
    with $Provider<WebRtcService> {
  WebRtcServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webRtcServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webRtcServiceHash();

  @$internal
  @override
  $ProviderElement<WebRtcService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebRtcService create(Ref ref) {
    return webRtcService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebRtcService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebRtcService>(value),
    );
  }
}

String _$webRtcServiceHash() => r'c83cb179387e2e68de15187ef0ee4ef71432ba95';
