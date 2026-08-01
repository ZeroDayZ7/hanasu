import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color scaffoldBackground;
  final Color surfaceContainer;
  final Color inputBorder;
  final Color error;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.scaffoldBackground,
    required this.surfaceContainer,
    required this.inputBorder,
    required this.error,
  });

  /// Domyślny ciemny motyw (Dark Theme Tokens)
  static const dark = AppColors(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF10B981),
    scaffoldBackground: Color(0xFF0F172A),
    surfaceContainer: Color(0xFF1E293B),
    inputBorder: Color(0xFF334155),
    error: Color(0xFFEF4444),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? scaffoldBackground,
    Color? surfaceContainer,
    Color? inputBorder,
    Color? error,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      inputBorder: inputBorder ?? this.inputBorder,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Helper extension ułatwiający szybki dostęp do tokenów z BuildContext
extension AppColorsBuildContextX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
