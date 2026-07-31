import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

const _storage = FlutterSecureStorage();
const _localeKey = 'selected_locale';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Future<Locale> build() async {
    final savedLocale = await _storage.read(key: _localeKey);
    if (savedLocale != null) {
      return Locale(savedLocale);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale newLocale) async {
    state = AsyncData(newLocale);
    await _storage.write(key: _localeKey, value: newLocale.languageCode);
  }
}
