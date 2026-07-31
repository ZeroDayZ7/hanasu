import 'package:app/config/env_config.dart';
import 'package:app/config/env_dev.dart';
import 'package:app/config/env_prod.dart';
import 'package:app/core/locale/locale_provider.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/logger/app_provider_observer.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/room/presentation/room_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  mainDev();
}

void mainDev() {
  _bootstrap(configBuilder: () => DevConfig(), envName: 'DEV');
}

void mainProd() {
  _bootstrap(configBuilder: () => ProdConfig(), envName: 'PROD');
}

void _bootstrap({
  required EnvConfig Function() configBuilder,
  required String envName,
}) {
  final logger = AppLogger();
  logger.i('Starting Hanasu application...', module: 'Bootstrap');

  try {
    WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
    binding.deferFirstFrame();
    logger.d('WidgetsFlutterBinding initialized', module: 'Bootstrap');

    EnvConfig.current = configBuilder();
    logger.i('Environment configured: $envName', module: 'Bootstrap');

    FlutterError.onError = (details) {
      logger.e(
        'Unhandled Flutter framework error',
        module: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logger.e(
        'Unhandled async error in root zone',
        module: 'PlatformDispatcher',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    logger.d('Global error handlers registered', module: 'Bootstrap');

    runApp(
      ProviderScope(
        observers: [AppProviderObserver(logger)],
        overrides: [appLoggerProvider.overrideWithValue(logger)],
        child: const HanasuApp(),
      ),
    );

    binding.allowFirstFrame();
    logger.i('Application booted successfully', module: 'Bootstrap');
  } catch (e, st) {
    logger.e(
      'Fatal bootstrap failure',
      module: 'Bootstrap',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
}

class HanasuApp extends ConsumerWidget {
  const HanasuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(appLoggerProvider);
    final localeAsync = ref.watch(appLocaleProvider);

    logger.d(
      'Building HanasuApp widget (locale state: ${localeAsync.value?.languageCode ?? "loading..."})',
      module: 'HanasuApp',
    );

    return MaterialApp(
      title: 'Hanasu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localeAsync.value ?? const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pl'), Locale('ja')],
      home: const RoomScreen(),
    );
  }
}
