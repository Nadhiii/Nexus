import 'package:flutter/material.dart';

/// Nexus Design System - Color Palette
/// Inspired by modern fintech apps but adapted for personal finance management
class AppColors {
  // Brand Colors - Deep blue gradient like Revolut
  static const Color primaryBlue = Color(0xFF2952CC);
  static const Color primaryBlueDark = Color(0xFF1B3799);
  static const Color primaryBlueLight = Color(0xFF4A6FE0);
  
  // Accent Colors
  static const Color accentTeal = Color(0xFF00D4AA);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFFF9500);
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors - Dark Mode First
  static const Color neutral900 = Color(0xFF0A0A0A);
  static const Color neutral800 = Color(0xFF1A1A1A);
  static const Color neutral700 = Color(0xFF2A2A2A);
  static const Color neutral600 = Color(0xFF3A3A3A);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFFAFAFA);
  
  // Background Gradients
  static const List<Color> darkGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF0F0F23),
  ];
  
  static const List<Color> blueGradient = [
    Color(0xFF2952CC),
    Color(0xFF1B3799),
  ];
  
  static const List<Color> tealGradient = [
    Color(0xFF00D4AA),
    Color(0xFF00A896),
  ];
  
  static const List<Color> purpleGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
  ];
  
  // Card Colors
  static const Color cardDark = Color(0xFF1E1E2D);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDarkElevated = Color(0xFF252538);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  
  // Special Effects
  static const Color shimmerBase = Color(0xFF2A2A2A);
  static const Color shimmerHighlight = Color(0xFF3A3A3A);
  static const Color glassBackground = Color(0x33FFFFFF);
  static const Color glassBackgroundDark = Color(0x1AFFFFFF);
  
  // Category Colors (for financial categories)
  static const Map<String, Color> categoryColors = {
    'income': Color(0xFF10B981),
    'food': Color(0xFFFF6B6B),
    'transport': Color(0xFF4ECDC4),
    'shopping': Color(0xFFFFA502),
    'entertainment': Color(0xFFB53471),
    'bills': Color(0xFF5F27CD),
    'health': Color(0xFF00D2D3),
    'education': Color(0xFF1E90FF),
    'travel': Color(0xFFFF6348),
    'other': Color(0xFF95A5A6),
  };
  
  // Account Type Colors
  static const Map<String, Color> accountTypeColors = {
    'cash': Color(0xFF10B981),
    'bank': Color(0xFF3B82F6),
    'credit': Color(0xFFEC4899),
    'investment': Color(0xFF8B5CF6),
    'crypto': Color(0xFFFF9500),
    'savings': Color(0xFF00D4AA),
  };
}
