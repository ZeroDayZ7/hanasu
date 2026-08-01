import 'package:app/core/logger/app_logger.dart';
import 'package:flutter/widgets.dart';

class AppRouterObserver extends NavigatorObserver {
  final AppLogger logger;

  AppRouterObserver(this.logger);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation(route, previousRoute, action: 'PUSH');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation(previousRoute, route, action: 'POP');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation(newRoute, oldRoute, action: 'REPLACE');
  }

  void _logNavigation(
    Route<dynamic>? currentRoute,
    Route<dynamic>? previousRoute, {
    required String action,
  }) {
    final currentPath =
        currentRoute?.settings.name ??
        currentRoute?.settings.arguments?.toString() ??
        'unknown';
    final previousPath = previousRoute?.settings.name ?? 'none';

    logger.d(
      '[$action] Current route: $currentPath (Previous: $previousPath)',
      module: 'Router',
    );
  }
}
