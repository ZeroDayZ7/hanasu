import 'dart:async';

import 'package:app/core/app/app_bootstrap.dart';
import 'package:app/core/app/app_lifecycle.dart';
import 'package:app/core/app/app_widget.dart';
import 'package:app/core/logger/app_provider_observer.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      final logger = await bootstrapApp(isProduction: kReleaseMode);

      final observer = AppLifecycleObserver(logger);
      WidgetsBinding.instance.addObserver(observer);

      runApp(
        ProviderScope(
          observers: [AppProviderObserver(logger)],
          overrides: [appLoggerProvider.overrideWithValue(logger)],
          child: const MainApp(),
        ),
      );
    },
    (error, stackTrace) {
      // Catch-all dla nieschwytanych błędów asynchronicznych
      debugPrint('Uncaught Zone Error: $error\n$stackTrace');
    },
  );
}
