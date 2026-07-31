// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerFamily._();

final class SessionControllerProvider
    extends $NotifierProvider<SessionController, SessionState> {
  SessionControllerProvider._({
    required SessionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @override
  String toString() {
    return r'sessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionControllerHash() => r'ea0cfcb1c9722e56f041a14b5a7fe672b984353b';

final class SessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionController,
          SessionState,
          SessionState,
          SessionState,
          String
        > {
  SessionControllerFamily._()
    : super(
        retry: null,
        name: r'sessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionControllerProvider call(String roomId) =>
      SessionControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'sessionControllerProvider';
}

abstract class _$SessionController extends $Notifier<SessionState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  SessionState build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
