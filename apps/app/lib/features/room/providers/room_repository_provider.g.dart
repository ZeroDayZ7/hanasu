// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatRoomsNotifier)
final chatRoomsProvider = ChatRoomsNotifierProvider._();

final class ChatRoomsNotifierProvider
    extends $AsyncNotifierProvider<ChatRoomsNotifier, List<ChatRoom>> {
  ChatRoomsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRoomsNotifierHash();

  @$internal
  @override
  ChatRoomsNotifier create() => ChatRoomsNotifier();
}

String _$chatRoomsNotifierHash() => r'cded34a1dc62b99b77ff42137ba0dec67f91d6c2';

abstract class _$ChatRoomsNotifier extends $AsyncNotifier<List<ChatRoom>> {
  FutureOr<List<ChatRoom>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<ChatRoom>>, List<ChatRoom>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatRoom>>, List<ChatRoom>>,
              AsyncValue<List<ChatRoom>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
