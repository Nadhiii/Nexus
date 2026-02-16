import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // --- Font Families ---
  static const String bodyFont = 'Inter';
  static const String headerFont = 'RammettoOne'; // Bold, playful display font

  // --- Headlines (RammettoOne) ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 48,
    fontWeight: FontWeight.w400,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headerFont,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headerFont,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // --- Currency Styles (RammettoOne for numbers) ---
  static const TextStyle currencyLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.2,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // --- Body & Lists (Inter) ---
  // Inter Variable font handles all these weights (400, 600) perfectly
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // --- Titles (Inter) ---
  static const TextStyle titleLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // --- Labels (Inter) ---
  static const TextStyle labelLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // --- TextTheme Definitions ---
  static const TextTheme textTheme = TextTheme(
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
}
