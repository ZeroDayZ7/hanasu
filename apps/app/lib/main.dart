import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/env_config.dart';
import 'config/env_dev.dart';
import 'config/env_prod.dart';
import 'core/theme/app_theme.dart';
import 'features/room/presentation/room_screen.dart';

void main() {
  mainDev();
}

void mainDev() {
  EnvConfig.current = DevConfig();
  _runHanasuApp();
}

void mainProd() {
  EnvConfig.current = ProdConfig();
  _runHanasuApp();
}

void _runHanasuApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: HanasuApp(),
    ),
  );
}

class HanasuApp extends StatelessWidget {
  const HanasuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanasu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RoomScreen(),
    );
  }
}
