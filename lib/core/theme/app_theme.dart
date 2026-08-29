import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_animations.dart';

class AppTheme {
  static final OutlineInputBorder _roundedInputBorder = OutlineInputBorder(
    borderRadius: AppSpacing.borderRadiusLg,
    borderSide: BorderSide.none,
  );

  // --- Light Theme (Kuvera Light) ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.kuveraBgLight,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.kuveraTextPrimaryLight,
        displayColor: AppColors.kuveraTextPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.kuveraCardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: const BorderSide(color: AppColors.kuveraBorderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.kuveraBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: const BorderSide(color: AppColors.kuveraBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white,
        modalBackgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      pageTransitionsTheme: AppAnimations.pageTransitionsTheme,
    );
  }

  // --- Dark Theme (Nexus Pitch Dark) ---
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.pastelPurple,
      onSecondary: AppColors.white,
      surface: AppColors.cardSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.cardElevated,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.white38,
      error: AppColors.error,
      onError: AppColors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundBlack,
      textTheme: AppTypography.textTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardElevated,
        border: _roundedInputBorder,
        enabledBorder: _roundedInputBorder,
        focusedBorder: _roundedInputBorder,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardElevated,
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.24),
        disabledColor: AppColors.cardElevated.withValues(alpha: 0.5),
        side: const BorderSide(color: AppColors.white12),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXs),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.white12, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryBlue : AppColors.cardElevated),
        trackOutlineColor: WidgetStateProperty.all(AppColors.white12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardElevated,
        modalBackgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      pageTransitionsTheme: AppAnimations.pageTransitionsTheme,
    );
  }

  static ThemeData get theme => darkTheme;
}
