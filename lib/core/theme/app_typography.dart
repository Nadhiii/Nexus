import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Fonts
  static const String bodyFont = 'Inter';
  static const String headerFont = 'RammettoOne'; // App signature maintained
  static const String serifHeaderFont = 'PlayfairDisplay';

  // Semantic Roles
  static const TextStyle hero = displayLarge;
  static const TextStyle screenTitle = headlineLarge;
  static const TextStyle sectionTitle = titleLarge;
  static const TextStyle body = bodyMedium;
  static const TextStyle caption = bodySmall;
  static const TextStyle controlLabel = labelLarge;

  // --- Signature Rammetto Currency (Characterful & Punchy) ---
  static const TextStyle currencyLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // --- Kuvera Hero Titles ---
  static const TextStyle kuveraSerifLarge = TextStyle(
    fontFamily: serifHeaderFont,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.kuveraTextPrimaryLight,
  );

  static const TextStyle kuveraSerifMedium = TextStyle(
    fontFamily: serifHeaderFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.kuveraTextPrimaryLight,
  );

  // --- Rammetto Headlines ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 38,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headerFont,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headerFont,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headerFont,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headerFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // --- UI Titles (Inter provides crisp readability for smaller section titles) ---
  static const TextStyle titleLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // --- Body Styles ---
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.1,
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
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // --- Labels ---
  static const TextStyle labelLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

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
