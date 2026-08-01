import 'package:app/config/env_config.dart';
import 'package:app/config/env_dev.dart';
import 'package:app/config/env_prod.dart';
import 'package:app/core/locale/locale_provider.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/logger/app_provider_observer.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/clipboard_service_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  if (kReleaseMode) {
    mainProd();
  } else {
    mainDev();
  }
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

  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  logger.d('WidgetsFlutterBinding initialized', module: 'Bootstrap');

  try {
    EnvConfig.current = configBuilder();
    logger.i('Environment configured: $envName', module: 'Bootstrap');

    ErrorWidget.builder = (FlutterErrorDetails details) {
      logger.e(
        'UI Rendering error caught by ErrorWidget',
        module: 'ErrorWidget',
        error: details.exception,
        stackTrace: details.stack,
      );
      return FatalErrorScreen(error: details.exception);
    };

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

    logger.i('Application booted successfully', module: 'Bootstrap');
  } catch (e, st) {
    logger.e(
      'Fatal bootstrap failure',
      module: 'Bootstrap',
      error: e,
      stackTrace: st,
    );
    runApp(FatalErrorApp(error: e));
  } finally {
    binding.allowFirstFrame();
  }
}

class HanasuApp extends ConsumerWidget {
  const HanasuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(appLoggerProvider);
    final localeAsync = ref.watch(appLocaleProvider);
    final router = ref.watch(routerProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    logger.d(
      'Building HanasuApp widget (locale state: ${localeAsync.value?.languageCode ?? "loading..."})',
      module: 'HanasuApp',
    );

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
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
      routerConfig: router,
      builder: (context, child) {
        return AppErrorBoundary(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class AppErrorBoundary extends StatefulWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return FatalErrorScreen(
        error: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }
}

class FatalErrorApp extends StatelessWidget {
  final Object error;

  const FatalErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FatalErrorScreen(error: error),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const FatalErrorScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'SYSTEM ERROR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Wystąpił nieoczekiwany błąd aplikacji. Spróbuj uruchomić ponownie lub skontaktuj się z administratorem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'SPRÓBUJ PONOWNIE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
