import 'package:app/core/locale/locale_provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/clipboard_service_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeAsync = ref.watch(appLocaleProvider);
    final messengerKey = ref.watch(scaffoldMessengerKeyProvider);

    return localeAsync.when(
      data: (locale) => MaterialApp.router(
        title: 'VoIP Chat Engine',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: messengerKey,
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (err, st) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Critical App Load Error: $err')),
        ),
      ),
    );
  }
}
