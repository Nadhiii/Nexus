import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtService _debtService = DebtService();

  List<Debt> _debts = [];
  Map<String, dynamic> _statistics = {};
  DebtPayoffStrategy _selectedStrategy = DebtPayoffStrategy.avalanche;
  double _extraPayment = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Debt> get debts => _debts;
  Map<String, dynamic> get statistics => _statistics;
  DebtPayoffStrategy get selectedStrategy => _selectedStrategy;
  double get extraPayment => _extraPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculated getters
  double get totalDebt => _statistics['totalDebt']?.toDouble() ?? 0.0;
  double get totalMinimumPayments =>
      _statistics['totalMinimumPayments']?.toDouble() ?? 0.0;
  double get totalMonthlyInterest =>
      _statistics['totalMonthlyInterest']?.toDouble() ?? 0.0;
  double get averageInterestRate =>
      _statistics['averageInterestRate']?.toDouble() ?? 0.0;
  int get debtCount => _statistics['debtCount']?.toInt() ?? 0;
  double get totalProgress => _statistics['totalProgress']?.toDouble() ?? 0.0;

  // Formatted getters
  String get formattedTotalDebt => '₹${totalDebt.toStringAsFixed(2)}';
  String get formattedTotalMinimumPayments =>
      '₹${totalMinimumPayments.toStringAsFixed(2)}';
  String get formattedTotalMonthlyInterest =>
      '₹${totalMonthlyInterest.toStringAsFixed(2)}';
  String get formattedAverageInterestRate =>
      '${averageInterestRate.toStringAsFixed(1)}%';

  // Debt-free calculation
  Map<String, dynamic> get debtFreeCalculation {
    return _debtService.calculateDebtFreeDate(
      _debts,
      _selectedStrategy,
      _extraPayment,
    );
  }

  // Initialize the provider with user data
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupDebtStreams(user.uid);
    }
  }

  // Setup real-time streams for debt data
  void _setupDebtStreams(String userId) {
    _setLoading(true);

    // Listen to debts sorted by strategy
    _debtService
        .watchDebtsByStrategy(userId, _selectedStrategy)
        .listen(
          (debts) {
            _debts = debts;
            _setLoading(false);
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load debts: $error');
            _setLoading(false);
          },
        );

    // Listen to debt statistics
    _debtService
        .watchDebtStatistics(userId)
        .listen(
          (stats) {
            _statistics = stats;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error calculating debt statistics: $error');
          },
        );
  }

  // Change payoff strategy
  void setPayoffStrategy(DebtPayoffStrategy strategy) {
    if (_selectedStrategy != strategy) {
      _selectedStrategy = strategy;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _setupDebtStreams(user.uid); // Reload with new strategy
      }
      notifyListeners();
    }
  }

  // Set extra payment amount
  void setExtraPayment(double amount) {
    if (_extraPayment != amount) {
      _extraPayment = amount;
      notifyListeners();
    }
  }

  // Create a new debt
  Future<bool> createDebt(Debt debt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      await _debtService.createDebt(user.uid, debt);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to create debt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing debt
  Future<bool> updateDebt(Debt debt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      await _debtService.updateDebt(user.uid, debt);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update debt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Record a payment
  Future<bool> recordPayment(String debtId, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      await _debtService.recordPayment(user.uid, debtId, amount);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to record payment: $e');
      return false;
    }
  }

  // Delete a debt
  Future<bool> deleteDebt(String debtId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      await _debtService.deleteDebt(user.uid, debtId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete debt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get debt by ID
  Debt? getDebtById(String debtId) {
    try {
      return _debts.firstWhere((debt) => debt.id == debtId);
    } catch (e) {
      return null;
    }
  }

  // Get debts by type
  List<Debt> getDebtsByType(DebtType type) {
    return _debts.where((debt) => debt.type == type).toList();
  }

  // Get high-priority debts (overdue or high interest)
  List<Debt> get priorityDebts {
    return _debts
        .where((debt) => debt.isOverdue || debt.isHighInterest)
        .toList();
  }

  // Calculate savings with different strategies
  Map<String, Map<String, dynamic>> calculateStrategySavings() {
    Map<String, Map<String, dynamic>> results = {};

    for (DebtPayoffStrategy strategy in DebtPayoffStrategy.values) {
      results[strategy.name] = _debtService.calculateDebtFreeDate(
        _debts,
        strategy,
        _extraPayment,
      );
    }

    return results;
  }

  // Reset provider state (for logout)
  void reset() {
    _debts = [];
    _statistics = {};
    _selectedStrategy = DebtPayoffStrategy.avalanche;
    _extraPayment = 0.0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupDebtStreams(user.uid);
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

  // Utility methods
  String getStrategyName(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.snowball:
        return 'Debt Snowball';
      case DebtPayoffStrategy.avalanche:
        return 'Debt Avalanche';
      case DebtPayoffStrategy.custom:
        return 'Custom Priority';
    }
  }

  String getStrategyDescription(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.snowball:
        return 'Pay minimums on all debts, focus extra money on smallest balance first. Builds momentum and motivation.';
      case DebtPayoffStrategy.avalanche:
        return 'Pay minimums on all debts, focus extra money on highest interest rate first. Saves most money mathematically.';
      case DebtPayoffStrategy.custom:
        return 'Pay debts based on your custom priority order. You decide what matters most.';
    }
  }
}
