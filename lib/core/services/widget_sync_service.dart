import 'dart:async';
import '../theme/app_animations.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/debt_provider.dart';
import 'home_screen_widget_service.dart';

/// Service that syncs financial data to Android home screen widgets.
/// Listens to providers and updates widgets automatically.
class WidgetSyncService {
  static WidgetSyncService? _instance;
  static WidgetSyncService get instance => _instance ??= WidgetSyncService._();

  WidgetSyncService._();

  TransactionProvider? _transactionProvider;
  AccountProvider? _accountProvider;
  SubscriptionProvider? _subscriptionProvider;
  DebtProvider? _debtProvider;

  Timer? _debounceTimer;
  bool _isInitialized = false;

  /// Initialize with providers
  void initialize({
    required TransactionProvider transactionProvider,
    required AccountProvider accountProvider,
    SubscriptionProvider? subscriptionProvider,
    DebtProvider? debtProvider,
  }) {
    _transactionProvider = transactionProvider;
    _accountProvider = accountProvider;
    _subscriptionProvider = subscriptionProvider;
    _debtProvider = debtProvider;

    // Listen for changes
    _transactionProvider?.addListener(_onTransactionChanged);
    _accountProvider?.addListener(_onAccountChanged);
    _subscriptionProvider?.addListener(_onFinancialDataChanged);
    _debtProvider?.addListener(_onFinancialDataChanged);

    _isInitialized = true;

    // Initial sync
    syncAllWidgets();
  }

  /// Dispose listeners
  void dispose() {
    _transactionProvider?.removeListener(_onTransactionChanged);
    _accountProvider?.removeListener(_onAccountChanged);
    _subscriptionProvider?.removeListener(_onFinancialDataChanged);
    _debtProvider?.removeListener(_onFinancialDataChanged);
    _debounceTimer?.cancel();
  }

  void _onTransactionChanged() {
    _debouncedSync(() {
      syncQuickTransactionWidget();
      syncBalanceWidget();
    });
  }

  void _onAccountChanged() {
    _debouncedSync(() {
      syncBalanceWidget();
    });
  }

  void _onFinancialDataChanged() {
    _debouncedSync(() {
      syncBalanceWidget();
    });
  }

  /// Debounce rapid updates
  void _debouncedSync(VoidCallback callback) {
    _debounceTimer?.cancel();
    debugPrint('⏱️  Widget sync debounced (500ms)');
    _debounceTimer = Timer(AppAnimations.verySlow, () {
      debugPrint('🚀 Executing debounced widget sync');
      callback();
    });
  }

  /// Sync all widgets at once
  Future<void> syncAllWidgets() async {
    if (!_isInitialized) return;

    await Future.wait([syncQuickTransactionWidget(), syncBalanceWidget()]);
  }

  /// Sync Quick Transaction widget with spending data
  Future<void> syncQuickTransactionWidget() async {
    if (_transactionProvider == null) return;

    try {
      final transactions = _transactionProvider!.transactions;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      // Calculate today's spending
      double todaySpent = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.expense &&
            t.date.isAfter(todayStart.subtract(const Duration(seconds: 1)))) {
          todaySpent += t.amount;
        }
      }

      // Calculate this week's spending
      double weekSpent = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.expense &&
            t.date.isAfter(weekStart.subtract(const Duration(seconds: 1)))) {
          weekSpent += t.amount;
        }
      }

      // Get last expense transaction
      String lastTransaction = 'No transactions';
      double lastAmount = 0;
      final expenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
      if (expenses.isNotEmpty) {
        final last = expenses.first;
        lastTransaction = last.description ?? last.categoryId ?? 'Expense';
        lastAmount = last.amount;
      }

      // Find top spending category this month
      final monthStart = DateTime(now.year, now.month, 1);
      final Map<String, double> categorySpending = {};
      for (final t in transactions) {
        if (t.type == TransactionType.expense &&
            t.date.isAfter(monthStart.subtract(const Duration(seconds: 1)))) {
          final category = t.categoryId ?? 'Other';
          categorySpending[category] =
              (categorySpending[category] ?? 0) + t.amount;
        }
      }

      String topCategory = 'None';
      if (categorySpending.isNotEmpty) {
        final sorted = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topCategory = sorted.first.key;
      }

      await HomeScreenWidgetService.updateQuickTransactionWidget(
        todaySpent: todaySpent,
        weekSpent: weekSpent,
        lastTransaction: lastTransaction,
        lastAmount: lastAmount,
        topCategory: topCategory,
      );

      debugPrint('📱 Quick Transaction widget synced');
    } catch (e) {
      debugPrint('❌ Error syncing quick transaction widget: $e');
    }
  }

  /// Sync Balance Overview widget with financial summary
  Future<void> syncBalanceWidget() async {
    if (_accountProvider == null || _transactionProvider == null) return;

    try {
      // Total balance from all accounts
      double totalBalance = 0;
      for (final account in _accountProvider!.accounts) {
        totalBalance += account.balance;
      }

      final transactions = _transactionProvider!.transactions;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // This month's income
      double monthIncome = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.income &&
            t.date.isAfter(monthStart.subtract(const Duration(seconds: 1)))) {
          monthIncome += t.amount;
        }
      }

      // This month's expenses
      double monthExpense = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.expense &&
            t.date.isAfter(monthStart.subtract(const Duration(seconds: 1)))) {
          monthExpense += t.amount;
        }
      }

      // Savings rate
      double savingsRate = 0;
      if (monthIncome > 0) {
        savingsRate = ((monthIncome - monthExpense) / monthIncome) * 100;
        if (savingsRate < 0) savingsRate = 0;
      }

      // Count pending bills (EMIs + subscriptions due this week)
      int pendingBills = 0;

      // Count subscriptions due in next 7 days
      if (_subscriptionProvider != null) {
        final weekFromNow = now.add(const Duration(days: 7));
        for (final sub in _subscriptionProvider!.subscriptions) {
          if (sub.isActive) {
            if (sub.nextDueDate.isAfter(now) &&
                sub.nextDueDate.isBefore(weekFromNow)) {
              pendingBills++;
            }
          }
        }
      }

      // Count EMIs due in next 7 days
      if (_debtProvider != null) {
        final weekFromNow = now.add(const Duration(days: 7));
        for (final debt in _debtProvider!.debts) {
          if (debt.nextPaymentDate != null) {
            if (debt.nextPaymentDate!.isAfter(now) &&
                debt.nextPaymentDate!.isBefore(weekFromNow)) {
              pendingBills++;
            }
          }
        }
      }

      await HomeScreenWidgetService.updateBalanceWidget(
        totalBalance: totalBalance,
        monthIncome: monthIncome,
        monthExpense: monthExpense,
        savingsRate: savingsRate,
        pendingBills: pendingBills,
      );

      debugPrint('📱 Balance widget synced');
    } catch (e) {
      debugPrint('❌ Error syncing balance widget: $e');
    }
  }
}
