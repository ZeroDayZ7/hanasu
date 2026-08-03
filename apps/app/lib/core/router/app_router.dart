import 'package:app/core/logger/app_router_observer.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/features/room/presentation/room_screen.dart';
import 'package:app/features/session/presentation/session_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@TypedGoRoute<RoomRoute>(
  path: '/',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SessionRoute>(path: 'session/:roomId'),
  ],
)
class RoomRoute extends GoRouteData with $RoomRoute {
  const RoomRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RoomScreen();
  }
}

class SessionRoute extends GoRouteData with $SessionRoute {
  const SessionRoute({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SessionScreen(roomId: roomId);
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final logger = ref.watch(appLoggerProvider);

  return GoRouter(
    initialLocation: const RoomRoute().location,
    debugLogDiagnostics: true,
    observers: [AppRouterObserver(logger)],
    routes: $appRoutes,
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('404 - Nie znaleziono strony: ${state.error}')),
    ),
  );
}
