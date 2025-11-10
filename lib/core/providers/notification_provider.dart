import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  bool get hasUnread => unreadCount > 0;

  NotificationProvider() {
    _loadNotifications();
    _generateSampleNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('app_notifications');
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications = notificationsList
            .map((json) => AppNotification.fromMap(json))
            .toList();
        
        // Sort by creation date (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((notification) => notification.toMap()).toList(),
      );
      await prefs.setString('app_notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void addNotification(AppNotification notification) {
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
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  void _generateSampleNotifications() {
    // Only generate if no notifications exist
    if (_notifications.isEmpty) {
      final sampleNotifications = [
        AppNotification.billReminder(
          billName: 'Electricity Bill',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          amount: 2500.0,
        ),
        AppNotification.goalProgress(
          goalName: 'Emergency Fund',
          currentAmount: 75000.0,
          targetAmount: 100000.0,
          progressPercentage: 75.0,
        ),
        AppNotification.transactionAlert(
          description: 'Salary Credit',
          amount: 85000.0,
          isIncome: true,
        ),
        AppNotification.unusualSpending(
          amount: 8500.0,
          category: 'Entertainment',
        ),
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: NotificationType.systemUpdate,
          title: 'Welcome to Nexus!',
          message: 'Start tracking your finances with our powerful tools.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          actionText: 'Get Started',
          actionRoute: '/dashboard',
        ),
      ];

      _notifications.addAll(sampleNotifications);
      _saveNotifications();
      notifyListeners();
    }
  }

  // Helper methods to trigger notifications
  void notifyBillDue(String billName, DateTime dueDate, double amount) {
    addNotification(AppNotification.billReminder(
      billName: billName,
      dueDate: dueDate,
      amount: amount,
    ));
  }

  void notifyGoalAchieved(String goalName, double targetAmount) {
    addNotification(AppNotification.goalAchievement(
      goalName: goalName,
      targetAmount: targetAmount,
    ));
  }

  void notifyUnusualSpending(double amount, String category) {
    addNotification(AppNotification.unusualSpending(
      amount: amount,
      category: category,
    ));
  }

  void notifyTransaction(String description, double amount, bool isIncome) {
    addNotification(AppNotification.transactionAlert(
      description: description,
      amount: amount,
      isIncome: isIncome,
    ));
  }

  void notifyGoalProgress(String goalName, double currentAmount, 
                         double targetAmount, double progressPercentage) {
    addNotification(AppNotification.goalProgress(
      goalName: goalName,
      currentAmount: currentAmount,
      targetAmount: targetAmount,
      progressPercentage: progressPercentage,
    ));
  }
}
