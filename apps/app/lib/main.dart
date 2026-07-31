import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env_config.dart';
import 'config/env_dev.dart';
import 'config/env_prod.dart';
import 'core/locale/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/room/presentation/room_screen.dart';

void main() {
  mainDev();
}

void mainDev() {
  EnvConfig.current = DevConfig();
  _runApp();
}

void mainProd() {
  EnvConfig.current = ProdConfig();
  _runApp();
}

void _runApp() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: HanasuApp()));
}

class HanasuApp extends ConsumerWidget {
  const HanasuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(appLocaleProvider);

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
