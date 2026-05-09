import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4B44CC);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const backgroundLight = Color(0xFFF8F8FC);
  static const backgroundDark = Color(0xFF13131F);

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E2E);

  static const cardBorderLight = Color(0xFFE5E5F0);
  static const cardBorderDark = Color(0xFF2E2E45);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B6B80);
  static const textTertiary = Color(0xFF9999AA);

  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? primary : primary;
    final surface = isDark ? surfaceDark : surfaceLight;
    final onSurface = isDark ? Colors.white : textPrimary;

    return ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: primaryDark,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      outline: isDark ? cardBorderDark : cardBorderLight,
      surfaceContainerHighest: isDark ? const Color(0xFF25253A) : const Color(0xFFF1F1FA),
      shadow: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
      scrim: Colors.black.withValues(alpha: 0.4),
      inverseSurface: isDark ? surfaceLight : surfaceDark,
      onInverseSurface: isDark ? textPrimary : Colors.white,
      surfaceTint: primaryColor,
    );
  }
}
