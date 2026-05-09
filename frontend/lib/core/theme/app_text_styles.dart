import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Inter';

  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static TextTheme textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final secondary = scheme.brightness == Brightness.dark
        ? onSurface.withValues(alpha: 0.78)
        : onSurface.withValues(alpha: 0.74);
    final tertiary = scheme.brightness == Brightness.dark
        ? onSurface.withValues(alpha: 0.58)
        : onSurface.withValues(alpha: 0.56);

    return TextTheme(
      displaySmall: h1.copyWith(color: onSurface),
      headlineSmall: h2.copyWith(color: onSurface),
      titleLarge: h3.copyWith(color: onSurface),
      bodyLarge: body.copyWith(color: onSurface),
      bodyMedium: body.copyWith(color: secondary),
      bodySmall: bodySmall.copyWith(color: secondary),
      labelSmall: caption.copyWith(color: tertiary),
      labelMedium: caption.copyWith(color: secondary),
    );
  }
}

