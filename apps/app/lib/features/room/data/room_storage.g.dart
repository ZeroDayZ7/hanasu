// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedRooms)
final savedRoomsProvider = SavedRoomsProvider._();

final class SavedRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatRoom>>,
          List<ChatRoom>,
          FutureOr<List<ChatRoom>>
        >
    with $FutureModifier<List<ChatRoom>>, $FutureProvider<List<ChatRoom>> {
  SavedRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedRoomsHash();

  @$internal
  @override
  $FutureProviderElement<List<ChatRoom>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChatRoom>> create(Ref ref) {
    return savedRooms(ref);
  }
}

String _$savedRoomsHash() => r'66c8b6fec8692871541d971bf03b661278c5c09b';

@ProviderFor(activeRoomId)
final activeRoomIdProvider = ActiveRoomIdProvider._();

final class ActiveRoomIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  ActiveRoomIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRoomIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRoomIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return activeRoomId(ref);
  }
}

String _$activeRoomIdHash() => r'c4654b6dcbb26a69ad9022a5f8b7b18b50715746';
