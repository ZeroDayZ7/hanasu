import 'package:app/core/logger/app_router_observer.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/features/room/presentation/room_screen.dart';
import 'package:app/features/session/presentation/session_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final logger = ref.watch(appLoggerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    observers: [AppRouterObserver(logger)],
    routes: [
      GoRoute(
        path: '/',
        name: 'rooms',
        builder: (context, state) => const RoomScreen(),
      ),
      GoRoute(
        path: '/session/:roomId',
        name: 'session',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return SessionScreen(roomId: roomId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('404 - Nie znaleziono strony: ${state.error}')),
    ),
  );
}
