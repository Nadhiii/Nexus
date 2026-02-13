import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const _notificationsStorageKey = 'app_notifications';
  static const _migrationKey = 'notifications_migrated_v1';

  // Settings keys
  static const _budgetAlertsKey = 'notifications_budget_alerts';
  static const _subscriptionRemindersKey =
      'notifications_subscription_reminders';
  static const _largeTransactionAlertsKey = 'notifications_large_transactions';
  static const _fuelNotificationsKey = 'notifications_fuel_logged';

  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  // Notification Settings
  bool _budgetAlertsEnabled = true;
  bool _subscriptionRemindersEnabled = true;
  bool _largeTransactionAlertsEnabled = true;
  bool _fuelNotificationsEnabled = true;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get budgetAlertsEnabled => _budgetAlertsEnabled;
  bool get subscriptionRemindersEnabled => _subscriptionRemindersEnabled;
  bool get largeTransactionAlertsEnabled => _largeTransactionAlertsEnabled;
  bool get fuelNotificationsEnabled => _fuelNotificationsEnabled;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSettings();
    await _runMigration();
    await _loadNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetAlertsEnabled = prefs.getBool(_budgetAlertsKey) ?? true;
    _subscriptionRemindersEnabled =
        prefs.getBool(_subscriptionRemindersKey) ?? true;
    _largeTransactionAlertsEnabled =
        prefs.getBool(_largeTransactionAlertsKey) ?? true;
    _fuelNotificationsEnabled = prefs.getBool(_fuelNotificationsKey) ?? true;
    notifyListeners();
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await _loadSettings(); // Reload all settings to ensure consistency
  }

  Future<void> _runMigration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_migrationKey) ?? false)) {
      await prefs.remove(_notificationsStorageKey);
      await prefs.setBool(_migrationKey, true);
    }
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_notificationsStorageKey);
      if (json != null) {
        _notifications = (jsonDecode(json) as List)
            .map((item) => AppNotification.fromMap(item))
            .toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      _notifications = [];
      await _saveNotifications();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationsStorageKey,
      jsonEncode(_notifications.map((n) => n.toMap()).toList()),
    );
  }

  void addNotification(AppNotification notification) {
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    _saveNotifications();
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _saveNotifications();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  void sendTestNotification() {
    addNotification(
      AppNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.systemUpdate,
        title: 'Test Notification',
        message: 'If you see this, your notifications are working correctly!',
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyTransaction(
    String description,
    double amount,
    bool isIncome, {
    double threshold = 10000,
  }) {
    if (_largeTransactionAlertsEnabled && amount.abs() > threshold) {
      addNotification(
        AppNotification.transactionAlert(
          description: description,
          amount: amount,
          isIncome: isIncome,
        ),
      );
    }
  }

  void checkBudgetThresholds(
    double totalSpent,
    double budgetAmount,
    String budgetCategory,
    String budgetCycle,
  ) {
    if (_budgetAlertsEnabled) {
      final threshold = budgetAmount * 0.9;
      if (totalSpent >= threshold && totalSpent < budgetAmount) {
        addNotification(
          AppNotification.budgetWarning(
            category: budgetCategory,
            cycle: budgetCycle,
            spentAmount: totalSpent,
            budgetAmount: budgetAmount,
          ),
        );
      }
    }
  }

  void checkSubscriptionReminders(
    String subscriptionName,
    DateTime nextPaymentDate,
  ) {
    if (_subscriptionRemindersEnabled) {
      final reminderDays = 3;
      final reminderDate = nextPaymentDate.subtract(
        Duration(days: reminderDays),
      );
      if (DateTime.now().isAfter(reminderDate) &&
          DateTime.now().isBefore(nextPaymentDate)) {
        addNotification(
          AppNotification.subscriptionReminder(
            subscriptionName: subscriptionName,
            dueDate: nextPaymentDate,
          ),
        );
      }
    }
  }

  void notifyFuelLogged({
    required String vehicleName,
    required double mileage,
    required double fuelAmount,
    required double cost,
  }) {
    if (_fuelNotificationsEnabled && mileage > 0) {
      addNotification(
        AppNotification.fuelLogged(
          vehicleName: vehicleName,
          mileage: mileage,
          fuelAmount: fuelAmount,
          cost: cost,
        ),
      );
    }
  }
}
