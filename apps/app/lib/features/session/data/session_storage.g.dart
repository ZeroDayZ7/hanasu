// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lastActiveRoomId)
final lastActiveRoomIdProvider = LastActiveRoomIdProvider._();

final class LastActiveRoomIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  LastActiveRoomIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastActiveRoomIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastActiveRoomIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return lastActiveRoomId(ref);
  }
}

String _$lastActiveRoomIdHash() => r'd16045ca39adcce7c31dc3f257cabbdc6eccf33b';
