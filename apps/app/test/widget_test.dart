import 'package:app/core/app/app_widget.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/core/logger/logger_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MainApp render smoke test', (WidgetTester tester) async {
    final mockLogger = AppLogger();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLoggerProvider.overrideWithValue(mockLogger)],
        child: const MainApp(),
      ),
    );

    // Renderowanie pierwszej klatki aplikacji
    await tester.pump();

    // Weryfikacja czy korzeń MaterialApp.router został zamontowany w drzewie
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
