// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomList)
final roomListProvider = RoomListProvider._();

final class RoomListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatRoom>>,
          List<ChatRoom>,
          FutureOr<List<ChatRoom>>
        >
    with $FutureModifier<List<ChatRoom>>, $FutureProvider<List<ChatRoom>> {
  RoomListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomListHash();

  @$internal
  @override
  $FutureProviderElement<List<ChatRoom>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChatRoom>> create(Ref ref) {
    return roomList(ref);
  }
}

String _$roomListHash() => r'998fa43f806e89ceb808ef7e2972eaaa4abb7a2e';
