import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

const _localeKey = 'selected_locale';

@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  @override
  Future<Locale> build() async {
    final storage = ref.watch(secureStorageProvider);
    final savedLocale = await storage.read(key: _localeKey);

    if (savedLocale != null) {
      return Locale(savedLocale);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale newLocale) async {
    final storage = ref.read(secureStorageProvider);

    state = AsyncData(newLocale);
    await storage.write(key: _localeKey, value: newLocale.languageCode);
  }
}
