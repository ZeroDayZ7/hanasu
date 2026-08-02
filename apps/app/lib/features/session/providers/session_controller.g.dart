// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SessionMessagesController)
final sessionMessagesControllerProvider = SessionMessagesControllerFamily._();

final class SessionMessagesControllerProvider
    extends $NotifierProvider<SessionMessagesController, List<ChatMessage>> {
  SessionMessagesControllerProvider._({
    required SessionMessagesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionMessagesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionMessagesControllerHash();

  @override
  String toString() {
    return r'sessionMessagesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionMessagesController create() => SessionMessagesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatMessage>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionMessagesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionMessagesControllerHash() =>
    r'c1dfec0344e2dd96ad94aa1746d30ed1727ca63d';

final class SessionMessagesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionMessagesController,
          List<ChatMessage>,
          List<ChatMessage>,
          List<ChatMessage>,
          String
        > {
  SessionMessagesControllerFamily._()
    : super(
        retry: null,
        name: r'sessionMessagesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionMessagesControllerProvider call(String roomId) =>
      SessionMessagesControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'sessionMessagesControllerProvider';
}

abstract class _$SessionMessagesController
    extends $Notifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  List<ChatMessage> build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ChatMessage>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ChatMessage>, List<ChatMessage>>,
              List<ChatMessage>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

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

String _$sessionControllerHash() => r'b18e3d90495d56b0d42cd7a50078955dbd61e34a';

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
