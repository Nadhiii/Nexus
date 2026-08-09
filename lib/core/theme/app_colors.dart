import 'package:flutter/material.dart';

class AppColors {
  // --- Kuvera Light Palette Extensions ---
  static const Color kuveraBgLight = Color(0xFFF9FAFB);
  static const Color kuveraCardLight = Color(0xFFFFFFFF);
  static const Color kuveraBorderLight = Color(0xFFE5E7EB);
  static const Color kuveraTextPrimaryLight = Color(0xFF111827);
  static const Color kuveraTextSecondaryLight = Color(0xFF6B7280);
  
  // --- Kuvera Specific Accents ---
  static const Color kuveraGreen = Color(0xFF00A859);
  static const Color kuveraGreenBg = Color(0xFFE8F8F0);
  static const Color kuveraRed = Color(0xFFE53935);
  static const Color kuveraRedBg = Color(0xFFFFEBEE);
  static const Color kuveraArcBgLight = Color(0xFFF3F4F6);
  static const Color kuveraArcBgDark = Color(0xFF111827);

  // --- Brand Colors ---
  static const Color primaryBlue = Color(0xFF4B6BFB);
  static const Color primaryBlueDark = Color(0xFF324AB2);
  static const Color primaryBlueLight = Color(0xFF7B92FF);

  // --- Pastel Accents ---
  static const Color pastelTeal = Color(0xFF2DD4BF);
  static const Color pastelPurple = Color(0xFFA78BFA);
  static const Color pastelPink = Color(0xFFF472B6);
  static const Color pastelOrange = Color(0xFFFB923C);
  static const Color pastelGreen = Color(0xFF34D399);
  static const Color pastelYellow = Color(0xFFFACC15);
  static const Color pastelIndigo = Color(0xFF6366F1);

  // --- NBox Hero Accent ---
  static const Color nboxHeroStart = Color(0xFF6D28D9);
  static const Color nboxHeroEnd = Color(0xFF4C1D95);
  static const Color nboxAccent = Color(0xFFC084FC);

  // --- Premium/Special Colors ---
  static const Color premiumAmber = Color(0xFFD97706);
  static const Color investmentIndigo = Color(0xFF6366F1);
  static const Color profitEmerald = Color(0xFF065F46);
  static const Color profitEmeraldDark = Color(0xFF064E3B);
  static const Color lossRose = Color(0xFF9F1239);
  static const Color lossRoseDark = Color(0xFF881337);

  static const Color smsAccent = Color(0xFFF59E0B);
  static const Color emailAccent = Color(0xFF3B82F6);

  // --- Backgrounds (Dark Mode) ---
  static const Color backgroundBlack = Color.fromARGB(255, 19, 20, 39);
  static const Color cardSurface = Color(0xFF1E293B);
  static const Color cardElevated = Color(0xFF334155);

  // --- Semantic Colors ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // --- Text (Dark Mode) ---
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // --- Neutral Colors ---
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

  static const Color cardDark = cardSurface;
  static const Color cardDarkElevated = cardElevated;

  // Gradients
  static const List<Color> darkGradient = [backgroundBlack, cardSurface];
  static const List<Color> blueGradient = [primaryBlue, primaryBlueDark];
  static const List<Color> tealGradient = [pastelTeal, Color(0xFF14B8A6)];
  static const List<Color> purpleGradient = [pastelPurple, Color(0xFF8B5CF6)];
  static const List<Color> nboxHeroGradient = [nboxHeroStart, nboxHeroEnd];
  static const List<Color> indigoGradient = [pastelIndigo, Color(0xFF4F46E5)];
  static const List<Color> profitGradient = [profitEmerald, profitEmeraldDark];
  static const List<Color> lossGradient = [lossRose, lossRoseDark];
  static const List<Color> summaryCardGradient = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];

  static const List<Color> netWorthPositiveGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
  ];

  static const List<Color> netWorthNegativeGradient = [
    Color(0xFF450A0A),
    Color(0xFF7F1D1D),
  ];

  // Opacity variations
  static const Color whiteDim = Color(0x99FFFFFF);
  static const Color whiteLight = Color(0xB3FFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black12 = Color(0x1F000000);

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

  static const Map<String, Color> accountTypeColors = {
    'cash': pastelGreen,
    'bank': info,
    'credit': pastelPink,
    'investment': pastelPurple,
    'savings': pastelTeal,
  };
}