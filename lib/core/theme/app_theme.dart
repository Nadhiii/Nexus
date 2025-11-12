import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'package:animations/animations.dart';

class AppTheme {
  // Spacing system
  static const double spacing4 = AppSpacing.xs;
  static const double spacing8 = AppSpacing.sm;
  static const double spacing12 = AppSpacing.md;
  static const double spacing16 = AppSpacing.lg;
  static const double spacing20 = AppSpacing.xl;
  static const double spacing24 = AppSpacing.xl2;
  static const double spacing32 = AppSpacing.xl4;

  // Border radius
  static const double radiusSmall = AppSpacing.radiusSm;
  static const double radiusMedium = AppSpacing.radiusMd;
  static const double radiusLarge = AppSpacing.radiusLg;
  static const double radiusXLarge = AppSpacing.radiusXl;

  static final ColorScheme _appLightColorScheme = const ColorScheme.light(
    primary: AppColors.primaryBlue,
    secondary: AppColors.accentTeal,
    tertiary: AppColors.accentPurple,
    surface: AppColors.cardLight,
    background: AppColors.neutral50,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryLight,
    onError: Colors.white,
    outline: AppColors.neutral200,
    primaryContainer: AppColors.primaryBlueLight,
    secondaryContainer: AppColors.accentTeal,
  );

  static final ColorScheme _appDarkColorScheme = const ColorScheme.dark(
    primary: AppColors.primaryBlue,
    secondary: AppColors.accentTeal,
    tertiary: AppColors.accentPurple,
    surface: AppColors.cardDark,
    background: AppColors.neutral900,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimary,
    onError: Colors.white,
    outline: AppColors.neutral700,
    primaryContainer: AppColors.primaryBlueDark,
    secondaryContainer: AppColors.accentTeal,
  );

  static TextTheme _getTextTheme(ColorScheme colorScheme, TextTheme baseTextTheme) {
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'RammettoOne'),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'RammettoOne'),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: 'RammettoOne'),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: 'RammettoOne'),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'RammettoOne'),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: 'RammettoOne'),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: 'Inter'),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: 'Inter'),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: 'Inter'),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: 'Inter'),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: 'Inter'),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: 'Inter'),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: 'Inter'),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: 'Inter'),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: 'Inter'),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static ThemeData _getThemeData(ColorScheme colorScheme, TextTheme baseTextTheme) {
    final textTheme = _getTextTheme(colorScheme, baseTextTheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing16,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing16,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing16,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: textTheme.bodyLarge,
        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: colorScheme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.headlineSmall,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.primary.withOpacity(0.1),
        labelStyle: textTheme.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  static ThemeData get lightTheme => _getThemeData(_appLightColorScheme, AppTypography.textThemeLight);
  static ThemeData get darkTheme => _getThemeData(_appDarkColorScheme, AppTypography.textThemeDark);

  static ThemeData getTheme(ColorScheme colorScheme) => colorScheme.brightness == Brightness.light ? lightTheme : darkTheme;
}
