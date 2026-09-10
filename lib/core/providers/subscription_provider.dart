import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'notification_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  NotificationProvider? _notificationProvider;

  List<Subscription> _subscriptions = [];
  List<Subscription> _dueToday = [];
  bool _isLoading = false;
  String? _error;
  String _filterFrequency = 'all';
  Future<void>? _initializationFuture;
  StreamSubscription<List<Subscription>>? _subscriptionsSubscription;
  StreamSubscription<List<Subscription>>? _dueTodaySubscription;

  SubscriptionProvider();

  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get dueToday => _dueToday;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterFrequency => _filterFrequency;

  void update(NotificationProvider? notification) {
    _notificationProvider = notification;
    _checkSubscriptionReminders();
  }

  // Filtered subscriptions
  List<Subscription> get filteredSubscriptions {
    if (_filterFrequency == 'all') {
      return _subscriptions;
    }
    return _subscriptions
        .where((sub) => sub.frequency == _filterFrequency)
        .toList();
  }

  // Statistics
  double get totalMonthlyCost {
    double total = 0.0;
    for (var subscription in _subscriptions.where((s) => s.isActive)) {
      switch (subscription.frequency) {
        case 'daily':
          total += subscription.amount * 30;
          break;
        case 'weekly':
          total += subscription.amount * 4.33;
          break;
        case 'monthly':
          total += subscription.amount;
          break;
        case 'yearly':
          total += subscription.amount / 12;
          break;
      }
    }
    return total;
  }

  double get totalYearlyCost => totalMonthlyCost * 12;

  int get activeSubscriptionCount =>
      _subscriptions.where((s) => s.isActive).length;
  int get totalSubscriptionCount => _subscriptions.length;

  List<Subscription> get overdueSubscriptions =>
      _subscriptions.where((s) => s.isOverdue).toList();

  // Formatted getters
  String get formattedTotalMonthlyCost =>
      '₹${totalMonthlyCost.toStringAsFixed(2)}';
  String get formattedTotalYearlyCost =>
      '₹${totalYearlyCost.toStringAsFixed(2)}';

  Future<void> initialize() {
    return _initializationFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadSubscriptions(user.uid);
      _loadDueToday(user.uid);
    }
  }

  void _loadSubscriptions(String userId) {
    _setLoading(true);
    _subscriptionsSubscription = _subscriptionService
        .watchActiveSubscriptions(userId)
        .listen(
          (subscriptions) {
            _subscriptions = subscriptions;
            _checkSubscriptionReminders();
            _setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load subscriptions: $error');
            _setLoading(false);
          },
        );
  }

  void _loadDueToday(String userId) {
    _dueTodaySubscription = _subscriptionService
        .watchDueToday(userId)
        .listen(
          (subscriptions) {
            _dueToday = subscriptions;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading due today: $error');
          },
        );
  }

  void _checkSubscriptionReminders() {
    if (_notificationProvider == null) {
      return;
    }
    for (final sub in _subscriptions) {
      _notificationProvider!.checkSubscriptionReminders(
        sub.name,
        sub.nextDueDate,
      );
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      await _subscriptionService.addSubscription(
        subscription.copyWith(userId: user.uid),
      );
    } catch (e) {
      _setError('Failed to add subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      await _subscriptionService.updateSubscription(
        subscription.copyWith(userId: user.uid),
      );
    } catch (e) {
      _setError('Failed to update subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      _setLoading(true);
      await _subscriptionService.deleteSubscription(subscriptionId);
    } catch (e) {
      _setError('Failed to delete subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markSubscriptionPaid(Subscription subscription) async {
    try {
      final nextDate = subscription.calculateNextDueDate();
      final updated = subscription.copyWith(nextDueDate: nextDate);
      await _subscriptionService.updateSubscription(updated);
      // Update local list optimistically
      final idx = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (idx != -1) {
        _subscriptions[idx] = updated;
      }
      // Refresh reminders for this subscription
      if (_notificationProvider != null) {
        _notificationProvider!.checkSubscriptionReminders(
          updated.name,
          updated.nextDueDate,
        );
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark as paid: $e');
    }
  }

  void setFrequencyFilter(String frequency) {
    _filterFrequency = frequency;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await _subscriptionService.clearAllSubscriptions(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final subscriptions = data
        .map((d) => Subscription.fromJson(d as Map<String, dynamic>))
        .toList();
    await _subscriptionService.restoreSubscriptions(user.uid, subscriptions);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void reset() {
    _subscriptions = [];
    _dueToday = [];
    _isLoading = false;
    _error = null;
    _filterFrequency = 'all';
    notifyListeners();
  }

  void clear() {
    reset();
  }

  @override
  void dispose() {
    _subscriptionsSubscription?.cancel();
    _dueTodaySubscription?.cancel();
    super.dispose();
  }
}
