import 'package:flutter/services.dart';
import 'dart:async';

/// Service to communicate with Android Home Screen Widgets.
/// Uses MethodChannel to send data from Flutter to native Android widgets.
class HomeScreenWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.mahanadhi.nexus/widget',
  );

  // ============== GARAGE WIDGET ==============

  /// Update the Garage widget with current vehicle data
  static Future<bool> updateGarageWidget({
    required String vehicleName,
    required double odometer,
    required double mileage,
    required String lastFuelDate,
    required double fuelPrice,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateGarageWidget', {
        'vehicleName': vehicleName,
        'odometer': odometer,
        'mileage': mileage,
        'lastFuelDate': lastFuelDate,
        'fuelPrice': fuelPrice,
      });
      return result == true;
    } catch (e) {
      print('Error updating garage widget: $e');
      return false;
    }
  }

  /// Request the user to pin the Garage widget to home screen
  static Future<bool> requestPinGarageWidget() async {
    try {
      final result = await _channel.invokeMethod('requestPinGarageWidget');
      return result == true;
    } catch (e) {
      print('Error pinning widget: $e');
      return false;
    }
  }

  /// Get the number of Garage widgets placed on home screens
  static Future<int> getGarageWidgetCount() async {
    try {
      final result = await _channel.invokeMethod('getGarageWidgetCount');
      return result as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ============== QUICK TRANSACTION WIDGET ==============

  /// Update the Quick Transaction widget with recent transactions
  static Future<bool> updateQuickTransactionWidget({
    required double todaySpent,
    required double weekSpent,
    required String lastTransaction,
    required double lastAmount,
    required String topCategory,
  }) async {
    try {
      final result = await _channel
          .invokeMethod('updateQuickTransactionWidget', {
            'todaySpent': todaySpent,
            'weekSpent': weekSpent,
            'lastTransaction': lastTransaction,
            'lastAmount': lastAmount,
            'topCategory': topCategory,
          });
      return result == true;
    } catch (e) {
      print('Error updating quick transaction widget: $e');
      return false;
    }
  }

  /// Request the user to pin the Quick Transaction widget to home screen
  static Future<bool> requestPinQuickTransactionWidget() async {
    try {
      final result = await _channel.invokeMethod(
        'requestPinQuickTransactionWidget',
      );
      return result == true;
    } catch (e) {
      print('Error pinning widget: $e');
      return false;
    }
  }

  // ============== BALANCE OVERVIEW WIDGET ==============

  /// Update the Balance Overview widget with financial summary
  static Future<bool> updateBalanceWidget({
    required double totalBalance,
    required double monthIncome,
    required double monthExpense,
    required double savingsRate,
    required int pendingBills,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateBalanceWidget', {
        'totalBalance': totalBalance,
        'monthIncome': monthIncome,
        'monthExpense': monthExpense,
        'savingsRate': savingsRate,
        'pendingBills': pendingBills,
      });
      return result == true;
    } catch (e) {
      print('Error updating balance widget: $e');
      return false;
    }
  }

  /// Request the user to pin the Balance widget to home screen
  static Future<bool> requestPinBalanceWidget() async {
    try {
      final result = await _channel.invokeMethod('requestPinBalanceWidget');
      return result == true;
    } catch (e) {
      print('Error pinning widget: $e');
      return false;
    }
  }

  // ============== COMMON ==============

  /// Check if widgets are supported on this device
  static Future<bool> areWidgetsSupported() async {
    try {
      final result = await _channel.invokeMethod('areWidgetsSupported');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Force refresh all widgets
  static Future<void> refreshAllWidgets() async {
    try {
      await _channel.invokeMethod('refreshAllWidgets');
    } catch (e) {
      print('Error refreshing widgets: $e');
    }
  }
}

/// Enum for different widget types
enum WidgetType { garage, quickTransaction, balance }

/// Widget update data model
class WidgetUpdateData {
  final WidgetType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WidgetUpdateData({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
