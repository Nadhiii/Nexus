import 'package:flutter/services.dart';

/// Service for handling Android Auto integration using Platform Channels
class AndroidAutoService {
  static const platform = MethodChannel('com.mahanadhi.nexus/android_auto');

  /// Initialize Android Auto service
  static Future<void> initializeAndroidAuto() async {
    try {
      await platform.invokeMethod('initializeAndroidAuto');
    } on PlatformException catch (e) {
      print('Failed to initialize Android Auto: ${e.message}');
      rethrow;
    }
  }

  /// Send current app state to Android Auto display
  static Future<void> sendAppState({
    required String title,
    required String content,
    required Map<String, dynamic> data,
  }) async {
    try {
      await platform.invokeMethod('updateAppState', {
        'title': title,
        'content': content,
        'data': data,
      });
    } on PlatformException catch (e) {
      print('Failed to send app state: ${e.message}');
      rethrow;
    }
  }

  /// Send current dashboard summary to Android Auto
  static Future<void> sendDashboardSummary({
    required String totalBalance,
    required String monthlyIncome,
    required String monthlyExpense,
    required String savingsRate,
  }) async {
    try {
      await platform.invokeMethod('updateDashboardSummary', {
        'totalBalance': totalBalance,
        'monthlyIncome': monthlyIncome,
        'monthlyExpense': monthlyExpense,
        'savingsRate': savingsRate,
      });
    } on PlatformException catch (e) {
      print('Failed to send dashboard summary: ${e.message}');
      rethrow;
    }
  }

  /// Send recent transactions to Android Auto
  static Future<void> sendRecentTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      await platform.invokeMethod('updateRecentTransactions', {
        'transactions': transactions,
      });
    } on PlatformException catch (e) {
      print('Failed to send transactions: ${e.message}');
      rethrow;
    }
  }

  /// Send alert/notification to Android Auto
  static Future<void> sendAlert({
    required String title,
    required String message,
    required String alertType,
  }) async {
    try {
      await platform.invokeMethod('sendAlert', {
        'title': title,
        'message': message,
        'alertType': alertType, // 'info', 'warning', 'error'
      });
    } on PlatformException catch (e) {
      print('Failed to send alert: ${e.message}');
      rethrow;
    }
  }

  /// Request action from Android Auto (e.g., user tapped a button)
  static Future<void> handleAndroidAutoAction(String actionId) async {
    try {
      await platform.invokeMethod('handleAction', {'actionId': actionId});
    } on PlatformException catch (e) {
      print('Failed to handle action: ${e.message}');
      rethrow;
    }
  }

  /// Check if Android Auto is connected/available
  static Future<bool> isAndroidAutoConnected() async {
    try {
      final result = await platform.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check Android Auto connection: ${e.message}');
      return false;
    }
  }
}
