import 'dart:async';

import 'package:app/config/env_config.dart';
import 'package:app/config/env_dev.dart';
import 'package:app/config/env_prod.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Funkcja inicjalizująca natywne powiązania oraz konfigurację środowiska
Future<AppLogger> bootstrapApp({required bool isProduction}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja konfiguracji środowiskowej
  EnvConfig.current = isProduction ? ProdConfig() : DevConfig();

  // Inicjalizacja rejestratora zdarzeń
  final logger = AppLogger();
  logger.i(
    'Starting application in ${isProduction ? "PRODUCTION" : "DEVELOPMENT"} mode',
    module: 'Bootstrap',
  );

  // Globalna obsługa błędów Fluttera
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.e(
      'Flutter Framework Error',
      module: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Obsługa błędów asynchronicznych poza pętlą UI
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    logger.e(
      'Platform Unhandled Async Error',
      module: 'PlatformError',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  return logger;
}
