import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({super.key});

  static const List<Locale> _supportedLocales = [
    Locale('en'),
    Locale('pl'),
    Locale('ja'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(appLocaleProvider);

    return localeState.when(
      loading: () => const SizedBox(
        width: 120,
        height: 42,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => _buildDropdown(context, ref, const Locale('en')),
      data: (currentLocale) {
        final activeLocale = _supportedLocales.firstWhere(
          (locale) => locale.languageCode == currentLocale.languageCode,
          orElse: () => const Locale('en'),
        );

        return _buildDropdown(context, ref, activeLocale);
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    WidgetRef ref,
    Locale activeLocale,
  ) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: activeLocale,
          dropdownColor: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white54,
          ),
          items: const [
            DropdownMenuItem(
              value: Locale('en'),
              child: _LanguageItem(label: 'English'),
            ),
            DropdownMenuItem(
              value: Locale('pl'),
              child: _LanguageItem(label: 'Polski'),
            ),
            DropdownMenuItem(
              value: Locale('ja'),
              child: _LanguageItem(label: '日本語'),
            ),
          ],
          selectedItemBuilder: (context) {
            return const [
              _LanguageSelected(label: 'English'),
              _LanguageSelected(label: 'Polski'),
              _LanguageSelected(label: '日本語'),
            ];
          },
          onChanged: (newLocale) {
            if (newLocale == null) {
              return;
            }

            ref.read(appLocaleProvider.notifier).setLocale(newLocale);
          },
        ),
      ),
    );
  }
}

class _LanguageSelected extends StatelessWidget {
  final String label;

  const _LanguageSelected({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.language_rounded, size: 20, color: Colors.white70),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String label;

  const _LanguageItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.translate_rounded, size: 18, color: Colors.white70),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
