import 'package:flutter/material.dart';

/// Financial health score calculator and display
class FinancialHealthScore {
  final double savingsRate; // % of income saved
  final double debtToIncomeRatio; // % of income going to debt
  final double budgetAdherence; // % of budgets met
  final double emergencyFundMonths; // Months of expenses covered
  final int activeDebts;
  final int overduePayments;

  FinancialHealthScore({
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.budgetAdherence,
    required this.emergencyFundMonths,
    required this.activeDebts,
    required this.overduePayments,
  });

  /// Calculate overall score (0-100)
  int get overallScore {
    double score = 0;

    // Savings Rate (max 25 points)
    // 20%+ is excellent, 10-20% is good, 5-10% fair, <5% poor
    if (savingsRate >= 20) {
      score += 25;
    } else if (savingsRate >= 10) {
      score += 15 + (savingsRate - 10) * 1;
    } else if (savingsRate >= 5) {
      score += 10 + (savingsRate - 5) * 1;
    } else {
      score += savingsRate * 2;
    }

    // Debt to Income (max 25 points)
    // <20% excellent, 20-35% good, 35-50% fair, >50% poor
    if (debtToIncomeRatio <= 20) {
      score += 25;
    } else if (debtToIncomeRatio <= 35) {
      score += 25 - (debtToIncomeRatio - 20);
    } else if (debtToIncomeRatio <= 50) {
      score += 10 - (debtToIncomeRatio - 35) * 0.5;
    } else {
      score += 0;
    }

    // Budget Adherence (max 25 points)
    score += budgetAdherence * 0.25;

    // Emergency Fund (max 15 points)
    // 6+ months excellent, 3-6 good, 1-3 fair, <1 poor
    if (emergencyFundMonths >= 6) {
      score += 15;
    } else if (emergencyFundMonths >= 3) {
      score += 10 + (emergencyFundMonths - 3) * (5 / 3);
    } else if (emergencyFundMonths >= 1) {
      score += 5 + (emergencyFundMonths - 1) * 2.5;
    } else {
      score += emergencyFundMonths * 5;
    }

    // Penalties
    // -2 points per active debt (max -6)
    score -= (activeDebts * 2).clamp(0, 6);

    // -5 points per overdue payment (max -10)
    score -= (overduePayments * 5).clamp(0, 10);

    return score.clamp(0, 100).round();
  }

  /// Get grade (A, B, C, D, F)
  String get grade {
    final score = overallScore;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  /// Get color for the score
  Color get scoreColor {
    final score = overallScore;
    if (score >= 80) return const Color(0xFF00E676); // Green
    if (score >= 60) return const Color(0xFFFFEA00); // Yellow
    if (score >= 40) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFFF3D00); // Red
  }

  /// Get descriptive status
  String get status {
    final score = overallScore;
    if (score >= 90) return 'Excellent! Keep it up!';
    if (score >= 80) return 'Very Good Financial Health';
    if (score >= 70) return 'Good, with room to improve';
    if (score >= 60) return 'Fair - needs attention';
    if (score >= 50) return 'Below Average - take action';
    return 'Needs Improvement';
  }

  /// Get personalized tips based on score components
  List<HealthTip> get tips {
    final tips = <HealthTip>[];

    // Savings tips
    if (savingsRate < 10) {
      tips.add(
        HealthTip(
          icon: Icons.savings,
          title: 'Increase Savings',
          description: 'Try to save at least 10-20% of your income',
          priority: savingsRate < 5 ? TipPriority.high : TipPriority.medium,
        ),
      );
    }

    // Debt tips
    if (debtToIncomeRatio > 35) {
      tips.add(
        HealthTip(
          icon: Icons.credit_card_off,
          title: 'Reduce Debt',
          description:
              'Your debt payments are ${debtToIncomeRatio.toStringAsFixed(0)}% of income. Target under 35%.',
          priority: TipPriority.high,
        ),
      );
    }

    // Budget tips
    if (budgetAdherence < 70) {
      tips.add(
        HealthTip(
          icon: Icons.pie_chart,
          title: 'Stick to Budgets',
          description:
              'You\'re only meeting ${budgetAdherence.toStringAsFixed(0)}% of your budgets',
          priority: TipPriority.medium,
        ),
      );
    }

    // Emergency fund tips
    if (emergencyFundMonths < 3) {
      tips.add(
        HealthTip(
          icon: Icons.emergency,
          title: 'Build Emergency Fund',
          description: 'Aim for 3-6 months of expenses saved',
          priority: emergencyFundMonths < 1
              ? TipPriority.high
              : TipPriority.medium,
        ),
      );
    }

    // Overdue payments
    if (overduePayments > 0) {
      tips.add(
        HealthTip(
          icon: Icons.warning,
          title: 'Clear Overdue Payments',
          description: 'You have $overduePayments overdue payments',
          priority: TipPriority.high,
        ),
      );
    }

    // Positive reinforcement
    if (overallScore >= 80 && tips.isEmpty) {
      tips.add(
        HealthTip(
          icon: Icons.celebration,
          title: 'Great Job!',
          description:
              'Your finances are in excellent shape. Consider investing surplus funds.',
          priority: TipPriority.low,
        ),
      );
    }

    // Sort by priority
    tips.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return tips;
  }

  /// Get component scores for breakdown
  List<ScoreComponent> get components => [
    ScoreComponent(
      name: 'Savings Rate',
      value: savingsRate,
      maxPoints: 25,
      score: _savingsScore,
      description: '${savingsRate.toStringAsFixed(1)}% of income saved',
    ),
    ScoreComponent(
      name: 'Debt-to-Income',
      value: debtToIncomeRatio,
      maxPoints: 25,
      score: _debtScore,
      description: '${debtToIncomeRatio.toStringAsFixed(1)}% going to debt',
    ),
    ScoreComponent(
      name: 'Budget Adherence',
      value: budgetAdherence,
      maxPoints: 25,
      score: (budgetAdherence * 0.25).round(),
      description: '${budgetAdherence.toStringAsFixed(0)}% of budgets met',
    ),
    ScoreComponent(
      name: 'Emergency Fund',
      value: emergencyFundMonths,
      maxPoints: 15,
      score: _emergencyScore,
      description: '${emergencyFundMonths.toStringAsFixed(1)} months covered',
    ),
  ];

  int get _savingsScore {
    if (savingsRate >= 20) return 25;
    if (savingsRate >= 10) return (15 + (savingsRate - 10)).round();
    if (savingsRate >= 5) return (10 + (savingsRate - 5)).round();
    return (savingsRate * 2).round();
  }

  int get _debtScore {
    if (debtToIncomeRatio <= 20) return 25;
    if (debtToIncomeRatio <= 35) return (25 - (debtToIncomeRatio - 20)).round();
    if (debtToIncomeRatio <= 50)
      return (10 - (debtToIncomeRatio - 35) * 0.5).round();
    return 0;
  }

  int get _emergencyScore {
    if (emergencyFundMonths >= 6) return 15;
    if (emergencyFundMonths >= 3)
      return (10 + (emergencyFundMonths - 3) * (5 / 3)).round();
    if (emergencyFundMonths >= 1)
      return (5 + (emergencyFundMonths - 1) * 2.5).round();
    return (emergencyFundMonths * 5).round();
  }
}

/// A tip for improving financial health
class HealthTip {
  final IconData icon;
  final String title;
  final String description;
  final TipPriority priority;

  HealthTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum TipPriority { high, medium, low }

/// Individual component of the health score
class ScoreComponent {
  final String name;
  final double value;
  final int maxPoints;
  final int score;
  final String description;

  ScoreComponent({
    required this.name,
    required this.value,
    required this.maxPoints,
    required this.score,
    required this.description,
  });

  double get percentage => maxPoints > 0 ? (score / maxPoints) * 100 : 0;
}
