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
    extends $NotifierProvider<RoomController, RoomState> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomState>(value),
    );
  }
}

String _$roomControllerHash() => r'5837c75eac501ff6c748185278ce2e1c0da849e1';

abstract class _$RoomController extends $Notifier<RoomState> {
  RoomState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RoomState, RoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RoomState, RoomState>,
              RoomState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
