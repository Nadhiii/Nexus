import 'package:flutter/foundation.dart';
import 'package:nexus/core/services/android_auto_service.dart';

/// Android Auto state model
class AndroidAutoState {
  final bool isConnected;
  final String currentScreen;
  final Map<String, dynamic> dashboardData;
  final List<Map<String, dynamic>> recentTransactions;
  final String? lastAlert;

  AndroidAutoState({
    this.isConnected = false,
    this.currentScreen = 'dashboard',
    this.dashboardData = const {},
    this.recentTransactions = const [],
    this.lastAlert,
  });

  AndroidAutoState copyWith({
    bool? isConnected,
    String? currentScreen,
    Map<String, dynamic>? dashboardData,
    List<Map<String, dynamic>>? recentTransactions,
    String? lastAlert,
  }) {
    return AndroidAutoState(
      isConnected: isConnected ?? this.isConnected,
      currentScreen: currentScreen ?? this.currentScreen,
      dashboardData: dashboardData ?? this.dashboardData,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      lastAlert: lastAlert ?? this.lastAlert,
    );
  }
}

/// Provider for managing Android Auto state and communication
class AndroidAutoProvider extends ChangeNotifier {
  AndroidAutoState _state = AndroidAutoState();

  AndroidAutoState get state => _state;

  bool get isConnected => _state.isConnected;
  bool get isAvailable => _state.isConnected;

  /// Initialize Android Auto connection
  Future<void> initialize() async {
    try {
      await AndroidAutoService.initializeAndroidAuto();
      final connected = await AndroidAutoService.isAndroidAutoConnected();
      _state = _state.copyWith(isConnected: connected);
      notifyListeners();
    } catch (e) {
      print('Failed to initialize Android Auto: $e');
    }
  }

  /// Update dashboard summary on Android Auto display
  Future<void> updateDashboardSummary({
    required String totalBalance,
    required String monthlyIncome,
    required String monthlyExpense,
    required String savingsRate,
  }) async {
    try {
      await AndroidAutoService.sendDashboardSummary(
        totalBalance: totalBalance,
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        savingsRate: savingsRate,
      );

      _state = _state.copyWith(
        dashboardData: {
          'totalBalance': totalBalance,
          'monthlyIncome': monthlyIncome,
          'monthlyExpense': monthlyExpense,
          'savingsRate': savingsRate,
        },
      );
      notifyListeners();
    } catch (e) {
      print('Failed to update dashboard summary: $e');
    }
  }

  /// Send recent transactions to Android Auto
  Future<void> updateRecentTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      await AndroidAutoService.sendRecentTransactions(transactions);
      _state = _state.copyWith(recentTransactions: transactions);
      notifyListeners();
    } catch (e) {
      print('Failed to update recent transactions: $e');
    }
  }

  /// Send an alert/notification to Android Auto
  Future<void> sendAlert({
    required String title,
    required String message,
    String alertType = 'info', // 'info', 'warning', 'error'
  }) async {
    try {
      await AndroidAutoService.sendAlert(
        title: title,
        message: message,
        alertType: alertType,
      );
      _state = _state.copyWith(lastAlert: '$title: $message');
      notifyListeners();
    } catch (e) {
      print('Failed to send alert: $e');
    }
  }

  /// Update app state on Android Auto
  Future<void> updateAppState({
    required String title,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    try {
      await AndroidAutoService.sendAppState(
        title: title,
        content: content,
        data: data ?? {},
      );
      _state = _state.copyWith(currentScreen: title);
      notifyListeners();
    } catch (e) {
      print('Failed to update app state: $e');
    }
  }

  /// Handle action from Android Auto (e.g., button press)
  Future<void> handleAndroidAutoAction(String actionId) async {
    try {
      await AndroidAutoService.handleAndroidAutoAction(actionId);
    } catch (e) {
      print('Failed to handle Android Auto action: $e');
    }
  }

  /// Check if Android Auto is connected
  Future<void> checkConnection() async {
    try {
      final connected = await AndroidAutoService.isAndroidAutoConnected();
      _state = _state.copyWith(isConnected: connected);
      notifyListeners();
    } catch (e) {
      print('Failed to check Android Auto connection: $e');
    }
  }
}
