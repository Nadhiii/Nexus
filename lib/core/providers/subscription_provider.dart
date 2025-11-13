import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'notification_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  NotificationProvider? notificationProvider;

  List<Subscription> _subscriptions = [];
  List<Subscription> _dueToday = [];
  bool _isLoading = false;
  String? _error;
  String _filterFrequency = 'all';

  SubscriptionProvider({this.notificationProvider});

  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get dueToday => _dueToday;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterFrequency => _filterFrequency;

  // Filtered subscriptions
  List<Subscription> get filteredSubscriptions {
    if (_filterFrequency == 'all') {
      return _subscriptions;
    }
    return _subscriptions.where((sub) => sub.frequency == _filterFrequency).toList();
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

  int get activeSubscriptionCount => _subscriptions.where((s) => s.isActive).length;
  int get totalSubscriptionCount => _subscriptions.length;

  List<Subscription> get overdueSubscriptions =>
      _subscriptions.where((s) => s.isOverdue).toList();

  // Formatted getters
  String get formattedTotalMonthlyCost => '₹${totalMonthlyCost.toStringAsFixed(2)}';
  String get formattedTotalYearlyCost => '₹${totalYearlyCost.toStringAsFixed(2)}';


  void initialize() {
    _loadSubscriptions();
    _loadDueToday();
  }

  void _loadSubscriptions() {
    _setLoading(true);
    _subscriptionService.watchActiveSubscriptions().listen(
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

  void _loadDueToday() {
    _subscriptionService.watchDueToday().listen(
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
    for (final sub in _subscriptions) {
      notificationProvider?.checkSubscriptionReminders(sub.name, sub.nextDueDate);
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      await _subscriptionService.addSubscription(subscription);
    } catch (e) {
      _setError('Failed to add subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      await _subscriptionService.updateSubscription(subscription);
    } catch (e) {
      _setError('Failed to update subscription: $e');
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
    } finally {
      _setLoading(false);
    }
  }

  void setFrequencyFilter(String frequency) {
    _filterFrequency = frequency;
    notifyListeners();
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
}
