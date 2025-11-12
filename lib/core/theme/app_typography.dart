import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Inter';
  static const String headlineFontFamily = 'RammettoOne';

  // Base TextStyles
  static const TextStyle displayLarge = TextStyle(fontFamily: headlineFontFamily, fontSize: 56, fontWeight: FontWeight.w400, height: 1.1, letterSpacing: -0.5);
  static const TextStyle displayMedium = TextStyle(fontFamily: headlineFontFamily, fontSize: 44, fontWeight: FontWeight.w400, height: 1.15, letterSpacing: -0.3);
  static const TextStyle displaySmall = TextStyle(fontFamily: headlineFontFamily, fontSize: 36, fontWeight: FontWeight.w400, height: 1.2, letterSpacing: -0.2);

  static const TextStyle headlineLarge = TextStyle(fontFamily: headlineFontFamily, fontSize: 32, fontWeight: FontWeight.w400, height: 1.25);
  static const TextStyle headlineMedium = TextStyle(fontFamily: headlineFontFamily, fontSize: 28, fontWeight: FontWeight.w400, height: 1.3);
  static const TextStyle headlineSmall = TextStyle(fontFamily: headlineFontFamily, fontSize: 24, fontWeight: FontWeight.w400, height: 1.3);

  static const TextStyle titleLarge = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0);
  static const TextStyle titleMedium = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.1);
  static const TextStyle titleSmall = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.1);

  static const TextStyle bodyLarge = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.15);
  static const TextStyle bodyMedium = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.25);
  static const TextStyle bodySmall = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0.4);

  static const TextStyle labelLarge = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.5);
  static const TextStyle labelMedium = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.5);
  static const TextStyle labelSmall = TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.5);

  // CORRECTED: Restored the currency styles that were mistakenly deleted.
  static const TextStyle currencyLarge = TextStyle(fontFamily: fontFamily, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1,);
  static const TextStyle currencyMedium = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5,);
  static const TextStyle currencySmall = TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.3,);

  // TextTheme definitions needed by AppTheme
  static const TextTheme textThemeLight = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  static final TextTheme textThemeDark = textThemeLight.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );
}
