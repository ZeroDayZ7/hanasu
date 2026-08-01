// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomController)
final roomControllerProvider = RoomControllerProvider._();

final class RoomControllerProvider
    extends $AsyncNotifierProvider<RoomController, RoomData> {
  RoomControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomControllerHash();

  @$internal
  @override
  RoomController create() => RoomController();
}

String _$roomControllerHash() => r'40b59ca1387ebc036551ce4ba65d13c6ba3b8a91';

abstract class _$RoomController extends $AsyncNotifier<RoomData> {
  FutureOr<RoomData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RoomData>, RoomData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RoomData>, RoomData>,
              AsyncValue<RoomData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
