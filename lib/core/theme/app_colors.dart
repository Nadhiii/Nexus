import 'package:flutter/material.dart';

class AppColors {
  // --- Brand Colors (Softened for Pastel Theme) ---
  static const Color primaryBlue = Color(0xFF4B6BFB);
  static const Color primaryBlueDark = Color(0xFF324AB2);
  static const Color primaryBlueLight = Color(0xFF7B92FF);

  // --- Pastel Accents ---
  static const Color pastelTeal = Color(0xFF2DD4BF); // Soft Mint
  static const Color pastelPurple = Color(0xFFA78BFA); // Soft Lavender
  static const Color pastelPink = Color(0xFFF472B6); // Soft Rose
  static const Color pastelOrange = Color(0xFFFB923C); // Soft Apricot
  static const Color pastelGreen = Color(0xFF34D399); // Soft Emerald
  static const Color pastelYellow = Color(0xFFFACC15); // Soft Amber
  static const Color pastelIndigo = Color(0xFF6366F1); // Soft Indigo

  // --- Premium/Special Colors ---
  static const Color premiumAmber = Color(0xFFD97706); // Premium badge
  static const Color investmentIndigo = Color(0xFF6366F1); // Investment screens
  static const Color profitEmerald = Color(0xFF065F46); // Profit indicators
  static const Color profitEmeraldDark = Color(0xFF064E3B);
  static const Color lossRose = Color(0xFF9F1239); // Loss indicators
  static const Color lossRoseDark = Color(0xFF881337);

  // --- Backgrounds (Dark Grey/Blue) ---
  static const Color backgroundBlack = Color(0xFF0F172A); // Main Background
  static const Color cardSurface = Color(0xFF1E293B); // Card Background
  static const Color cardElevated = Color(
    0xFF334155,
  ); // Input fields / Highlights

  // --- Semantic Colors ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // --- Text (High Contrast for Safety) ---
  static const Color textPrimary = Color(0xFFF8FAFC); // White-ish
  static const Color textSecondary = Color(0xFF94A3B8); // Cool Grey
  static const Color textTertiary = Color(0xFF64748B); // Darker Grey

  // --- Neutral Colors (Kept for compatibility) ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // --- Backwards Compatibility Aliases ---
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

  // Card colors aliases
  static const Color cardDark = cardSurface;
  static const Color cardDarkElevated = cardElevated;

  // Gradients
  static const List<Color> darkGradient = [backgroundBlack, cardSurface];

  static const List<Color> blueGradient = [primaryBlue, primaryBlueDark];

  static const List<Color> tealGradient = [pastelTeal, Color(0xFF14B8A6)];

  static const List<Color> purpleGradient = [pastelPurple, Color(0xFF8B5CF6)];

  static const List<Color> indigoGradient = [pastelIndigo, Color(0xFF4F46E5)];

  static const List<Color> profitGradient = [profitEmerald, profitEmeraldDark];

  static const List<Color> lossGradient = [lossRose, lossRoseDark];

  static const List<Color> summaryCardGradient = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];

  // Net Worth Card Gradients
  static const List<Color> netWorthPositiveGradient = [
    Color(0xFF0F172A), // Dark slate
    Color(0xFF1E293B), // Slate
  ];

  static const List<Color> netWorthNegativeGradient = [
    Color(0xFF450A0A), // Dark red
    Color(0xFF7F1D1D), // Red
  ];

  // Opacity variations
  static const Color whiteDim = Color(0x99FFFFFF); // white 60%
  static const Color whiteLight = Color(0xB3FFFFFF); // white 70%
  static const Color white12 = Color(0x1FFFFFFF); // white 12%
  static const Color white38 = Color(0x61FFFFFF); // white 38%
  static const Color white54 = Color(0x8AFFFFFF); // white 54%
  static const Color white70 = Color(0xB3FFFFFF); // white 70%
  static const Color black12 = Color(0x1F000000); // black 12%

  // Neutral Colors (for compatibility)
  static const Color neutral900 = backgroundBlack;
  static const Color neutral800 = cardSurface;
  static const Color neutral700 = cardElevated;
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral400 = textSecondary;
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral50 = Color(0xFFF8FAFC);

  // --- Category Colors ---
  static const Map<String, Color> categoryColors = {
    'income': pastelGreen,
    'food': pastelPink,
    'transport': pastelOrange,
    'shopping': pastelPurple,
    'entertainment': pastelTeal,
    'bills': Color(0xFF818CF8),
    'health': Color(0xFF22D3EE),
    'education': primaryBlueLight,
    'travel': Color(0xFFF43F5E),
    'other': textSecondary,
  };

  // Account Type Colors
  static const Map<String, Color> accountTypeColors = {
    'cash': pastelGreen,
    'bank': info,
    'credit': pastelPink,
    'investment': pastelPurple,
    'savings': pastelTeal,
  };
}
