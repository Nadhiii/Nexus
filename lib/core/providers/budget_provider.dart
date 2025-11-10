import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

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

  // Filtered budgets
  List<Budget> get activeBudgets => _budgets.where((budget) => budget.isPeriodActive).toList();
  List<Budget> get overBudgets => _budgets.where((budget) => budget.isOverspent).toList();
  List<Budget> get nearLimitBudgets => _budgets.where((budget) => budget.isNearLimit).toList();
  List<Budget> get onTrackBudgets => _budgets.where((budget) => budget.isOnTrack).toList();

  // Analytics getters
  double get totalAllocated => _analytics['totalAllocated']?.toDouble() ?? 0.0;
  double get totalSpent => _analytics['totalSpent']?.toDouble() ?? 0.0;
  double get totalRemaining => _analytics['totalRemaining']?.toDouble() ?? 0.0;
  double get overallProgress => _analytics['overallProgress']?.toDouble() ?? 0.0;
  int get budgetCount => _analytics['budgetCount']?.toInt() ?? 0;
  int get overBudgetCount => _analytics['overBudgetCount']?.toInt() ?? 0;
  int get nearLimitCount => _analytics['nearLimitCount']?.toInt() ?? 0;
  int get onTrackCount => _analytics['onTrackCount']?.toInt() ?? 0;
  double get averageProgress => _analytics['averageProgress']?.toDouble() ?? 0.0;
  double get projectedTotalSpending => _analytics['projectedTotalSpending']?.toDouble() ?? 0.0;

  // Formatted getters
  String get formattedTotalAllocated => '₹${totalAllocated.toStringAsFixed(2)}';
  String get formattedTotalSpent => '₹${totalSpent.toStringAsFixed(2)}';
  String get formattedTotalRemaining => '₹${totalRemaining.toStringAsFixed(2)}';
  String get formattedProjectedSpending => '₹${projectedTotalSpending.toStringAsFixed(2)}';

  /// Initialize and start listening to budgets
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupBudgetStreams(user.uid);
    }
  }

  /// Setup budget streams for a specific user
  void _setupBudgetStreams(String userId) {
    _loadBudgets(userId);
    _loadAnalytics(userId);
    _loadRecommendations(userId);
  }

  /// Load budgets from Firestore
  void _loadBudgets(String userId) {
    _setLoading(true);
    _budgetService.watchCurrentPeriodBudgets(userId).listen(
      (budgets) {
        _budgets = budgets;
        _setLoading(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load budgets: $error');
        _setLoading(false);
      },
    );
  }

  /// Load analytics
  void _loadAnalytics(String userId) {
    _budgetService.watchBudgetAnalytics(userId).listen(
      (analytics) {
        _analytics = analytics;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading analytics: $error');
      },
    );
  }

  /// Load recommendations
  void _loadRecommendations(String userId) async {
    try {
      _recommendations = await _budgetService.getBudgetRecommendations(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  /// Create a new budget
  Future<void> createBudget(Budget budget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _budgetService.createBudget(user.uid, budget);
      await refresh(); // Refresh data to show the new budget
      _clearError();
    } catch (e) {
      _setError('Failed to create budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _budgetService.updateBudget(user.uid, budget);
      _clearError();
    } catch (e) {
      _setError('Failed to update budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _budgetService.deleteBudget(user.uid, budgetId);
      _clearError();
    } catch (e) {
      _setError('Failed to delete budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create monthly budgets based on income
  Future<void> createMonthlyBudgets(double monthlyIncome, DateTime startDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _budgetService.createMonthlyBudgets(user.uid, monthlyIncome, startDate);
      _clearError();
    } catch (e) {
      _setError('Failed to create monthly budgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update all spent amounts
  Future<void> updateAllSpentAmounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      await _budgetService.updateAllSpentAmounts(user.uid);
      _clearError();
    } catch (e) {
      _setError('Failed to update spent amounts: $e');
    }
  }

  /// Clone budgets from previous period
  Future<void> cloneBudgetsFromPreviousPeriod(DateTime newStartDate, String period) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoading(true);
      await _budgetService.cloneBudgetsFromPreviousPeriod(user.uid, newStartDate, period);
      _clearError();
    } catch (e) {
      _setError('Failed to clone budgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set period filter
  void setPeriodFilter(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _loadBudgetsByPeriod(user.uid);
      }
      notifyListeners();
    }
  }

  /// Load budgets by period
  void _loadBudgetsByPeriod(String userId) {
    _setLoading(true);
    _budgetService.watchBudgetsByPeriod(userId, _selectedPeriod).listen(
      (budgets) {
        _budgets = budgets;
        _setLoading(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load budgets: $error');
        _setLoading(false);
      },
    );
  }

  /// Get budget by ID
  Budget? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get budgets by category
  List<Budget> getBudgetsByCategory(String categoryId) {
    return _budgets.where((budget) => budget.categoryId == categoryId).toList();
  }

  /// Get essential budgets (housing, food, transportation)
  List<Budget> get essentialBudgets {
    return _budgets.where((budget) => 
        budget.metadata?['isEssential'] == true).toList();
  }

  /// Get lifestyle budgets (entertainment, shopping, etc.)
  List<Budget> get lifestyleBudgets {
    return _budgets.where((budget) => 
        budget.metadata?['isEssential'] != true).toList();
  }

  /// Calculate budget distribution
  Map<String, double> getBudgetDistribution() {
    Map<String, double> distribution = {};
    
    for (var budget in _budgets) {
      distribution[budget.categoryName] = budget.allocatedAmount;
    }
    
    return distribution;
  }

  /// Calculate spending distribution
  Map<String, double> getSpendingDistribution() {
    Map<String, double> distribution = {};
    
    for (var budget in _budgets) {
      distribution[budget.categoryName] = budget.spentAmount;
    }
    
    return distribution;
  }

  /// Get budget efficiency (how well allocated vs spent)
  List<Map<String, dynamic>> getBudgetEfficiency() {
    return _budgets.map((budget) => {
      'category': budget.categoryName,
      'allocated': budget.allocatedAmount,
      'spent': budget.spentAmount,
      'efficiency': budget.allocatedAmount > 0 
          ? (budget.spentAmount / budget.allocatedAmount) 
          : 0.0,
      'status': budget.statusDescription,
    }).toList()..sort((a, b) => (b['efficiency'] as double).compareTo(a['efficiency'] as double));
  }

  /// Get spending trends
  List<Map<String, dynamic>> getSpendingTrends() {
    return _budgets.map((budget) => {
      'category': budget.categoryName,
      'current': budget.spentAmount,
      'projected': budget.projectedSpending,
      'trend': budget.spendingTrend.toString().split('.').last,
      'daysRemaining': budget.daysRemaining,
      'recommendedDaily': budget.recommendedDailySpending,
    }).toList();
  }

  /// Refresh data
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupBudgetStreams(user.uid);
    }
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

  /// Reset provider state (for logout)
  void reset() {
    _budgets = [];
    _analytics = {};
    _recommendations = [];
    _selectedPeriod = 'monthly';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
