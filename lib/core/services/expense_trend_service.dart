import 'dart:math' as math;
import '../models/transaction.dart';

/// Service for analyzing expense trends and forecasting future spending
class ExpenseTrendService {
  /// Get spending by category for a date range
  Map<String, double> getSpendingByCategory(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filtered = _filterByDateRange(
      transactions,
      startDate,
      endDate,
    ).where((t) => t.type == TransactionType.expense);

    final categoryTotals = <String, double>{};
    for (final t in filtered) {
      final category = t.categoryId ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + t.amount;
    }

    return categoryTotals;
  }

  /// Get daily spending for a date range
  Map<DateTime, double> getDailySpending(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filtered = _filterByDateRange(
      transactions,
      startDate,
      endDate,
    ).where((t) => t.type == TransactionType.expense);

    final dailyTotals = <DateTime, double>{};
    for (final t in filtered) {
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + t.amount;
    }

    return dailyTotals;
  }

  /// Get monthly spending for the past N months
  List<MonthlySpending> getMonthlySpending(
    List<Transaction> transactions, {
    int months = 12,
  }) {
    final now = DateTime.now();
    final results = <MonthlySpending>[];

    for (int i = months - 1; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);

      final monthExpenses = transactions.where(
        (t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(targetMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(nextMonth),
      );

      final monthIncome = transactions.where(
        (t) =>
            t.type == TransactionType.income &&
            t.date.isAfter(targetMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(nextMonth),
      );

      results.add(
        MonthlySpending(
          month: targetMonth,
          totalExpenses: monthExpenses.fold(0.0, (sum, t) => sum + t.amount),
          totalIncome: monthIncome.fold(0.0, (sum, t) => sum + t.amount),
          transactionCount: monthExpenses.length,
        ),
      );
    }

    return results;
  }

  /// Get category trends (comparing current month to previous months)
  List<CategoryTrend> getCategoryTrends(
    List<Transaction> transactions, {
    int compareMonths = 3,
  }) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final prevPeriodStart = DateTime(now.year, now.month - compareMonths, 1);

    // Current month spending by category
    final currentSpending = getSpendingByCategory(
      transactions,
      startDate: thisMonthStart,
    );

    // Average spending from previous months
    final prevSpending = getSpendingByCategory(
      transactions,
      startDate: prevPeriodStart,
      endDate: thisMonthStart.subtract(const Duration(days: 1)),
    );

    // Calculate averages for previous months
    final prevAverages = prevSpending.map(
      (key, value) => MapEntry(key, value / compareMonths),
    );

    // Build trends
    final allCategories = {...currentSpending.keys, ...prevAverages.keys};
    return allCategories.map((category) {
      final current = currentSpending[category] ?? 0;
      final average = prevAverages[category] ?? 0;

      double percentChange = 0;
      if (average > 0) {
        percentChange = ((current - average) / average) * 100;
      } else if (current > 0) {
        percentChange = 100; // New category
      }

      return CategoryTrend(
        category: category,
        currentAmount: current,
        averageAmount: average,
        percentChange: percentChange,
      );
    }).toList()..sort((a, b) => b.currentAmount.compareTo(a.currentAmount));
  }

  /// Forecast next month's spending using simple moving average
  SpendingForecast forecastNextMonth(List<Transaction> transactions) {
    final monthlyData = getMonthlySpending(transactions, months: 6);

    if (monthlyData.length < 2) {
      return SpendingForecast(
        predictedExpenses: 0,
        predictedIncome: 0,
        confidence: 0,
        basedOnMonths: monthlyData.length,
        method: 'Insufficient data',
      );
    }

    // Use weighted moving average (more recent months have higher weight)
    double totalExpenseWeight = 0;
    double totalIncomeWeight = 0;
    double weightSum = 0;

    for (int i = 0; i < monthlyData.length; i++) {
      final weight = (i + 1).toDouble(); // More recent = higher weight
      totalExpenseWeight += monthlyData[i].totalExpenses * weight;
      totalIncomeWeight += monthlyData[i].totalIncome * weight;
      weightSum += weight;
    }

    final predictedExpenses = totalExpenseWeight / weightSum;
    final predictedIncome = totalIncomeWeight / weightSum;

    // Calculate confidence based on variance
    final expenseVariance = _calculateVariance(
      monthlyData.map((m) => m.totalExpenses).toList(),
    );
    final meanExpense =
        monthlyData.fold(0.0, (sum, m) => sum + m.totalExpenses) /
        monthlyData.length;

    // Lower variance = higher confidence (normalized to 0-100%)
    double confidence = 50;
    if (meanExpense > 0) {
      final cv =
          math.sqrt(expenseVariance) / meanExpense; // Coefficient of variation
      confidence = (100 - (cv * 100)).clamp(20, 95);
    }

    return SpendingForecast(
      predictedExpenses: predictedExpenses,
      predictedIncome: predictedIncome,
      confidence: confidence,
      basedOnMonths: monthlyData.length,
      method: 'Weighted Moving Average',
    );
  }

  /// Get spending velocity (rate of change)
  SpendingVelocity getSpendingVelocity(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final daysPassed = now.day;

    // Current month spending
    final currentMonthExpenses = transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    // Daily rate this month
    final dailyRate = daysPassed > 0 ? currentMonthExpenses / daysPassed : 0.0;

    // Projected month-end
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projected = dailyRate * daysInMonth;

    // Compare to last month's total
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthExpenses = transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.isAfter(
                lastMonthStart.subtract(const Duration(days: 1)),
              ) &&
              t.date.isBefore(thisMonthStart),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    // Determine if on track
    String status;
    if (lastMonthExpenses == 0) {
      status = 'No historical data';
    } else if (projected <= lastMonthExpenses * 0.9) {
      status = 'Under budget';
    } else if (projected <= lastMonthExpenses * 1.1) {
      status = 'On track';
    } else {
      status = 'Over budget';
    }

    return SpendingVelocity(
      currentMonthSpent: currentMonthExpenses,
      dailyRate: dailyRate,
      projectedMonthEnd: projected,
      lastMonthTotal: lastMonthExpenses,
      status: status,
      daysRemaining: daysInMonth - daysPassed,
    );
  }

  /// Detect unusual spending patterns
  List<SpendingAnomaly> detectAnomalies(List<Transaction> transactions) {
    final anomalies = <SpendingAnomaly>[];
    final now = DateTime.now();

    // Check for unusually large transactions (>2 std dev from mean)
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) { return anomalies; }

    final amounts = expenses.map((t) => t.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final stdDev = math.sqrt(_calculateVariance(amounts));

    for (final t in expenses) {
      if (t.amount > mean + (2 * stdDev) &&
          t.date.isAfter(now.subtract(const Duration(days: 30)))) {
        anomalies.add(
          SpendingAnomaly(
            type: AnomalyType.unusuallyLarge,
            amount: t.amount,
            date: t.date,
            description: t.description ?? 'Large expense',
            category: t.categoryId,
            deviation: (t.amount - mean) / stdDev,
          ),
        );
      }
    }

    // Check for spending spike in a category
    final categoryTrends = getCategoryTrends(transactions);
    for (final trend in categoryTrends) {
      if (trend.percentChange > 50 && trend.currentAmount > 1000) {
        anomalies.add(
          SpendingAnomaly(
            type: AnomalyType.categorySpike,
            amount: trend.currentAmount,
            date: now,
            description:
                '${trend.category} spending up ${trend.percentChange.toStringAsFixed(0)}%',
            category: trend.category,
            deviation: trend.percentChange / 50,
          ),
        );
      }
    }

    return anomalies..sort((a, b) => b.deviation.compareTo(a.deviation));
  }

  // Helper methods
  Iterable<Transaction> _filterByDateRange(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return transactions.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) { return false; }
      if (endDate != null && t.date.isAfter(endDate)) { return false; }
      return true;
    });
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) { return 0; }
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
  }
}

/// Monthly spending summary
class MonthlySpending {
  final DateTime month;
  final double totalExpenses;
  final double totalIncome;
  final int transactionCount;

  MonthlySpending({
    required this.month,
    required this.totalExpenses,
    required this.totalIncome,
    required this.transactionCount,
  });

  double get netSavings => totalIncome - totalExpenses;
  double get savingsRate =>
      totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;
}

/// Category spending trend
class CategoryTrend {
  final String category;
  final double currentAmount;
  final double averageAmount;
  final double percentChange;

  CategoryTrend({
    required this.category,
    required this.currentAmount,
    required this.averageAmount,
    required this.percentChange,
  });

  bool get isIncreasing => percentChange > 10;
  bool get isDecreasing => percentChange < -10;
  bool get isStable => !isIncreasing && !isDecreasing;
}

/// Spending forecast
class SpendingForecast {
  final double predictedExpenses;
  final double predictedIncome;
  final double confidence; // 0-100%
  final int basedOnMonths;
  final String method;

  SpendingForecast({
    required this.predictedExpenses,
    required this.predictedIncome,
    required this.confidence,
    required this.basedOnMonths,
    required this.method,
  });

  double get predictedSavings => predictedIncome - predictedExpenses;
}

/// Current spending velocity
class SpendingVelocity {
  final double currentMonthSpent;
  final double dailyRate;
  final double projectedMonthEnd;
  final double lastMonthTotal;
  final String status;
  final int daysRemaining;

  SpendingVelocity({
    required this.currentMonthSpent,
    required this.dailyRate,
    required this.projectedMonthEnd,
    required this.lastMonthTotal,
    required this.status,
    required this.daysRemaining,
  });

  double get remainingBudget => lastMonthTotal - currentMonthSpent;
  double get dailyBudgetRemaining =>
      daysRemaining > 0 ? remainingBudget / daysRemaining : 0;
}

/// Spending anomaly detection
enum AnomalyType { unusuallyLarge, categorySpike, frequencySpike }

class SpendingAnomaly {
  final AnomalyType type;
  final double amount;
  final DateTime date;
  final String description;
  final String? category;
  final double deviation; // How many standard deviations from normal

  SpendingAnomaly({
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.category,
    required this.deviation,
  });
}
