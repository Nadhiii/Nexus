import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Subscription> _subscriptions = [];
  List<Subscription> _dueToday = [];
  bool _isLoading = false;
  String? _error;
  String _filterFrequency = 'all';

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

  /// Initialize and start listening to subscriptions
  void initialize() {
    _loadSubscriptions();
    _loadDueToday();
  }

  /// Load all subscriptions from Firestore
  void _loadSubscriptions() {
    _setLoading(true);
    _subscriptionService.watchActiveSubscriptions().listen(
      (subscriptions) {
        _subscriptions = subscriptions;
        _setLoading(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load subscriptions: $error');
        _setLoading(false);
      },
    );
  }

  /// Load subscriptions due today
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

  /// Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      await _subscriptionService.addSubscription(subscription);
      _clearError();
    } catch (e) {
      _setError('Failed to add subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing subscription
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      _setLoading(true);
      await _subscriptionService.updateSubscription(subscription);
      _clearError();
    } catch (e) {
      _setError('Failed to update subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      _setLoading(true);
      await _subscriptionService.deleteSubscription(subscriptionId);
      _clearError();
    } catch (e) {
      _setError('Failed to delete subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mark subscription as paid and update next due date
  Future<void> markAsPaid(String subscriptionId) async {
    try {
      await _subscriptionService.updateNextDueDate(subscriptionId);
      _clearError();
    } catch (e) {
      _setError('Failed to mark as paid: $e');
    }
  }

  /// Toggle subscription active status
  Future<void> toggleSubscriptionStatus(String subscriptionId) async {
    try {
      await _subscriptionService.toggleSubscriptionStatus(subscriptionId);
      _clearError();
    } catch (e) {
      _setError('Failed to toggle subscription: $e');
    }
  }

  /// Set frequency filter
  void setFrequencyFilter(String frequency) {
    _filterFrequency = frequency;
    notifyListeners();
  }

  /// Get subscription by ID
  Subscription? getSubscriptionById(String id) {
    try {
      return _subscriptions.firstWhere((subscription) => subscription.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get subscriptions by frequency
  List<Subscription> getSubscriptionsByFrequency(String frequency) {
    return _subscriptions.where((sub) => sub.frequency == frequency && sub.isActive).toList();
  }

  /// Get subscription distribution
  Map<String, int> getFrequencyDistribution() {
    Map<String, int> distribution = {
      'daily': 0,
      'weekly': 0,
      'monthly': 0,
      'yearly': 0,
    };

    for (var subscription in _subscriptions.where((s) => s.isActive)) {
      distribution[subscription.frequency] = 
          (distribution[subscription.frequency] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get upcoming subscriptions (next 7 days)
  List<Subscription> getUpcomingSubscriptions() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return _subscriptions
        .where((sub) => 
            sub.isActive && 
            sub.nextDueDate.isAfter(now) && 
            sub.nextDueDate.isBefore(nextWeek))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  /// Get most expensive subscriptions
  List<Subscription> getMostExpensive({int limit = 5}) {
    final sortedSubscriptions = List<Subscription>.from(
      _subscriptions.where((s) => s.isActive)
    );
    sortedSubscriptions.sort((a, b) => b.amount.compareTo(a.amount));
    return sortedSubscriptions.take(limit).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
