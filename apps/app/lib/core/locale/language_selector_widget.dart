import 'package:app/core/locale/locale_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageOption {
  final Locale locale;
  final String label;

  const LanguageOption({required this.locale, required this.label});
}

const List<LanguageOption> appLanguages = [
  LanguageOption(locale: Locale('en'), label: 'English'),
  LanguageOption(locale: Locale('pl'), label: 'Polski'),
  LanguageOption(locale: Locale('ja'), label: '日本語'),
];

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(appLocaleProvider);

    return localeState.when(
      loading: () => const SizedBox(
        width: 120,
        height: 42,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => _buildDropdown(context, ref, appLanguages.first.locale),
      data: (currentLocale) {
        final activeOption = appLanguages.firstWhere(
          (opt) => opt.locale.languageCode == currentLocale.languageCode,
          orElse: () => appLanguages.first,
        );

        return _buildDropdown(context, ref, activeOption.locale);
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    WidgetRef ref,
    Locale activeLocale,
  ) {
    // Weryfikacja ze wspieranymi językami w systemie (bezpiecznik)
    final supportedCodes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();

    final availableOptions = appLanguages
        .where((opt) => supportedCodes.contains(opt.locale.languageCode))
        .toList();

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
          items: availableOptions.map((opt) {
            return DropdownMenuItem<Locale>(
              value: opt.locale,
              child: _LanguageItem(label: opt.label),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return availableOptions.map((opt) {
              return _LanguageSelected(label: opt.label);
            }).toList();
          },
          onChanged: (newLocale) {
            if (newLocale == null) return;
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
