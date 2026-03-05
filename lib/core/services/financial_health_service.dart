import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/goal.dart';
import '../models/subscription.dart';
import '../models/investment.dart';

/// Comprehensive Financial Health Score Service
/// Aggregates data from all financial modules to calculate a holistic health score
class FinancialHealthService {
  static const double _maxScore = 100.0;

  /// Calculate overall financial health score (0-100)
  static FinancialHealthReport calculateHealthScore({
    required double totalCash,
    required double totalInvestments,
    required double totalDebt,
    required double monthlyIncome,
    required double monthlyExpenses,
    required List<Budget> budgets,
    required List<Debt> debts,
    required List<Goal> goals,
    required List<Subscription> subscriptions,
    required List<Investment> investments,
  }) {
    final scores = <String, double>{};
    final insights = <HealthInsight>[];

    // 1. BUDGET ADHERENCE (25 points max)
    final budgetScore = _calculateBudgetScore(budgets);
    scores['budget'] = budgetScore.score;
    insights.addAll(budgetScore.insights);

    // 2. DEBT HEALTH (25 points max)
    final debtScore = _calculateDebtScore(debts, monthlyIncome);
    scores['debt'] = debtScore.score;
    insights.addAll(debtScore.insights);

    // 3. SAVINGS & GOALS (25 points max)
    final savingsScore = _calculateSavingsScore(
      goals,
      investments,
      monthlyIncome,
      monthlyExpenses,
    );
    scores['savings'] = savingsScore.score;
    insights.addAll(savingsScore.insights);

    // 4. CASH FLOW & LIQUIDITY (25 points max)
    final liquidityScore = _calculateLiquidityScore(
      totalCash,
      totalDebt,
      monthlyExpenses,
      subscriptions,
      debts,
    );
    scores['liquidity'] = liquidityScore.score;
    insights.addAll(liquidityScore.insights);

    // Calculate total score
    final totalScore = scores.values.fold(0.0, (sum, s) => sum + s);

    // Determine grade
    final grade = _getGrade(totalScore);

    // Sort insights by priority
    insights.sort((a, b) => b.priority.compareTo(a.priority));

    return FinancialHealthReport(
      overallScore: totalScore,
      maxScore: _maxScore,
      grade: grade,
      categoryScores: scores,
      insights: insights.take(5).toList(), // Top 5 insights
      lastCalculated: DateTime.now(),
    );
  }

  static _ScoreResult _calculateBudgetScore(List<Budget> budgets) {
    final insights = <HealthInsight>[];

    if (budgets.isEmpty) {
      insights.add(
        HealthInsight(
          type: InsightType.warning,
          title: 'No budgets set',
          message: 'Create budgets to track your spending habits',
          action: 'Set up budgets',
          actionRoute: '/budgets',
          priority: 8,
        ),
      );
      return _ScoreResult(10, insights); // Partial score for having the app
    }

    double totalScore = 0;
    int onTrack = 0;
    int overBudget = 0;

    for (final budget in budgets) {
      if (budget.isOverspent) {
        overBudget++;
      } else if (budget.progress <= 0.9) {
        onTrack++;
        totalScore += 1;
      } else {
        totalScore += 0.5; // Near limit
      }
    }

    final budgetScore = (totalScore / budgets.length) * 25;

    if (overBudget > 0) {
      insights.add(
        HealthInsight(
          type: InsightType.alert,
          title: '$overBudget budget${overBudget > 1 ? 's' : ''} exceeded',
          message: 'Review your spending in these categories',
          action: 'View budgets',
          actionRoute: '/budgets',
          priority: 9,
        ),
      );
    }

    if (onTrack == budgets.length) {
      insights.add(
        HealthInsight(
          type: InsightType.success,
          title: 'All budgets on track! 🎉',
          message: 'You\'re doing great managing your spending',
          priority: 3,
        ),
      );
    }

    return _ScoreResult(budgetScore, insights);
  }

  static _ScoreResult _calculateDebtScore(
    List<Debt> debts,
    double monthlyIncome,
  ) {
    final insights = <HealthInsight>[];

    final activeDebts = debts
        .where((d) => d.currentBalance > 0 && d.type != DebtType.owedToMe)
        .toList();

    if (activeDebts.isEmpty) {
      insights.add(
        HealthInsight(
          type: InsightType.success,
          title: 'Debt-free! 🎊',
          message: 'You have no active debts',
          priority: 2,
        ),
      );
      return _ScoreResult(25, insights); // Full score
    }

    // ignore: unused_local_variable
    final _ = activeDebts.fold(0.0, (sum, d) => sum + d.currentBalance);
    final totalEMI = activeDebts.fold(
      0.0,
      (sum, d) => sum + (d.monthlyEMI ?? 0),
    );

    // Debt-to-income ratio (EMI shouldn't exceed 40% of income)
    final dtiRatio = monthlyIncome > 0 ? totalEMI / monthlyIncome : 1.0;

    double debtScore = 25;

    if (dtiRatio > 0.5) {
      debtScore = 5;
      insights.add(
        HealthInsight(
          type: InsightType.alert,
          title: 'High debt burden',
          message:
              'EMIs are ${(dtiRatio * 100).toStringAsFixed(0)}% of your income (ideal: <40%)',
          action: 'Review debts',
          actionRoute: '/debts',
          priority: 10,
        ),
      );
    } else if (dtiRatio > 0.4) {
      debtScore = 12;
      insights.add(
        HealthInsight(
          type: InsightType.warning,
          title: 'EMIs at ${(dtiRatio * 100).toStringAsFixed(0)}% of income',
          message: 'Consider reducing debt or increasing income',
          action: 'Debt strategies',
          actionRoute: '/debts',
          priority: 7,
        ),
      );
    } else if (dtiRatio > 0.3) {
      debtScore = 18;
    } else {
      debtScore = 22;
      insights.add(
        HealthInsight(
          type: InsightType.success,
          title: 'Healthy debt ratio',
          message: 'Your EMIs are well within manageable limits',
          priority: 2,
        ),
      );
    }

    // Check for high-interest debts (credit cards)
    final creditCards = activeDebts
        .where((d) => d.type == DebtType.creditCard)
        .toList();
    if (creditCards.isNotEmpty) {
      final ccDebt = creditCards.fold(0.0, (sum, d) => sum + d.currentBalance);
      if (ccDebt > 50000) {
        debtScore -= 5;
        insights.add(
          HealthInsight(
            type: InsightType.alert,
            title: 'High credit card debt',
            message:
                'Credit card interest can accumulate fast. Prioritize paying this off.',
            action: 'View credit cards',
            actionRoute: '/debts',
            priority: 9,
          ),
        );
      }
    }

    return _ScoreResult(debtScore.clamp(0, 25), insights);
  }

  static _ScoreResult _calculateSavingsScore(
    List<Goal> goals,
    List<Investment> investments,
    double monthlyIncome,
    double monthlyExpenses,
  ) {
    final insights = <HealthInsight>[];
    double savingsScore = 0;

    // Calculate savings rate
    final monthlySavings = monthlyIncome - monthlyExpenses;
    final savingsRate = monthlyIncome > 0 ? monthlySavings / monthlyIncome : 0;

    if (savingsRate >= 0.2) {
      savingsScore += 10;
      insights.add(
        HealthInsight(
          type: InsightType.success,
          title: 'Great savings rate!',
          message:
              'You\'re saving ${(savingsRate * 100).toStringAsFixed(0)}% of your income',
          priority: 3,
        ),
      );
    } else if (savingsRate >= 0.1) {
      savingsScore += 6;
    } else if (savingsRate > 0) {
      savingsScore += 3;
      insights.add(
        HealthInsight(
          type: InsightType.tip,
          title: 'Increase your savings',
          message: 'Aim to save at least 20% of your income',
          action: 'Set up goals',
          actionRoute: '/goals',
          priority: 5,
        ),
      );
    } else {
      insights.add(
        HealthInsight(
          type: InsightType.alert,
          title: 'Negative cash flow',
          message: 'You\'re spending more than you earn',
          action: 'Review expenses',
          actionRoute: '/transactions',
          priority: 10,
        ),
      );
    }

    // Goals progress
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    if (activeGoals.isNotEmpty) {
      final avgProgress =
          activeGoals.fold(0.0, (sum, g) => sum + g.progressPercentage) /
          activeGoals.length;
      savingsScore += (avgProgress / 100) * 8;

      final overdueGoals = activeGoals.where((g) => g.isOverdue).length;
      if (overdueGoals > 0) {
        insights.add(
          HealthInsight(
            type: InsightType.warning,
            title:
                '$overdueGoals goal${overdueGoals > 1 ? 's' : ''} past deadline',
            message: 'Review and adjust your goal timelines',
            action: 'View goals',
            actionRoute: '/goals',
            priority: 6,
          ),
        );
      }
    } else {
      insights.add(
        HealthInsight(
          type: InsightType.tip,
          title: 'Set financial goals',
          message: 'Goals help you stay motivated and track progress',
          action: 'Create a goal',
          actionRoute: '/goals',
          priority: 4,
        ),
      );
    }

    // Investment diversity
    if (investments.isNotEmpty) {
      final totalInvested = investments.fold(
        0.0,
        (sum, i) => sum + i.investedAmount,
      );
      final hasMultipleTypes =
          investments.map((i) => i.type).toSet().length > 1;

      savingsScore += 5;
      if (hasMultipleTypes) {
        savingsScore += 2;
      }

      // Use totalInvested for insight if significant
      if (totalInvested > monthlyIncome * 3) {
        savingsScore += 3; // Bonus for substantial investments
      }

      // Check for SIPs
      final sipCount = investments.where((i) => i.sipAmount > 0).length;
      if (sipCount > 0) {
        insights.add(
          HealthInsight(
            type: InsightType.success,
            title: '$sipCount active SIP${sipCount > 1 ? 's' : ''}',
            message: 'Systematic investing is key to wealth building',
            priority: 2,
          ),
        );
      }
    } else {
      insights.add(
        HealthInsight(
          type: InsightType.tip,
          title: 'Start investing',
          message: 'Even small regular investments grow over time',
          action: 'Add investment',
          actionRoute: '/investments',
          priority: 5,
        ),
      );
    }

    return _ScoreResult(savingsScore.clamp(0, 25), insights);
  }

  static _ScoreResult _calculateLiquidityScore(
    double totalCash,
    double totalDebt,
    double monthlyExpenses,
    List<Subscription> subscriptions,
    List<Debt> debts,
  ) {
    final insights = <HealthInsight>[];
    double liquidityScore = 0;

    // Emergency fund check (should cover 3-6 months expenses)
    final monthsCovered = monthlyExpenses > 0 ? totalCash / monthlyExpenses : 0;

    if (monthsCovered >= 6) {
      liquidityScore += 15;
      insights.add(
        HealthInsight(
          type: InsightType.success,
          title: '6+ months emergency fund',
          message: 'Excellent financial cushion!',
          priority: 1,
        ),
      );
    } else if (monthsCovered >= 3) {
      liquidityScore += 10;
    } else if (monthsCovered >= 1) {
      liquidityScore += 5;
      insights.add(
        HealthInsight(
          type: InsightType.warning,
          title: 'Build your emergency fund',
          message: 'Aim for 3-6 months of expenses in savings',
          action: 'Set savings goal',
          actionRoute: '/goals',
          priority: 7,
        ),
      );
    } else {
      insights.add(
        HealthInsight(
          type: InsightType.alert,
          title: 'Low emergency reserves',
          message: 'Your savings cover less than 1 month of expenses',
          action: 'Review finances',
          actionRoute: '/insights',
          priority: 9,
        ),
      );
    }

    // Check upcoming obligations
    final totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));
    final totalSubs = subscriptions.where((s) => s.isActive).fold(0.0, (
      sum,
      s,
    ) {
      // Normalize to monthly
      switch (s.frequency.toLowerCase()) {
        case 'weekly':
          return sum + s.amount * 4.33;
        case 'yearly':
          return sum + s.amount / 12;
        default:
          return sum + s.amount;
      }
    });

    final fixedObligations = totalEMIs + totalSubs;
    final obligationRatio = monthlyExpenses > 0
        ? fixedObligations / monthlyExpenses
        : 0;

    if (obligationRatio < 0.3) {
      liquidityScore += 10;
    } else if (obligationRatio < 0.5) {
      liquidityScore += 6;
    } else {
      liquidityScore += 2;
      insights.add(
        HealthInsight(
          type: InsightType.warning,
          title: 'High fixed obligations',
          message:
              '${(obligationRatio * 100).toStringAsFixed(0)}% of expenses are fixed commitments',
          priority: 6,
        ),
      );
    }

    return _ScoreResult(liquidityScore.clamp(0, 25), insights);
  }

  static HealthGrade _getGrade(double score) {
    if (score >= 90) { return HealthGrade.excellent; }
    if (score >= 75) { return HealthGrade.good; }
    if (score >= 60) { return HealthGrade.fair; }
    if (score >= 40) { return HealthGrade.needsWork; }
    return HealthGrade.critical;
  }

  /// Calculate what-if scenarios
  static WhatIfResult calculateWhatIf({
    required String scenario,
    required FinancialHealthReport currentReport,
    required Map<String, dynamic> changes,
  }) {
    // Placeholder for what-if calculations
    // This would recalculate the score with modified inputs
    return WhatIfResult(
      scenario: scenario,
      currentScore: currentReport.overallScore,
      projectedScore: currentReport.overallScore, // Would be calculated
      difference: 0,
      recommendations: [],
    );
  }
}

// ==================== MODELS ====================

class FinancialHealthReport {
  final double overallScore;
  final double maxScore;
  final HealthGrade grade;
  final Map<String, double> categoryScores;
  final List<HealthInsight> insights;
  final DateTime lastCalculated;

  FinancialHealthReport({
    required this.overallScore,
    required this.maxScore,
    required this.grade,
    required this.categoryScores,
    required this.insights,
    required this.lastCalculated,
  });

  double get percentage => (overallScore / maxScore * 100).clamp(0, 100);

  String get gradeLabel {
    switch (grade) {
      case HealthGrade.excellent:
        return 'Excellent';
      case HealthGrade.good:
        return 'Good';
      case HealthGrade.fair:
        return 'Fair';
      case HealthGrade.needsWork:
        return 'Needs Work';
      case HealthGrade.critical:
        return 'Critical';
    }
  }

  Color get gradeColor {
    switch (grade) {
      case HealthGrade.excellent:
        return const Color(0xFF4CAF50);
      case HealthGrade.good:
        return const Color(0xFF8BC34A);
      case HealthGrade.fair:
        return const Color(0xFFFFC107);
      case HealthGrade.needsWork:
        return const Color(0xFFFF9800);
      case HealthGrade.critical:
        return const Color(0xFFF44336);
    }
  }
}

enum HealthGrade { excellent, good, fair, needsWork, critical }

enum InsightType { success, tip, warning, alert }

class HealthInsight {
  final InsightType type;
  final String title;
  final String message;
  final String? action;
  final String? actionRoute;
  final int priority; // Higher = more important

  HealthInsight({
    required this.type,
    required this.title,
    required this.message,
    this.action,
    this.actionRoute,
    this.priority = 5,
  });

  Color get color {
    switch (type) {
      case InsightType.success:
        return const Color(0xFF4CAF50);
      case InsightType.tip:
        return const Color(0xFF2196F3);
      case InsightType.warning:
        return const Color(0xFFFF9800);
      case InsightType.alert:
        return const Color(0xFFF44336);
    }
  }

  IconData get icon {
    switch (type) {
      case InsightType.success:
        return Icons.check_circle_rounded;
      case InsightType.tip:
        return Icons.lightbulb_rounded;
      case InsightType.warning:
        return Icons.warning_rounded;
      case InsightType.alert:
        return Icons.error_rounded;
    }
  }
}

class _ScoreResult {
  final double score;
  final List<HealthInsight> insights;
  _ScoreResult(this.score, this.insights);
}

class WhatIfResult {
  final String scenario;
  final double currentScore;
  final double projectedScore;
  final double difference;
  final List<String> recommendations;

  WhatIfResult({
    required this.scenario,
    required this.currentScore,
    required this.projectedScore,
    required this.difference,
    required this.recommendations,
  });
}

/// Upcoming payments/obligations aggregator
class UpcomingObligations {
  final List<UpcomingPayment> payments;
  final double totalAmount;
  final int daysAhead;

  UpcomingObligations({
    required this.payments,
    required this.totalAmount,
    required this.daysAhead,
  });

  static UpcomingObligations calculate({
    required List<Debt> debts,
    required List<Subscription> subscriptions,
    required int daysAhead,
  }) {
    final payments = <UpcomingPayment>[];
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));

    // Add EMI payments
    for (final debt in debts) {
      if (debt.nextPaymentDate != null &&
          debt.nextPaymentDate!.isAfter(now) &&
          debt.nextPaymentDate!.isBefore(cutoff)) {
        payments.add(
          UpcomingPayment(
            name: debt.name,
            amount: debt.monthlyEMI ?? 0,
            dueDate: debt.nextPaymentDate!,
            type: PaymentType.emi,
            icon: debt.type.icon,
          ),
        );
      }
    }

    // Add subscription payments
    for (final sub in subscriptions.where((s) => s.isActive)) {
      if (sub.nextDueDate.isAfter(now) && sub.nextDueDate.isBefore(cutoff)) {
        payments.add(
          UpcomingPayment(
            name: sub.name,
            amount: sub.amount,
            dueDate: sub.nextDueDate,
            type: PaymentType.subscription,
            icon: '🔄',
          ),
        );
      }
    }

    // Sort by due date
    payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final total = payments.fold(0.0, (sum, p) => sum + p.amount);

    return UpcomingObligations(
      payments: payments,
      totalAmount: total,
      daysAhead: daysAhead,
    );
  }
}

enum PaymentType { emi, subscription, bill, goal }

class UpcomingPayment {
  final String name;
  final double amount;
  final DateTime dueDate;
  final PaymentType type;
  final String icon;

  UpcomingPayment({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.icon,
  });

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  bool get isDueToday => daysUntilDue == 0;
  bool get isDueTomorrow => daysUntilDue == 1;
  bool get isOverdue => daysUntilDue < 0;
}
