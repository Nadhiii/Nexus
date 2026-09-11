import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // TWILIGHT LUXURY PALETTE (Deep Navy / Obsidian Tints)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBg = Color(
    0xFF0C101A,
  ); // Midnight ink (rich, not dead black)
  static const Color darkSurface = Color(0xFF151B2B); // Deep navy surface
  static const Color darkSurfaceElevated = Color(
    0xFF1D263B,
  ); // Floating cards / dialogs
  static const Color darkSurfaceHighlight = Color(
    0xFF26324D,
  ); // Active chips / taps

  // Porcelain Light Mode
  static const Color lightBg = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEDF1F7);
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F2);

  // ═══════════════════════════════════════════════════════════════════════════
  // VIBRANT BRAND ACCENTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Ultra-Punchy Cobalt Blue (Electric and luminous against dark navy)
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryLight = Color(0xFF6E85F7);
  static const Color primaryDark = Color(0xFF2B44C9);
  static const Color primaryBlue = primary;
  static const Color primaryBlueDark = primaryDark;
  static const Color primaryBlueLight = primaryLight;

  // Rich Electric Violet (Signature accent)
  static const Color accentViolet = Color(0xFF7B2CBF);
  static const Color accentVioletLight = Color(0xFF9D4EDD);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTICS & STATUS (Crisp Neon Accents)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successBgDark = Color(0x1F10B981);
  static const Color successBgLight = Color(0xFFE6F9F0);

  static const Color error = Color(0xFFFF3366); // Vivid Coral Rose
  static const Color errorBgDark = Color(0x1FFF3366);
  static const Color errorBgLight = Color(0xFFFFEBEF);

  static const Color warning = Color(0xFFFFB703); // Solar Amber
  static const Color warningBgDark = Color(0x1FFFB703);
  static const Color warningBgLight = Color(0xFFFFF7E6);

  static const Color info = Color(0xFF00B4D8); // Cyan Blue

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY & GRAYS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color textPrimaryDark = Color(0xFFF9FAFD);
  static const Color textSecondaryDark = Color(0xFF9AA7C2);
  static const Color textMutedDark = Color(0xFF657494);

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS BORDERS (Subtle hairline edges)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color borderSubtleDark = Color(0x1FFFFFFF); // 12% Glass white
  static const Color borderMediumDark = Color(0x38FFFFFF); // 22% White
  static const Color borderSubtleLight = Color(0xFFE2E8F0);
  static const Color borderMediumLight = Color(0xFFCBD5E1);

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARDS COMPATIBILITY ALIASES
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color backgroundBlack = darkBg;
  static const Color cardSurface = darkSurface;
  static const Color cardElevated = darkSurfaceElevated;
  static const Color cardDark = cardSurface;
  static const Color cardDarkElevated = cardElevated;

  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textTertiary = textMutedDark;

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  static const Color whiteDim = Color(0x99FFFFFF);
  static const Color whiteLight = Color(0xB3FFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black12 = Color(0x1F000000);

  // Pastels
  static const Color pastelTeal = Color(0xFF06D6A0);
  static const Color pastelPurple = Color(0xFFB588F8);
  static const Color pastelPink = Color(0xFFFF66C4);
  static const Color pastelOrange = Color(0xFFFF8833);
  static const Color pastelGreen = Color(0xFF10B981);
  static const Color pastelYellow = Color(0xFFFFD166);
  static const Color pastelIndigo = Color(0xFF6366F1);

  static const Color green = pastelGreen;
  static const Color red = error;
  static const Color orange = pastelOrange;
  static const Color yellow = pastelYellow;
  static const Color indigo = pastelIndigo;
  static const Color accentTeal = pastelTeal;
  static const Color accentPurple = pastelPurple;
  static const Color accentPink = pastelPink;
  static const Color accentOrange = pastelOrange;
  static const Color accentIndigo = pastelIndigo;
  static const Color accentYellow = pastelYellow;

  // Semantic Design Tokens
  static const Color surfaceBackground = backgroundBlack;
  static const Color surfaceDefault = cardSurface;
  static const Color surfaceElevated = cardElevated;
  static const Color borderSubtle = borderSubtleDark;
  static const Color borderDefault = borderMediumDark;
  static const Color textOnPrimary = white;
  static const Color textOnSurface = textPrimary;
  static const Color actionPrimary = primary;
  static const Color actionPrimaryPressed = primaryDark;
  static const Color actionSecondary = cardElevated;
  static const Color actionDestructive = error;
  static const Color feedbackPositive = success;
  static const Color feedbackWarning = warning;
  static const Color feedbackNegative = error;
  static const Color feedbackInformative = info;

  // Kuvera Light
  static const Color kuveraBgLight = lightBg;
  static const Color kuveraCardLight = lightSurface;
  static const Color kuveraBorderLight = borderSubtleLight;
  static const Color kuveraTextPrimaryLight = textPrimaryLight;
  static const Color kuveraTextSecondaryLight = textSecondaryLight;
  static const Color kuveraGreen = Color(0xFF00A859);
  static const Color kuveraGreenBg = Color(0xFFE8F8F0);
  static const Color kuveraRed = Color(0xFFE53935);
  static const Color kuveraRedBg = Color(0xFFFFEBEE);
  static const Color kuveraArcBgLight = Color(0xFFF3F4F6);
  static const Color kuveraArcBgDark = Color(0xFF111827);

  // Accents
  static const Color nboxHeroStart = Color(0xFF7209B7);
  static const Color nboxHeroEnd = Color(0xFF3F37C9);
  static const Color nboxAccent = Color(0xFFB5179E);
  static const Color premiumAmber = Color(0xFFF59E0B);
  static const Color investmentIndigo = Color(0xFF4361EE);
  static const Color profitEmerald = Color(0xFF059669);
  static const Color profitEmeraldDark = Color(0xFF064E3B);
  static const Color lossRose = Color(0xFFE11D48);
  static const Color lossRoseDark = Color(0xFF881337);
  static const Color smsAccent = Color(0xFFF59E0B);
  static const Color emailAccent = Color(0xFF3B82F6);

  // Gradients
  static const List<Color> darkGradient = [darkBg, darkSurface];
  static const List<Color> blueGradient = [primary, primaryDark];
  static const List<Color> tealGradient = [pastelTeal, Color(0xFF059669)];
  static const List<Color> purpleGradient = [pastelPurple, accentViolet];
  static const List<Color> nboxHeroGradient = [nboxHeroStart, nboxHeroEnd];
  static const List<Color> indigoGradient = [primary, Color(0xFF3A0CA3)];
  static const List<Color> profitGradient = [profitEmerald, profitEmeraldDark];
  static const List<Color> lossGradient = [lossRose, lossRoseDark];
  static const List<Color> summaryCardGradient = [
    darkSurfaceElevated,
    darkSurface,
  ];
  static const List<Color> netWorthPositiveGradient = [
    Color(0xFF132034),
    darkSurface,
  ];
  static const List<Color> netWorthNegativeGradient = [
    Color(0xFF36121E),
    darkSurface,
  ];

  // Neutrals
  static const Color neutral900 = darkBg;
  static const Color neutral800 = darkSurface;
  static const Color neutral700 = darkSurfaceElevated;
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral400 = textSecondary;
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral50 = Color(0xFFF8FAFC);

  // Category Maps
  static const Map<String, Color> categoryColors = {
    'income': pastelGreen,
    'food': pastelPink,
    'transport': pastelOrange,
    'shopping': pastelPurple,
    'entertainment': pastelTeal,
    'bills': Color(0xFF818CF8),
    'health': Color(0xFF22D3EE),
    'education': primaryLight,
    'travel': Color(0xFFF43F5E),
    'other': textSecondary,
  };

  static const Map<String, Color> accountTypeColors = {
    'cash': pastelGreen,
    'bank': info,
    'credit': pastelPink,
    'investment': pastelPurple,
    'savings': pastelTeal,
  };
}
