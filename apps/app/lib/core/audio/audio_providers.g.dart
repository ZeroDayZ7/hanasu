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
    extends
        $FunctionalProvider<
          AsyncValue<Raw<WebRtcService>>,
          Raw<WebRtcService>,
          FutureOr<Raw<WebRtcService>>
        >
    with
        $FutureModifier<Raw<WebRtcService>>,
        $FutureProvider<Raw<WebRtcService>> {
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
  $FutureProviderElement<Raw<WebRtcService>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Raw<WebRtcService>> create(Ref ref) {
    return webRtcService(ref);
  }
}

String _$webRtcServiceHash() => r'c5470aea577b913cad9b2bfef8dc13e7212d6001';
