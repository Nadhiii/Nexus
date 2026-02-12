import 'package:flutter/material.dart';
import '../models/financial_health.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/account.dart';

/// Provider for calculating and tracking financial health score
class FinancialHealthProvider with ChangeNotifier {
  FinancialHealthScore? _healthScore;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastCalculated;

  // Data snapshots for calculation
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Debt> _debts = [];
  List<Account> _accounts = [];

  FinancialHealthScore? get healthScore => _healthScore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastCalculated => _lastCalculated;

  /// Update with latest data from other providers
  void updateData({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Debt> debts,
    required List<Account> accounts,
  }) {
    _transactions = transactions;
    _budgets = budgets;
    _debts = debts;
    _accounts = accounts;

    // Auto-recalculate when data changes
    calculateScore();
  }

  /// Calculate the financial health score
  void calculateScore() {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get this month's transactions
      final monthlyTransactions = _transactions
          .where(
            (t) =>
                t.date.isAfter(
                  startOfMonth.subtract(const Duration(days: 1)),
                ) &&
                t.date.isBefore(endOfMonth.add(const Duration(days: 1))),
          )
          .toList();

      // Calculate monthly income
      final monthlyIncome = monthlyTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Calculate monthly expenses
      final monthlyExpenses = monthlyTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      // 1. Savings Rate
      double savingsRate = 0;
      if (monthlyIncome > 0) {
        final saved = monthlyIncome - monthlyExpenses;
        savingsRate = (saved / monthlyIncome) * 100;
        savingsRate = savingsRate.clamp(-100, 100);
      }

      // 2. Debt to Income Ratio
      double debtToIncomeRatio = 0;
      if (monthlyIncome > 0) {
        // Calculate monthly debt payments (EMI, etc.)
        final monthlyDebtPayments = _debts
            .where(
              (d) => d.type != DebtType.owedToMe && (d.monthlyEMI ?? 0) > 0,
            )
            .fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));

        debtToIncomeRatio = (monthlyDebtPayments / monthlyIncome) * 100;
      }

      // 3. Budget Adherence
      double budgetAdherence = 100; // Default to 100% if no budgets
      if (_budgets.isNotEmpty) {
        // Calculate percentage of budgets that are on track
        int onTrackBudgets = 0;
        for (final budget in _budgets) {
          // Consider a budget "on track" if spent <= 90% of allocated
          if (budget.spentAmount <= budget.allocatedAmount * 0.9) {
            onTrackBudgets++;
          }
        }
        budgetAdherence = (onTrackBudgets / _budgets.length) * 100;
      }

      // 4. Emergency Fund (months of expenses covered)
      double emergencyFundMonths = 0;
      if (monthlyExpenses > 0) {
        // Consider savings accounts as emergency fund
        final savingsBalance = _accounts
            .where(
              (a) =>
                  a.type == AccountType.savings ||
                  a.name.toLowerCase().contains('emergency') ||
                  a.name.toLowerCase().contains('saving'),
            )
            .fold(0.0, (sum, a) => sum + a.balance);

        emergencyFundMonths = savingsBalance / monthlyExpenses;
        emergencyFundMonths = emergencyFundMonths.clamp(
          0,
          12,
        ); // Cap at 12 months
      }

      // 5. Active Debts
      final activeDebts = _debts
          .where((d) => d.type != DebtType.owedToMe && d.currentBalance > 0)
          .length;

      // 6. Overdue Payments
      final overduePayments = _debts
          .where(
            (d) =>
                d.type != DebtType.owedToMe &&
                d.nextPaymentDate != null &&
                d.nextPaymentDate!.isBefore(now) &&
                d.currentBalance > 0,
          )
          .length;

      _healthScore = FinancialHealthScore(
        savingsRate: savingsRate,
        debtToIncomeRatio: debtToIncomeRatio,
        budgetAdherence: budgetAdherence,
        emergencyFundMonths: emergencyFundMonths,
        activeDebts: activeDebts,
        overduePayments: overduePayments,
      );

      _lastCalculated = now;
      _error = null;
    } catch (e) {
      _error = 'Failed to calculate health score: $e';
      _healthScore = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get historical scores (for trend display)
  List<Map<String, dynamic>> getScoreHistory({int months = 6}) {
    // This would ideally fetch from Firestore if we store historical scores
    // For now, return empty list - can be enhanced later
    return [];
  }

  /// Save current score to Firestore for historical tracking
  Future<void> saveScoreToHistory() async {
    if (_healthScore == null) return;

    // TODO: Implement Firestore storage for historical tracking
    // This would allow showing score trends over time
  }

  void reset() {
    _healthScore = null;
    _transactions = [];
    _budgets = [];
    _debts = [];
    _accounts = [];
    _isLoading = false;
    _error = null;
    _lastCalculated = null;
    notifyListeners();
  }
}
