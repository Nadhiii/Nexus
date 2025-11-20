import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebtProvider extends ChangeNotifier {
  final DebtService _debtService = DebtService();
  List<Debt> _debts = [];
  bool _isLoading = false;
  String? _error;
  DebtPayoffStrategy _selectedStrategy = DebtPayoffStrategy.snowball;
  Map<String, dynamic>? _debtFreeCalculation;


  List<Debt> get debts => _getSortedDebts();

  bool get isLoading => _isLoading;
  String? get error => _error;
  DebtPayoffStrategy get selectedStrategy => _selectedStrategy;
  Map<String, dynamic>? get debtFreeCalculation => _debtFreeCalculation;

  double get totalDebt => _debts.fold(0.0, (sum, debt) => sum + debt.currentBalance);
  double get totalMinimumPayments => _debts.fold(0.0, (sum, debt) => sum + (debt.monthlyEMI ?? 0.0));
  String get formattedTotalMinimumPayments => '₹${totalMinimumPayments.toStringAsFixed(2)}';
  double get totalMonthlyInterest => _debts.fold(0.0, (sum, debt) => sum + debt.monthlyInterestPayment);
  String get formattedTotalMonthlyInterest => '₹${totalMonthlyInterest.toStringAsFixed(2)}';


  DebtProvider() {
    initialize();
  }

  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadDebts(user.uid);
    }
  }
  
  void refresh(){
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        loadDebts(user.uid);
      }
  }


  Future<void> loadDebts(String userId) async {
    _setLoading(true);
    try {
      _debtService.watchDebts(userId).listen((debts) {
        _debts = debts;
        _calculateDebtFreePlan();
        _setLoading(false);
        notifyListeners();
      }, onError: (e) {
        _setError('Error loading debts: $e');
        _setLoading(false);
      });
    } catch (e) {
      _setError('Error setting up debt stream: $e');
      _setLoading(false);
    }
  }

  Future<void> addDebt(Debt debt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _debtService.addDebt(debt.copyWith(userId: user.uid));
    } catch (e) {
      _setError('Error adding debt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDebt(Debt debt) async {
    _setLoading(true);
    try {
      await _debtService.updateDebt(debt);
    } catch (e) {
      _setError('Error updating debt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteDebt(String debtId) async {
    _setLoading(true);
    try {
      await _debtService.deleteDebt(debtId);
    } catch (e) {
      _setError('Error deleting debt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addRepayment(String debtId, double amount) async {
    _setLoading(true);
    try {
      await _debtService.addRepayment(debtId, amount);
    } catch (e) {
      _setError('Error adding repayment: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setPayoffStrategy(DebtPayoffStrategy strategy) {
    _selectedStrategy = strategy;
    _calculateDebtFreePlan();
    notifyListeners();
  }

  void _calculateDebtFreePlan() {
    if (_debts.isEmpty) {
      _debtFreeCalculation = null;
      return;
    }
    // This is a placeholder for a more complex calculation
    _debtFreeCalculation = {
      'months': 12,
      'finalPayoffDate': DateTime.now().add(const Duration(days: 365)),
      'totalInterestPaid': 1234.56,
    };
  }

  List<Debt> _getSortedDebts() {
    List<Debt> sortedDebts = List.from(_debts);
    switch (_selectedStrategy) {
      case DebtPayoffStrategy.snowball:
        sortedDebts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
        break;
      case DebtPayoffStrategy.avalanche:
        sortedDebts.sort((a, b) => (b.interestRate ?? 0).compareTo(a.interestRate ?? 0));
        break;
      case DebtPayoffStrategy.custom:
        sortedDebts.sort((a, b) => (a.priority ?? 99).compareTo(b.priority ?? 99));
        break;
    }
    return sortedDebts;
  }
  
  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _debtService.clearAllDebts(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final debts = data.map((d) => Debt.fromJson(d as Map<String, dynamic>)).toList();
    await _debtService.restoreDebts(user.uid, debts);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
