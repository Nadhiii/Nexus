import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/investment.dart';
import 'dart:math' as math;

/// Service that analyzes goals and investments to provide linking recommendations
/// and automatic syncing between SIPs and financial goals.
class GoalSipLinkingService {
  /// Analyze all goals and investments to find potential links and recommendations
  static GoalSipAnalysis analyze({
    required List<Goal> goals,
    required List<Investment> investments,
  }) {
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final activeSips = investments
        .where((i) => i.isActive && i.sipAmount > 0)
        .toList();
    final activeInvestments = investments.where((i) => i.isActive).toList();

    final recommendations = <LinkRecommendation>[];
    final insights = <GoalInsight>[];
    final goalProjections = <String, GoalProjection>{};

    for (final goal in activeGoals) {
      // Calculate time to goal
      final monthsToGoal =
          goal.targetDate.difference(DateTime.now()).inDays / 30;
      final amountNeeded = goal.remainingAmount;

      // Required monthly contribution
      final requiredMonthly = monthsToGoal > 0
          ? amountNeeded / monthsToGoal
          : amountNeeded;

      // Check if there are matching SIPs
      final matchingSips = _findMatchingSips(
        goal: goal,
        investments: activeSips,
        requiredMonthly: requiredMonthly,
      );

      // Calculate projected completion
      final projection = _calculateProjection(
        goal: goal,
        linkedSips: matchingSips,
        allInvestments: activeInvestments,
      );
      goalProjections[goal.id] = projection;

      // Generate recommendations
      if (matchingSips.isEmpty && monthsToGoal > 1) {
        // No SIP linked - suggest creating one
        recommendations.add(
          LinkRecommendation(
            goalId: goal.id,
            goalName: goal.name,
            type: RecommendationType.createSip,
            suggestedAmount: requiredMonthly,
            message:
                'Start a ₹${requiredMonthly.toStringAsFixed(0)}/month SIP to reach "${goal.name}"',
            priority: _calculatePriority(goal, monthsToGoal, requiredMonthly),
          ),
        );
      } else if (matchingSips.isNotEmpty) {
        final totalSipAmount = matchingSips.fold(
          0.0,
          (sum, s) => sum + s.sipAmount,
        );

        if (totalSipAmount < requiredMonthly * 0.8) {
          // SIP exists but insufficient
          final deficit = requiredMonthly - totalSipAmount;
          recommendations.add(
            LinkRecommendation(
              goalId: goal.id,
              goalName: goal.name,
              type: RecommendationType.increaseSip,
              suggestedAmount: deficit,
              linkedInvestmentIds: matchingSips.map((s) => s.id).toList(),
              message:
                  'Increase SIP by ₹${deficit.toStringAsFixed(0)}/month to stay on track for "${goal.name}"',
              priority: _calculatePriority(goal, monthsToGoal, deficit),
            ),
          );
        } else if (totalSipAmount >= requiredMonthly) {
          // On track!
          insights.add(
            GoalInsight(
              goalId: goal.id,
              goalName: goal.name,
              type: InsightType.onTrack,
              message: 'Great! Your SIPs cover the target for "${goal.name}"',
              data: {'surplus': totalSipAmount - requiredMonthly},
            ),
          );
        }
      }

      // Time-based insights
      if (monthsToGoal < 3 && goal.progressPercentage < 80) {
        insights.add(
          GoalInsight(
            goalId: goal.id,
            goalName: goal.name,
            type: InsightType.urgentAttention,
            message:
                'Only ${monthsToGoal.toStringAsFixed(0)} months left for "${goal.name}" - ${goal.progressPercentage.toStringAsFixed(0)}% complete',
            data: {
              'monthsLeft': monthsToGoal,
              'progress': goal.progressPercentage,
            },
          ),
        );
      }

      if (goal.isOverdue) {
        insights.add(
          GoalInsight(
            goalId: goal.id,
            goalName: goal.name,
            type: InsightType.overdue,
            message:
                '"${goal.name}" target date has passed - consider extending or increasing contributions',
            data: {
              'daysOverdue': DateTime.now().difference(goal.targetDate).inDays,
            },
          ),
        );
      }
    }

    // Analyze orphan SIPs (not linked to any goal)
    for (final sip in activeSips) {
      final hasMatch = recommendations.any(
        (r) => r.linkedInvestmentIds?.contains(sip.id) == true,
      );

      if (!hasMatch) {
        // Suggest linking to a goal
        final suitableGoal = _findSuitableGoal(sip, activeGoals);
        if (suitableGoal != null) {
          recommendations.add(
            LinkRecommendation(
              goalId: suitableGoal.id,
              goalName: suitableGoal.name,
              investmentId: sip.id,
              investmentName: sip.name,
              type: RecommendationType.linkExisting,
              suggestedAmount: sip.sipAmount,
              message:
                  'Link your ${sip.name} SIP (₹${sip.sipAmount.toStringAsFixed(0)}/month) to "${suitableGoal.name}"',
              priority: 3,
            ),
          );
        }
      }
    }

    // Sort recommendations by priority
    recommendations.sort((a, b) => a.priority.compareTo(b.priority));

    return GoalSipAnalysis(
      recommendations: recommendations,
      insights: insights,
      goalProjections: goalProjections,
      totalMonthlySip: activeSips.fold(0.0, (sum, s) => sum + s.sipAmount),
      totalGoalTarget: activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount),
      overallHealthScore: _calculateOverallHealth(activeGoals, goalProjections),
    );
  }

  static List<Investment> _findMatchingSips({
    required Goal goal,
    required List<Investment> investments,
    required double requiredMonthly,
  }) {
    final matches = <Investment>[];

    for (final inv in investments) {
      // Match by name similarity
      final nameSimilarity = _calculateNameSimilarity(goal.name, inv.name);

      // Match by amount appropriateness
      final amountMatch =
          inv.sipAmount > 0 && inv.sipAmount <= requiredMonthly * 1.5;

      if (nameSimilarity > 0.3 || (amountMatch && nameSimilarity > 0.1)) {
        matches.add(inv);
      }
    }

    return matches;
  }

  static double _calculateNameSimilarity(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\s+')).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'\s+')).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0;

    final intersection = wordsA.intersection(wordsB);
    return intersection.length / math.max(wordsA.length, wordsB.length);
  }

  static GoalProjection _calculateProjection({
    required Goal goal,
    required List<Investment> linkedSips,
    required List<Investment> allInvestments,
  }) {
    final now = DateTime.now();
    final monthsRemaining = goal.targetDate.difference(now).inDays / 30;

    final totalSipAmount = linkedSips.fold(0.0, (sum, s) => sum + s.sipAmount);
    final linkedInvestmentValue = linkedSips.fold(
      0.0,
      (sum, s) => sum + s.currentAmount,
    );

    // Assume 10% annual growth for investments
    const annualGrowthRate = 0.10;
    final monthlyGrowthRate = annualGrowthRate / 12;

    // Project future value using compound interest with monthly contributions
    double projectedValue = goal.currentAmount + linkedInvestmentValue;
    for (int month = 0; month < monthsRemaining; month++) {
      projectedValue *= (1 + monthlyGrowthRate);
      projectedValue += totalSipAmount;
    }

    final targetReachable = projectedValue >= goal.targetAmount;
    final estimatedCompletion = _estimateCompletionDate(
      currentAmount: goal.currentAmount + linkedInvestmentValue,
      targetAmount: goal.targetAmount,
      monthlySip: totalSipAmount,
      monthlyGrowthRate: monthlyGrowthRate,
    );

    return GoalProjection(
      goalId: goal.id,
      projectedAmount: projectedValue,
      projectedDate: estimatedCompletion,
      isOnTrack: targetReachable,
      monthsAhead: estimatedCompletion != null
          ? (goal.targetDate.difference(estimatedCompletion).inDays / 30)
          : 0,
      confidenceScore: _calculateConfidence(
        goal,
        projectedValue,
        monthsRemaining,
      ),
    );
  }

  static DateTime? _estimateCompletionDate({
    required double currentAmount,
    required double targetAmount,
    required double monthlySip,
    required double monthlyGrowthRate,
  }) {
    if (currentAmount >= targetAmount) return DateTime.now();
    if (monthlySip <= 0) return null;

    double projected = currentAmount;
    int months = 0;
    const maxMonths = 600; // 50 years max

    while (projected < targetAmount && months < maxMonths) {
      projected *= (1 + monthlyGrowthRate);
      projected += monthlySip;
      months++;
    }

    if (months >= maxMonths) return null;
    return DateTime.now().add(Duration(days: months * 30));
  }

  static double _calculateConfidence(
    Goal goal,
    double projectedValue,
    double monthsRemaining,
  ) {
    final surplus = projectedValue - goal.targetAmount;
    final surplusRatio = surplus / goal.targetAmount;

    // Higher surplus = higher confidence
    double confidence = 0.5;
    if (surplusRatio > 0.2)
      confidence = 0.9;
    else if (surplusRatio > 0.1)
      confidence = 0.8;
    else if (surplusRatio > 0)
      confidence = 0.7;
    else if (surplusRatio > -0.1)
      confidence = 0.5;
    else
      confidence = 0.3;

    // Longer time horizon reduces confidence slightly
    if (monthsRemaining > 60) confidence *= 0.9;
    if (monthsRemaining > 120) confidence *= 0.85;

    return confidence.clamp(0.0, 1.0);
  }

  static Goal? _findSuitableGoal(Investment sip, List<Goal> goals) {
    if (goals.isEmpty) return null;

    Goal? bestMatch;
    double bestScore = 0;

    for (final goal in goals) {
      final nameSimilarity = _calculateNameSimilarity(goal.name, sip.name);

      final monthsToGoal =
          goal.targetDate.difference(DateTime.now()).inDays / 30;
      final requiredMonthly = monthsToGoal > 0
          ? goal.remainingAmount / monthsToGoal
          : goal.remainingAmount;

      final amountScore =
          1 - (sip.sipAmount - requiredMonthly).abs() / (requiredMonthly + 1);

      final score = (nameSimilarity * 0.6) + (amountScore.clamp(0, 1) * 0.4);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = goal;
      }
    }

    return bestScore > 0.2 ? bestMatch : null;
  }

  static int _calculatePriority(Goal goal, double monthsToGoal, double amount) {
    // Lower number = higher priority
    if (goal.isOverdue) return 1;
    if (monthsToGoal < 3) return 2;
    if (monthsToGoal < 6) return 3;
    if (amount > 10000) return 4;
    return 5;
  }

  static double _calculateOverallHealth(
    List<Goal> goals,
    Map<String, GoalProjection> projections,
  ) {
    if (goals.isEmpty) return 100;

    double totalScore = 0;
    for (final goal in goals) {
      final projection = projections[goal.id];
      if (projection != null) {
        totalScore += projection.confidenceScore * 100;
      } else {
        totalScore += goal.progressPercentage;
      }
    }

    return totalScore / goals.length;
  }
}

/// Complete analysis result
class GoalSipAnalysis {
  final List<LinkRecommendation> recommendations;
  final List<GoalInsight> insights;
  final Map<String, GoalProjection> goalProjections;
  final double totalMonthlySip;
  final double totalGoalTarget;
  final double overallHealthScore;

  GoalSipAnalysis({
    required this.recommendations,
    required this.insights,
    required this.goalProjections,
    required this.totalMonthlySip,
    required this.totalGoalTarget,
    required this.overallHealthScore,
  });

  bool get hasUrgentItems =>
      recommendations.any((r) => r.priority <= 2) ||
      insights.any(
        (i) =>
            i.type == InsightType.urgentAttention ||
            i.type == InsightType.overdue,
      );
}

enum RecommendationType { createSip, increaseSip, linkExisting, diversify }

class LinkRecommendation {
  final String goalId;
  final String goalName;
  final String? investmentId;
  final String? investmentName;
  final RecommendationType type;
  final double suggestedAmount;
  final String message;
  final int priority;
  final List<String>? linkedInvestmentIds;

  LinkRecommendation({
    required this.goalId,
    required this.goalName,
    this.investmentId,
    this.investmentName,
    required this.type,
    required this.suggestedAmount,
    required this.message,
    required this.priority,
    this.linkedInvestmentIds,
  });

  IconData get icon {
    switch (type) {
      case RecommendationType.createSip:
        return Icons.add_circle_outline;
      case RecommendationType.increaseSip:
        return Icons.trending_up;
      case RecommendationType.linkExisting:
        return Icons.link;
      case RecommendationType.diversify:
        return Icons.pie_chart;
    }
  }

  Color get color {
    switch (priority) {
      case 1:
        return const Color(0xFFF44336);
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF2196F3);
    }
  }
}

enum InsightType {
  onTrack,
  aheadOfSchedule,
  behindSchedule,
  urgentAttention,
  overdue,
}

class GoalInsight {
  final String goalId;
  final String goalName;
  final InsightType type;
  final String message;
  final Map<String, dynamic>? data;

  GoalInsight({
    required this.goalId,
    required this.goalName,
    required this.type,
    required this.message,
    this.data,
  });

  IconData get icon {
    switch (type) {
      case InsightType.onTrack:
        return Icons.check_circle;
      case InsightType.aheadOfSchedule:
        return Icons.rocket_launch;
      case InsightType.behindSchedule:
        return Icons.warning_amber;
      case InsightType.urgentAttention:
        return Icons.priority_high;
      case InsightType.overdue:
        return Icons.error;
    }
  }

  Color get color {
    switch (type) {
      case InsightType.onTrack:
      case InsightType.aheadOfSchedule:
        return const Color(0xFF4CAF50);
      case InsightType.behindSchedule:
        return const Color(0xFFFF9800);
      case InsightType.urgentAttention:
      case InsightType.overdue:
        return const Color(0xFFF44336);
    }
  }
}

class GoalProjection {
  final String goalId;
  final double projectedAmount;
  final DateTime? projectedDate;
  final bool isOnTrack;
  final double monthsAhead; // Positive = ahead, negative = behind
  final double confidenceScore;

  GoalProjection({
    required this.goalId,
    required this.projectedAmount,
    this.projectedDate,
    required this.isOnTrack,
    required this.monthsAhead,
    required this.confidenceScore,
  });

  String get statusText {
    if (isOnTrack && monthsAhead > 1) {
      return '${monthsAhead.abs().toStringAsFixed(0)} months ahead';
    } else if (isOnTrack) {
      return 'On track';
    } else if (monthsAhead < -3) {
      return '${monthsAhead.abs().toStringAsFixed(0)} months behind';
    } else {
      return 'Needs attention';
    }
  }
}
