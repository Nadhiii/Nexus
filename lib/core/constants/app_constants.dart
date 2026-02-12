import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Nexus';
  static const String appTagline = 'Smart Finance Management';
  static const String version = '1.0.0';

  // Design Constants
  static const double borderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);

  // Colors (Material 3 compatible)
  static const Color primaryTeal = Color(0xFF2D5F5F);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Transaction Types
  static const String transactionTypeIncome = 'income';
  static const String transactionTypeExpense = 'expense';
  static const String transactionTypeTransfer = 'transfer';

  // Account Types
  static const String accountTypeAsset = 'asset';
  static const String accountTypeLiability = 'liability';

  // Account Sub-types
  static const String accountSubTypeBank = 'bank';
  static const String accountSubTypeCash = 'cash';
  static const String accountSubTypeInvestment = 'investment';
  static const String accountSubTypeCreditCard = 'credit_card';
  static const String accountSubTypeLoan = 'loan';

  // Subscription Frequencies
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyMonthly = 'monthly';
  static const String frequencyYearly = 'yearly';

  // Default Categories
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Food & Dining', 'icon': 'restaurant', 'color': 0xFFFF5722},
    {'name': 'Transportation', 'icon': 'directions_car', 'color': 0xFF9C27B0},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFE91E63},
    {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFF673AB7},
    {'name': 'Bills & Utilities', 'icon': 'receipt', 'color': 0xFF3F51B5},
    {'name': 'Healthcare', 'icon': 'local_hospital', 'color': 0xFF009688},
    {'name': 'Education', 'icon': 'school', 'color': 0xFF795548},
    {'name': 'Personal Care', 'icon': 'face', 'color': 0xFFFF9800},
    {'name': 'Travel', 'icon': 'flight', 'color': 0xFF4CAF50},
    {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF607D8B},
  ];

  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {'name': 'Salary', 'icon': 'work', 'color': 0xFF4CAF50},
    {'name': 'Business', 'icon': 'business', 'color': 0xFF2196F3},
    {'name': 'Investment Returns', 'icon': 'trending_up', 'color': 0xFF9C27B0},
    {'name': 'Freelance', 'icon': 'computer', 'color': 0xFFFF9800},
    {'name': 'Rental Income', 'icon': 'home', 'color': 0xFF795548},
    {
      'name': 'Other Income',
      'icon': 'account_balance_wallet',
      'color': 0xFF607D8B,
    },
  ];

  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // API & Storage
  static const int cacheExpiryDays = 7;
  static const int maxTransactionHistory = 1000;

  // Notifications
  static const int dailyReminderHour = 21; // 9 PM
  static const int weeklyReportDay = 7; // Sunday

  // Formatting
  static const String currencySymbol = '₹';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Goals
  static const List<String> goalColors = [
    '4CAF50', // Green
    '2196F3', // Blue
    'FF9800', // Orange
    '9C27B0', // Purple
    'F44336', // Red
    '00BCD4', // Cyan
    'FF5722', // Deep Orange
    '795548', // Brown
  ];

  // Smart Features
  static const double similarTransactionThreshold = 0.8; // 80% similarity
  static const int maxSimilarTransactions = 5;
  static const int billReminderDays = 3; // Remind 3 days before due

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorPermission =
      'Permission denied. Please check app permissions.';
  static const String errorInvalidInput =
      'Invalid input. Please check your data.';

  // Success Messages
  static const String successTransactionAdded =
      'Transaction added successfully!';
  static const String successAccountCreated = 'Account created successfully!';
  static const String successGoalCreated = 'Goal created successfully!';
  static const String successBackupCompleted = 'Backup completed successfully!';
}

// ==================== ENUMS ====================

/// Filter options for subscription dashboard
enum SubscriptionFilter { active, history }

// ==================== EXTENSIONS ====================

// Extension for easy color access
extension AppColorsExtension on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}
