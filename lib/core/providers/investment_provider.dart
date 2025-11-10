import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService _investmentService = InvestmentService();

  List<Investment> _investments = [];
  List<InvestmentTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Investment> get investments => _investments;
  List<InvestmentTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Portfolio calculations
  double get totalPortfolioValue => _investments.fold(
    0.0,
    (sum, investment) => sum + investment.currentValue,
  );

  double get totalInvested => _investments.fold(
    0.0,
    (sum, investment) => sum + investment.totalInvested,
  );

  double get totalGainLoss => totalPortfolioValue - totalInvested;

  double get totalGainLossPercentage =>
      totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

  bool get isPortfolioProfitable => totalGainLoss > 0;

  String get formattedTotalValue =>
      '₹${totalPortfolioValue.toStringAsFixed(2)}';
  String get formattedTotalInvested => '₹${totalInvested.toStringAsFixed(2)}';
  String get formattedGainLoss {
    final sign = totalGainLoss >= 0 ? '+' : '';
    return '$sign₹${totalGainLoss.toStringAsFixed(2)}';
  }

  String get formattedGainLossPercentage {
    final sign = totalGainLossPercentage >= 0 ? '+' : '';
    return '$sign${totalGainLossPercentage.toStringAsFixed(2)}%';
  }

  /// Initialize and start listening to investments
  void initialize() {
    _loadInvestments();
  }

  /// Load investments from Firestore
  void _loadInvestments() {
    _setLoading(true);
    _investmentService.watchInvestments().listen(
      (investments) {
        _investments = investments;
        _setLoading(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load investments: $error');
        _setLoading(false);
      },
    );
  }

  /// Add a new investment
  Future<void> addInvestment(Investment investment) async {
    try {
      _setLoading(true);
      await _investmentService.addInvestment(investment);
      _clearError();
    } catch (e) {
      _setError('Failed to add investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing investment
  Future<void> updateInvestment(Investment investment) async {
    try {
      _setLoading(true);
      await _investmentService.updateInvestment(investment);
      _clearError();
    } catch (e) {
      _setError('Failed to update investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an investment
  Future<void> deleteInvestment(String investmentId) async {
    try {
      _setLoading(true);
      await _investmentService.deleteInvestment(investmentId);
      _clearError();
    } catch (e) {
      _setError('Failed to delete investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get investments for a specific account
  List<Investment> getInvestmentsByAccount(String accountId) {
    return _investments
        .where((investment) => investment.accountId == accountId)
        .toList();
  }

  /// Get investments by type
  List<Investment> getInvestmentsByType(InvestmentType type) {
    return _investments.where((investment) => investment.type == type).toList();
  }

  /// Add investment transaction
  Future<void> addInvestmentTransaction(
    InvestmentTransaction transaction,
  ) async {
    try {
      _setLoading(true);
      await _investmentService.addInvestmentTransaction(transaction);
      _clearError();
    } catch (e) {
      _setError('Failed to add transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load transactions for a specific investment
  void loadTransactionsForInvestment(String investmentId) {
    _investmentService
        .watchInvestmentTransactions(investmentId)
        .listen(
          (transactions) {
            _transactions = transactions;
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load transactions: $error');
          },
        );
  }

  /// Get portfolio distribution by investment type
  Map<InvestmentType, double> getPortfolioDistribution() {
    Map<InvestmentType, double> distribution = {};

    for (var investment in _investments) {
      distribution[investment.type] =
          (distribution[investment.type] ?? 0.0) + investment.currentValue;
    }

    return distribution;
  }

  /// Get top performing investments
  List<Investment> getTopPerformers({int limit = 5}) {
    final sortedInvestments = List<Investment>.from(_investments);
    sortedInvestments.sort(
      (a, b) => b.gainLossPercentage.compareTo(a.gainLossPercentage),
    );
    return sortedInvestments.take(limit).toList();
  }

  /// Get worst performing investments
  List<Investment> getWorstPerformers({int limit = 5}) {
    final sortedInvestments = List<Investment>.from(_investments);
    sortedInvestments.sort(
      (a, b) => a.gainLossPercentage.compareTo(b.gainLossPercentage),
    );
    return sortedInvestments.take(limit).toList();
  }

  /// Update current prices for all investments
  Future<void> refreshPrices() async {
    try {
      _setLoading(true);
      await _investmentService.updateCurrentPrices();
      _clearError();
    } catch (e) {
      _setError('Failed to refresh prices: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get investment by ID
  Investment? getInvestmentById(String id) {
    try {
      return _investments.firstWhere((investment) => investment.id == id);
    } catch (e) {
      return null;
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

}
