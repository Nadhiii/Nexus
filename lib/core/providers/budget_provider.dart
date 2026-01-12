import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/budget_service.dart';
import 'notification_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  NotificationProvider? _notificationProvider;

  List<Budget> _budgets = [];
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  String _selectedPeriod = 'monthly';

  // Getters
  List<Budget> get budgets => _budgets;
  Map<String, dynamic> get analytics => _analytics;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPeriod => _selectedPeriod;

  void update(NotificationProvider? notification) {
    _notificationProvider = notification;
  }

  // Filtered budgets
  List<Budget> get activeBudgets =>
      _budgets.where((budget) => budget.isPeriodActive).toList();
  List<Budget> get overBudgets =>
      _budgets.where((budget) => budget.isOverspent).toList();
  List<Budget> get nearLimitBudgets =>
      _budgets.where((budget) => budget.isNearLimit).toList();
  List<Budget> get onTrackBudgets =>
      _budgets.where((budget) => budget.isOnTrack).toList();

  // Analytics getters
  double get totalAllocated => _analytics['totalAllocated']?.toDouble() ?? 0.0;
  double get totalSpent => _analytics['totalSpent']?.toDouble() ?? 0.0;
  double get totalRemaining => _analytics['totalRemaining']?.toDouble() ?? 0.0;
  double get overallProgress =>
      _analytics['overallProgress']?.toDouble() ?? 0.0;
  int get budgetCount => _analytics['budgetCount']?.toInt() ?? 0;
  int get overBudgetCount => _analytics['overBudgetCount']?.toInt() ?? 0;
  int get nearLimitCount => _analytics['nearLimitCount']?.toInt() ?? 0;
  int get onTrackCount => _analytics['onTrackCount']?.toInt() ?? 0;
  double get averageProgress =>
      _analytics['averageProgress']?.toDouble() ?? 0.0;
  double get projectedTotalSpending =>
      _analytics['projectedTotalSpending']?.toDouble() ?? 0.0;

  // Formatted getters
  String get formattedTotalAllocated => '₹${totalAllocated.toStringAsFixed(2)}';
  String get formattedTotalSpent => '₹${totalSpent.toStringAsFixed(2)}';
  String get formattedTotalRemaining => '₹${totalRemaining.toStringAsFixed(2)}';
  String get formattedProjectedSpending =>
      '₹${projectedTotalSpending.toStringAsFixed(2)}';

  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupBudgetStreams(user.uid);
    }
  }

  void _setupBudgetStreams(String userId) {
    _loadBudgets(userId);
    _loadAnalytics(userId);
    _loadRecommendations(userId);
  }

  void _loadBudgets(String userId) {
    _setLoading(true);
    _budgetService
        .watchCurrentPeriodBudgets(userId)
        .listen(
          (budgets) {
            _budgets = budgets;
            _setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load budgets: $error');
            _setLoading(false);
          },
        );
  }

  void _loadAnalytics(String userId) {
    _budgetService
        .watchBudgetAnalytics(userId)
        .listen(
          (analytics) {
            _analytics = analytics;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error loading analytics: $error');
          },
        );
  }

  void _loadRecommendations(String userId) async {
    try {
      _recommendations = await _budgetService.getBudgetRecommendations(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<void> createBudget(Budget budget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      await _budgetService.createBudget(user.uid, budget);
      await refresh();
    } catch (e) {
      _setError('Failed to create budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBudget(Budget budget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      await _budgetService.updateBudget(user.uid, budget);
    } catch (e) {
      _setError('Failed to update budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      await _budgetService.deleteBudget(user.uid, budgetId);
    } catch (e) {
      _setError('Failed to delete budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkBudgetForTransaction(Transaction transaction) async {
    try {
      final budget = _budgets.firstWhere(
        (b) => b.categoryId == transaction.categoryId,
      );
      final newSpentAmount = budget.spentAmount + transaction.amount;
      _notificationProvider?.checkBudgetThresholds(
        newSpentAmount,
        budget.allocatedAmount,
        budget.categoryName,
        budget.period,
      );
    } catch (e) {
      // No budget found for this category, which is fine.
    }
  }

  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupBudgetStreams(user.uid);
    }
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
    _budgets = [];
    _analytics = {};
    _recommendations = [];
    _selectedPeriod = 'monthly';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void clear() {
    reset();
  }
}
