import 'package:app/core/logger/app_logger.dart';
import 'package:flutter/widgets.dart';

final class AppLifecycleObserver extends WidgetsBindingObserver {
  final AppLogger _logger;

  AppLifecycleObserver(this._logger);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('App lifecycle changed to: $state', module: 'Lifecycle');

    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
