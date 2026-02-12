import 'package:intl/intl.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/models/investment.dart';

/// Context Builder Service
/// Builds rich financial context for the AI based on query and available data

class FinancialContext {
  final String summary;
  final Map<String, dynamic> data;

  FinancialContext({required this.summary, required this.data});
}

class ContextBuilderService {
  final AccountProvider accountProvider;
  final DebtProvider debtProvider;
  final InvestmentProvider investmentProvider;
  final SubscriptionProvider subscriptionProvider;
  final TransactionProvider transactionProvider;
  final BudgetProvider? budgetProvider;
  final GoalProvider? goalProvider;
  final BikeProvider? bikeProvider;

  ContextBuilderService({
    required this.accountProvider,
    required this.debtProvider,
    required this.investmentProvider,
    required this.subscriptionProvider,
    required this.transactionProvider,
    this.budgetProvider,
    this.goalProvider,
    this.bikeProvider,
  });

  final _currencyFormat = NumberFormat('#,##,###', 'en_IN');
  final _dateFormat = DateFormat('MMM d');

  /// Build full context for the AI
  String buildFullContext({String? userQuery}) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('=== NEXUS FINANCIAL SNAPSHOT ===');
    buffer.writeln('Date: ${DateFormat('EEEE, MMMM d, yyyy').format(now)}');
    buffer.writeln('Time: ${DateFormat('h:mm a').format(now)}');
    buffer.writeln();

    // 1. WEALTH OVERVIEW
    buffer.writeln(_buildWealthOverview());

    // 2. ACCOUNTS
    buffer.writeln(_buildAccountsSummary());

    // 3. DEBTS & EMIs
    buffer.writeln(_buildDebtsSummary());

    // 4. INVESTMENTS
    buffer.writeln(_buildInvestmentsSummary());

    // 5. SUBSCRIPTIONS
    buffer.writeln(_buildSubscriptionsSummary());

    // 6. RECENT TRANSACTIONS (Spending Patterns)
    buffer.writeln(_buildTransactionsSummary());

    // 7. BUDGETS (if available)
    if (budgetProvider != null) {
      buffer.writeln(_buildBudgetsSummary());
    }

    // 8. GOALS (if available)
    if (goalProvider != null) {
      buffer.writeln(_buildGoalsSummary());
    }

    // 9. BIKE/VEHICLE (if available)
    if (bikeProvider != null) {
      buffer.writeln(_buildBikeSummary());
    }

    // 10. UPCOMING ALERTS
    buffer.writeln(_buildUpcomingAlerts());

    return buffer.toString();
  }

  /// Build smart context based on query keywords
  String buildSmartContext(String query) {
    final lowerQuery = query.toLowerCase();
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('Date: ${DateFormat('EEEE, MMMM d, yyyy').format(now)}');
    buffer.writeln();

    // Always include wealth overview (it's compact)
    buffer.writeln(_buildWealthOverview());

    // Query-specific context
    if (_matchesAny(lowerQuery, [
      'spend',
      'spent',
      'expense',
      'transaction',
      'buy',
      'bought',
      'purchase',
      'afford',
      'money',
    ])) {
      buffer.writeln(_buildTransactionsSummary());
      buffer.writeln(_buildAccountsSummary());
    }

    if (_matchesAny(lowerQuery, [
      'debt',
      'loan',
      'emi',
      'pay off',
      'payoff',
      'borrow',
      'credit',
      'prepay',
    ])) {
      buffer.writeln(_buildDebtsSummary());
    }

    if (_matchesAny(lowerQuery, [
      'invest',
      'stock',
      'mutual fund',
      'portfolio',
      'return',
      'sip',
    ])) {
      buffer.writeln(_buildInvestmentsSummary());
    }

    if (_matchesAny(lowerQuery, [
      'subscription',
      'subscribe',
      'netflix',
      'spotify',
      'recurring',
    ])) {
      buffer.writeln(_buildSubscriptionsSummary());
    }

    if (_matchesAny(lowerQuery, ['budget', 'limit', 'overspend'])) {
      buffer.writeln(_buildBudgetsSummary());
    }

    if (_matchesAny(lowerQuery, ['goal', 'save', 'saving', 'target'])) {
      buffer.writeln(_buildGoalsSummary());
    }

    if (_matchesAny(lowerQuery, [
      'bike',
      'vehicle',
      'fuel',
      'petrol',
      'service',
      'mileage',
      'km',
    ])) {
      buffer.writeln(_buildBikeSummary());
    }

    if (_matchesAny(lowerQuery, [
      'due',
      'upcoming',
      'remind',
      'alert',
      'expire',
      'expiry',
    ])) {
      buffer.writeln(_buildUpcomingAlerts());
    }

    // If no specific match, include accounts and transactions
    if (buffer.length < 500) {
      buffer.writeln(_buildAccountsSummary());
      buffer.writeln(_buildTransactionsSummary());
    }

    return buffer.toString();
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _buildWealthOverview() {
    final totalCash = accountProvider.accounts.fold(
      0.0,
      (sum, a) => sum + a.balance,
    );
    final totalInvestments = investmentProvider.investments.fold(
      0.0,
      (sum, i) => sum + i.currentAmount,
    );
    final activeDebts = debtProvider.debts
        .where((d) => d.currentBalance > 1.0)
        .toList();
    final totalLiabilities = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.currentBalance,
    );
    final netWorth = (totalCash + totalInvestments) - totalLiabilities;

    // Monthly burn rate
    final activeSubs = subscriptionProvider.subscriptions
        .where((s) => s.isActive)
        .toList();
    final subCost = activeSubs.fold(0.0, (sum, s) {
      if (s.frequency == 'monthly') return sum + s.amount;
      if (s.frequency == 'yearly') return sum + (s.amount / 12);
      return sum + s.amount;
    });
    final debtEMI = activeDebts.fold(
      0.0,
      (sum, d) => sum + (d.monthlyEMI ?? 0),
    );
    final monthlyBurn = subCost + debtEMI;

    return '''
--- WEALTH OVERVIEW ---
Net Worth: ₹${_currencyFormat.format(netWorth)}
  • Liquid Cash: ₹${_currencyFormat.format(totalCash)}
  • Investments: ₹${_currencyFormat.format(totalInvestments)}
  • Liabilities: ₹${_currencyFormat.format(totalLiabilities)}

Monthly Fixed Burn: ₹${_currencyFormat.format(monthlyBurn)}
  • Subscriptions: ₹${_currencyFormat.format(subCost)}
  • EMIs: ₹${_currencyFormat.format(debtEMI)}
''';
  }

  String _buildAccountsSummary() {
    final accounts = accountProvider.accounts;
    if (accounts.isEmpty) return '--- ACCOUNTS ---\nNo accounts configured.\n';

    final buffer = StringBuffer('--- ACCOUNTS ---\n');
    for (final acc in accounts) {
      buffer.writeln(
        '• ${acc.name} (${acc.type}): ₹${_currencyFormat.format(acc.balance)}',
      );
    }
    buffer.writeln();
    return buffer.toString();
  }

  String _buildDebtsSummary() {
    final activeDebts = debtProvider.debts
        .where((d) => d.currentBalance > 1.0)
        .toList();
    if (activeDebts.isEmpty)
      return '--- DEBTS ---\nNo active debts. Debt-free! 🎉\n';

    final buffer = StringBuffer(
      '--- DEBTS (${activeDebts.length} active) ---\n',
    );
    for (final debt in activeDebts) {
      final nextPayment = debt.nextPaymentDate;
      final daysUntilPayment = nextPayment != null
          ? nextPayment.difference(DateTime.now()).inDays
          : null;

      buffer.writeln('• ${debt.name}');
      buffer.writeln(
        '  Balance: ₹${_currencyFormat.format(debt.currentBalance)} of ₹${_currencyFormat.format(debt.originalAmount)}',
      );
      buffer.writeln(
        '  EMI: ₹${_currencyFormat.format(debt.monthlyEMI ?? 0)} @ ${debt.interestRate ?? 0}% p.a.',
      );
      if (daysUntilPayment != null) {
        buffer.writeln(
          '  Next Payment: ${_dateFormat.format(nextPayment!)} ($daysUntilPayment days)',
        );
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _buildInvestmentsSummary() {
    final investments = investmentProvider.investments;
    if (investments.isEmpty)
      return '--- INVESTMENTS ---\nNo investments tracked.\n';

    final totalInvested = investments.fold(
      0.0,
      (sum, i) => sum + i.investedAmount,
    );
    final currentValue = investments.fold(
      0.0,
      (sum, i) => sum + i.currentAmount,
    );
    final totalReturns = currentValue - totalInvested;
    final returnPercent = totalInvested > 0
        ? (totalReturns / totalInvested * 100)
        : 0;

    final buffer = StringBuffer('--- INVESTMENTS ---\n');
    buffer.writeln('Total Value: ₹${_currencyFormat.format(currentValue)}');
    buffer.writeln(
      'Returns: ₹${_currencyFormat.format(totalReturns)} (${returnPercent.toStringAsFixed(1)}%)',
    );
    buffer.writeln();

    // Group by type
    final byType = <InvestmentType, double>{};
    for (final inv in investments) {
      byType[inv.type] = (byType[inv.type] ?? 0) + inv.currentAmount;
    }
    for (final entry in byType.entries) {
      buffer.writeln(
        '• ${entry.key.name}: ₹${_currencyFormat.format(entry.value)}',
      );
    }
    buffer.writeln();
    return buffer.toString();
  }

  String _buildSubscriptionsSummary() {
    final activeSubs = subscriptionProvider.subscriptions
        .where((s) => s.isActive)
        .toList();
    if (activeSubs.isEmpty)
      return '--- SUBSCRIPTIONS ---\nNo active subscriptions.\n';

    final buffer = StringBuffer(
      '--- SUBSCRIPTIONS (${activeSubs.length} active) ---\n',
    );
    double monthlyTotal = 0;

    for (final sub in activeSubs) {
      final monthly = sub.frequency == 'yearly' ? sub.amount / 12 : sub.amount;
      monthlyTotal += monthly;
      buffer.writeln(
        '• ${sub.name}: ₹${_currencyFormat.format(sub.amount)}/${sub.frequency}',
      );
    }
    buffer.writeln('Monthly Total: ₹${_currencyFormat.format(monthlyTotal)}');
    buffer.writeln();
    return buffer.toString();
  }

  String _buildTransactionsSummary() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final allTxns = transactionProvider.transactions;
    final last30Days = allTxns
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();
    final last7Days = allTxns
        .where((t) => t.date.isAfter(sevenDaysAgo))
        .toList();

    if (last30Days.isEmpty)
      return '--- SPENDING ---\nNo transactions in last 30 days.\n';

    // Calculate spending by category (last 30 days)
    final expensesByCategory = <String, double>{};
    double totalExpenses = 0;
    double totalIncome = 0;

    for (final txn in last30Days) {
      if (txn.type.name == 'expense') {
        final category = txn.categoryId ?? 'Uncategorized';
        expensesByCategory[category] =
            (expensesByCategory[category] ?? 0) + txn.amount;
        totalExpenses += txn.amount;
      } else if (txn.type.name == 'income') {
        totalIncome += txn.amount;
      }
    }

    // Sort categories by amount
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer('--- SPENDING (Last 30 Days) ---\n');
    buffer.writeln('Total Expenses: ₹${_currencyFormat.format(totalExpenses)}');
    buffer.writeln('Total Income: ₹${_currencyFormat.format(totalIncome)}');
    buffer.writeln(
      'Net: ₹${_currencyFormat.format(totalIncome - totalExpenses)}',
    );
    buffer.writeln();
    buffer.writeln('By Category:');
    for (final entry in sortedCategories.take(8)) {
      final percent = totalExpenses > 0
          ? (entry.value / totalExpenses * 100).toStringAsFixed(0)
          : '0';
      buffer.writeln(
        '• ${entry.key}: ₹${_currencyFormat.format(entry.value)} ($percent%)',
      );
    }

    // Last 7 days
    final last7Expenses = last7Days
        .where((t) => t.type.name == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    buffer.writeln();
    buffer.writeln('Last 7 Days: ₹${_currencyFormat.format(last7Expenses)}');
    buffer.writeln();

    return buffer.toString();
  }

  String _buildBudgetsSummary() {
    if (budgetProvider == null) return '';
    final budgets = budgetProvider!.budgets;
    if (budgets.isEmpty) return '--- BUDGETS ---\nNo budgets set.\n';

    final buffer = StringBuffer('--- BUDGETS ---\n');
    for (final budget in budgets) {
      final percent = budget.allocatedAmount > 0
          ? (budget.spentAmount / budget.allocatedAmount * 100)
          : 0;
      final status = percent > 100 ? '🔴 OVER' : (percent > 80 ? '🟡' : '🟢');
      buffer.writeln(
        '• ${budget.categoryName}: ₹${_currencyFormat.format(budget.spentAmount)} / ₹${_currencyFormat.format(budget.allocatedAmount)} $status',
      );
    }
    buffer.writeln();
    return buffer.toString();
  }

  String _buildGoalsSummary() {
    if (goalProvider == null) return '';
    final goals = goalProvider!.goals;
    if (goals.isEmpty) return '--- GOALS ---\nNo savings goals set.\n';

    final buffer = StringBuffer('--- GOALS ---\n');
    for (final goal in goals) {
      final percent = goal.targetAmount > 0
          ? (goal.currentAmount / goal.targetAmount * 100)
          : 0;
      buffer.writeln(
        '• ${goal.name}: ₹${_currencyFormat.format(goal.currentAmount)} / ₹${_currencyFormat.format(goal.targetAmount)} (${percent.toStringAsFixed(0)}%)',
      );
      final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
      buffer.writeln(
        '  Target: ${_dateFormat.format(goal.targetDate)} ($daysLeft days left)',
      );
    }
    buffer.writeln();
    return buffer.toString();
  }

  String _buildBikeSummary() {
    if (bikeProvider == null) return '';

    final buffer = StringBuffer('--- VEHICLE ---\n');

    // Get current bike entries (fuel logs)
    final entries = bikeProvider!.currentBikeEntries;
    final fuelLogs = entries
        .where((e) => e.category == 'Fuel')
        .take(5)
        .toList();

    if (fuelLogs.isNotEmpty) {
      buffer.writeln('Recent Fuel:');
      for (final log in fuelLogs) {
        final pricePerLiter = log.fuelQuantity > 0
            ? log.fuelAmount / log.fuelQuantity
            : 0;
        buffer.writeln(
          '• ${_dateFormat.format(log.date)}: ${log.fuelQuantity}L @ ₹${pricePerLiter.toStringAsFixed(1)}/L = ₹${_currencyFormat.format(log.fuelAmount)}',
        );
      }

      // Get average mileage
      final avgMileage = bikeProvider!.getReliableAverageMileage();
      if (avgMileage > 0) {
        buffer.writeln(
          'Average Mileage: ${avgMileage.toStringAsFixed(1)} km/L',
        );
      }
    }

    // Service entries
    final serviceEntries = entries
        .where((e) => e.category == 'Service')
        .take(3)
        .toList();
    if (serviceEntries.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Recent Service:');
      for (final service in serviceEntries) {
        buffer.writeln(
          '• ${_dateFormat.format(service.date)}: ${service.notes ?? 'Service'} - ₹${_currencyFormat.format(service.fuelAmount)}',
        );
      }
    }

    // Selected bike info
    final selectedBike = bikeProvider!.selectedBike;
    if (selectedBike != null) {
      buffer.writeln();
      buffer.writeln('Vehicle: ${selectedBike.name}');
    }

    buffer.writeln();
    return buffer.toString();
  }

  String _buildUpcomingAlerts() {
    final buffer = StringBuffer('--- UPCOMING ALERTS ---\n');
    final now = DateTime.now();
    final alerts = <String>[];

    // EMI dates
    for (final debt in debtProvider.debts.where(
      (d) => d.currentBalance > 1.0,
    )) {
      if (debt.nextPaymentDate != null) {
        final days = debt.nextPaymentDate!.difference(now).inDays;
        if (days >= 0 && days <= 7) {
          alerts.add(
            '⚠️ ${debt.name} EMI (₹${_currencyFormat.format(debt.monthlyEMI ?? 0)}) due in $days days',
          );
        }
      }
    }

    // Subscription renewals
    for (final sub in subscriptionProvider.subscriptions.where(
      (s) => s.isActive,
    )) {
      final days = sub.nextDueDate.difference(now).inDays;
      if (days >= 0 && days <= 7) {
        alerts.add(
          '🔄 ${sub.name} renews in $days days (₹${_currencyFormat.format(sub.amount)})',
        );
      }
    }

    // Goal deadlines approaching
    if (goalProvider != null) {
      for (final goal in goalProvider!.goals.where((g) => !g.isCompleted)) {
        final days = goal.targetDate.difference(now).inDays;
        if (days >= 0 && days <= 30) {
          final progress = goal.targetAmount > 0
              ? (goal.currentAmount / goal.targetAmount * 100).toStringAsFixed(
                  0,
                )
              : '0';
          alerts.add(
            '🎯 ${goal.name} deadline in $days days ($progress% complete)',
          );
        }
      }
    }

    if (alerts.isEmpty) {
      buffer.writeln('No urgent alerts. All clear! ✅');
    } else {
      for (final alert in alerts) {
        buffer.writeln(alert);
      }
    }
    buffer.writeln();
    return buffer.toString();
  }
}
