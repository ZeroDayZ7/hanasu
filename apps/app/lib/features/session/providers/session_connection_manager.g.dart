// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_connection_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionConnectionManager)
final sessionConnectionManagerProvider = SessionConnectionManagerProvider._();

final class SessionConnectionManagerProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionConnectionManager>,
          SessionConnectionManager,
          FutureOr<SessionConnectionManager>
        >
    with
        $FutureModifier<SessionConnectionManager>,
        $FutureProvider<SessionConnectionManager> {
  SessionConnectionManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionConnectionManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionConnectionManagerHash();

  @$internal
  @override
  $FutureProviderElement<SessionConnectionManager> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionConnectionManager> create(Ref ref) {
    return sessionConnectionManager(ref);
  }
}

String _$sessionConnectionManagerHash() =>
    r'd210f589e2a8e283bc25576fb8c34ff8445dd9d1';
