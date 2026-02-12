import 'package:flutter/services.dart';
import 'dart:async';

/// Service to communicate with Android Auto.
/// Uses MethodChannel to send Garage and Dashboard data to the car display.
class AndroidAutoService {
  static const MethodChannel _channel = MethodChannel(
    'com.mahanadhi.nexus/android_auto',
  );

  static bool _isInitialized = false;

  /// Initialize Android Auto connection
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initializeAndroidAuto');
      _isInitialized = result == true;
      return _isInitialized;
    } catch (e) {
      print('Error initializing Android Auto: $e');
      return false;
    }
  }

  /// Check if Android Auto is connected
  static Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod('isConnected');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Update Garage data on Android Auto display
  static Future<bool> updateGarageData({
    required String vehicleName,
    required double odometer,
    required double mileage,
    required double lastFuelPrice,
    required String lastFuelDate,
    int nextServiceKm = 0,
    bool serviceDueSoon = false,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateGarageData', {
        'vehicleName': vehicleName,
        'odometer': odometer,
        'mileage': mileage,
        'lastFuelPrice': lastFuelPrice,
        'lastFuelDate': lastFuelDate,
        'nextServiceKm': nextServiceKm,
        'serviceDueSoon': serviceDueSoon,
      });
      return result == true;
    } catch (e) {
      print('Error updating Android Auto garage: $e');
      return false;
    }
  }

  /// Update Dashboard summary on Android Auto
  static Future<bool> updateDashboardSummary({
    required String totalBalance,
    required String monthlyIncome,
    required String monthlyExpense,
    required String savingsRate,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateDashboardSummary', {
        'totalBalance': totalBalance,
        'monthlyIncome': monthlyIncome,
        'monthlyExpense': monthlyExpense,
        'savingsRate': savingsRate,
      });
      return result == true;
    } catch (e) {
      print('Error updating Android Auto dashboard: $e');
      return false;
    }
  }

  /// Switch Android Auto display to Garage view
  static Future<bool> switchToGarage() async {
    try {
      final result = await _channel.invokeMethod('switchToGarage');
      return result == true;
    } catch (e) {
      print('Error switching to garage: $e');
      return false;
    }
  }

  /// Switch Android Auto display to Dashboard view
  static Future<bool> switchToDashboard() async {
    try {
      final result = await _channel.invokeMethod('switchToDashboard');
      return result == true;
    } catch (e) {
      print('Error switching to dashboard: $e');
      return false;
    }
  }

  /// Send an alert to Android Auto
  static Future<bool> sendAlert({
    required String title,
    required String message,
    AlertType type = AlertType.info,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendAlert', {
        'title': title,
        'message': message,
        'alertType': type.name,
      });
      return result == true;
    } catch (e) {
      print('Error sending alert: $e');
      return false;
    }
  }
}

enum AlertType { info, warning, error, success }

/// Helper class to sync Garage data automatically
class GarageAutoSync {
  Timer? _syncTimer;
  final Duration syncInterval;

  GarageAutoSync({this.syncInterval = const Duration(minutes: 5)});

  /// Start automatic syncing of Garage data to Android Auto
  void startSync(Future<GarageSyncData> Function() dataProvider) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (_) async {
      final data = await dataProvider();
      await AndroidAutoService.updateGarageData(
        vehicleName: data.vehicleName,
        odometer: data.odometer,
        mileage: data.mileage,
        lastFuelPrice: data.lastFuelPrice,
        lastFuelDate: data.lastFuelDate,
        nextServiceKm: data.nextServiceKm,
        serviceDueSoon: data.serviceDueSoon,
      );
    });

    // Also sync immediately
    dataProvider().then((data) {
      AndroidAutoService.updateGarageData(
        vehicleName: data.vehicleName,
        odometer: data.odometer,
        mileage: data.mileage,
        lastFuelPrice: data.lastFuelPrice,
        lastFuelDate: data.lastFuelDate,
        nextServiceKm: data.nextServiceKm,
        serviceDueSoon: data.serviceDueSoon,
      );
    });
  }

  /// Stop automatic syncing
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

/// Data class for Garage sync
class GarageSyncData {
  final String vehicleName;
  final double odometer;
  final double mileage;
  final double lastFuelPrice;
  final String lastFuelDate;
  final int nextServiceKm;
  final bool serviceDueSoon;

  GarageSyncData({
    required this.vehicleName,
    required this.odometer,
    required this.mileage,
    required this.lastFuelPrice,
    required this.lastFuelDate,
    this.nextServiceKm = 0,
    this.serviceDueSoon = false,
  });
}
