import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/goal.dart';
import '../models/subscription.dart';
import '../models/investment.dart';
import '../models/transaction.dart' as models;
import '../services/goal_sip_linking_service.dart';
import '../services/transaction_match_service.dart';

/// Cross-module notification hub that generates intelligent notifications
/// by analyzing data across all financial modules.
class CrossModuleNotificationHub {
  /// Analyze all data and generate relevant notifications
  static List<AppNotification> generateNotifications({
    required List<Budget> budgets,
    required List<Debt> debts,
    required List<Goal> goals,
    required List<Subscription> subscriptions,
    required List<Investment> investments,
    required List<models.Transaction> transactions,
    required double monthlyIncome,
  }) {
    final notifications = <AppNotification>[];
    final now = DateTime.now();

    // 1. Budget Notifications
    notifications.addAll(_generateBudgetNotifications(budgets, now));

    // 2. Debt Notifications
    notifications.addAll(_generateDebtNotifications(debts, now));

    // 3. Goal Notifications
    notifications.addAll(_generateGoalNotifications(goals, investments, now));

    // 4. Subscription Notifications
    notifications.addAll(
      _generateSubscriptionNotifications(subscriptions, now),
    );

    // 5. Investment Notifications
    notifications.addAll(_generateInvestmentNotifications(investments, now));

    // 6. Cross-Module Smart Notifications
    notifications.addAll(
      _generateCrossModuleNotifications(
        budgets: budgets,
        debts: debts,
        goals: goals,
        subscriptions: subscriptions,
        investments: investments,
        transactions: transactions,
        monthlyIncome: monthlyIncome,
      ),
    );

    // Sort by priority and date
    notifications.sort((a, b) {
      final priorityA = _getNotificationPriority(a.type);
      final priorityB = _getNotificationPriority(b.type);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return b.createdAt.compareTo(a.createdAt);
    });

    return notifications;
  }

  // ==================== BUDGET NOTIFICATIONS ====================

  static List<AppNotification> _generateBudgetNotifications(
    List<Budget> budgets,
    DateTime now,
  ) {
    final notifications = <AppNotification>[];

    for (final budget in budgets.where((b) => b.isActive)) {
      final percentUsed = budget.spentPercentage * 100; // Convert to percentage

      // Budget nearly exhausted (90%+)
      if (percentUsed >= 90 && percentUsed < 100) {
        notifications.add(
          AppNotification(
            id: 'budget_90_${budget.id}_${now.month}',
            type: NotificationType.budgetWarning,
            title: '${budget.categoryName} Budget Alert',
            message:
                'You\'ve used ${percentUsed.toStringAsFixed(0)}% of your ${budget.categoryName} budget. ₹${budget.remainingAmount.toStringAsFixed(0)} remaining.',
            createdAt: now,
            data: {'budgetId': budget.id, 'percentUsed': percentUsed},
            actionText: 'View Budget',
            actionRoute: '/budgets/${budget.id}',
          ),
        );
      }

      // Budget exceeded
      if (percentUsed >= 100) {
        final overAmount = budget.spentAmount - budget.allocatedAmount;
        notifications.add(
          AppNotification(
            id: 'budget_exceeded_${budget.id}_${now.month}',
            type: NotificationType.budgetWarning,
            title: '${budget.categoryName} Budget Exceeded',
            message:
                'You\'ve exceeded your ${budget.categoryName} budget by ₹${overAmount.toStringAsFixed(0)}.',
            createdAt: now,
            data: {'budgetId': budget.id, 'overAmount': overAmount},
            actionText: 'Manage Budget',
            actionRoute: '/budgets/${budget.id}',
          ),
        );
      }
    }

    return notifications;
  }

  // ==================== DEBT NOTIFICATIONS ====================

  static List<AppNotification> _generateDebtNotifications(
    List<Debt> debts,
    DateTime now,
  ) {
    final notifications = <AppNotification>[];

    for (final debt in debts.where((d) => d.currentBalance > 0)) {
      // EMI due in 3 days
      if (debt.nextPaymentDate != null) {
        final daysUntilDue = debt.nextPaymentDate!.difference(now).inDays;

        if (daysUntilDue == 3) {
          notifications.add(
            AppNotification(
              id: 'emi_3day_${debt.id}_${debt.nextPaymentDate}',
              type: NotificationType.billReminder,
              title: '${debt.name} EMI Due Soon',
              message:
                  'Your EMI of ₹${(debt.monthlyEMI ?? 0).toStringAsFixed(0)} is due in 3 days.',
              createdAt: now,
              data: {'debtId': debt.id, 'amount': debt.monthlyEMI},
              actionText: 'View Debt',
              actionRoute: '/debts/${debt.id}',
            ),
          );
        }

        if (daysUntilDue == 1) {
          notifications.add(
            AppNotification(
              id: 'emi_1day_${debt.id}_${debt.nextPaymentDate}',
              type: NotificationType.billReminder,
              title: '${debt.name} EMI Due Tomorrow',
              message:
                  'Don\'t forget! Your EMI of ₹${(debt.monthlyEMI ?? 0).toStringAsFixed(0)} is due tomorrow.',
              createdAt: now,
              data: {'debtId': debt.id, 'amount': debt.monthlyEMI},
              actionText: 'View Debt',
              actionRoute: '/debts/${debt.id}',
            ),
          );
        }

        if (daysUntilDue == 0) {
          notifications.add(
            AppNotification(
              id: 'emi_today_${debt.id}_${debt.nextPaymentDate}',
              type: NotificationType.billReminder,
              title: '${debt.name} EMI Due Today',
              message:
                  'Your EMI of ₹${(debt.monthlyEMI ?? 0).toStringAsFixed(0)} is due today.',
              createdAt: now,
              data: {
                'debtId': debt.id,
                'amount': debt.monthlyEMI,
                'urgent': true,
              },
              actionText: 'Mark as Paid',
              actionRoute: '/debts/${debt.id}',
            ),
          );
        }
      }

      // Debt almost paid off (< 3 EMIs remaining)
      if (debt.monthlyEMI != null && debt.monthlyEMI! > 0) {
        final emisRemaining = (debt.currentBalance / debt.monthlyEMI!).ceil();
        if (emisRemaining <= 3 && emisRemaining > 0) {
          notifications.add(
            AppNotification(
              id: 'debt_almost_done_${debt.id}',
              type: NotificationType.goalAchievement,
              title: '${debt.name} Almost Paid Off!',
              message:
                  'Just $emisRemaining EMI${emisRemaining > 1 ? 's' : ''} remaining. You\'re almost debt-free!',
              createdAt: now,
              data: {'debtId': debt.id, 'emisRemaining': emisRemaining},
            ),
          );
        }
      }
    }

    return notifications;
  }

  // ==================== GOAL NOTIFICATIONS ====================

  static List<AppNotification> _generateGoalNotifications(
    List<Goal> goals,
    List<Investment> investments,
    DateTime now,
  ) {
    final notifications = <AppNotification>[];

    // Analyze goals with SIP linking
    final analysis = GoalSipLinkingService.analyze(
      goals: goals,
      investments: investments,
    );

    for (final goal in goals.where((g) => !g.isCompleted)) {
      // Goal achieved!
      if (goal.currentAmount >= goal.targetAmount) {
        notifications.add(
          AppNotification(
            id: 'goal_achieved_${goal.id}',
            type: NotificationType.goalAchievement,
            title: '🎉 Goal Achieved!',
            message:
                'Congratulations! You\'ve reached your "${goal.name}" goal of ₹${goal.targetAmount.toStringAsFixed(0)}!',
            createdAt: now,
            data: {'goalId': goal.id, 'targetAmount': goal.targetAmount},
          ),
        );
      }

      // Milestone reached (25%, 50%, 75%)
      for (final milestone in [25.0, 50.0, 75.0]) {
        if (goal.progressPercentage >= milestone &&
            goal.progressPercentage < milestone + 5) {
          notifications.add(
            AppNotification(
              id: 'goal_milestone_${goal.id}_$milestone',
              type: NotificationType.goalProgress,
              title: '${goal.name} Progress',
              message:
                  'You\'ve reached ${milestone.toInt()}% of your "${goal.name}" goal!',
              createdAt: now,
              data: {'goalId': goal.id, 'milestone': milestone},
            ),
          );
        }
      }

      // Goal deadline approaching (7 days)
      final daysToDeadline = goal.targetDate.difference(now).inDays;
      if (daysToDeadline <= 7 &&
          daysToDeadline > 0 &&
          goal.progressPercentage < 100) {
        notifications.add(
          AppNotification(
            id: 'goal_deadline_${goal.id}',
            type: NotificationType.billReminder,
            title: '${goal.name} Deadline Approaching',
            message:
                'Only $daysToDeadline day${daysToDeadline > 1 ? 's' : ''} left. ${goal.progressPercentage.toStringAsFixed(0)}% complete.',
            createdAt: now,
            data: {'goalId': goal.id, 'daysLeft': daysToDeadline},
            actionText: 'View Goal',
            actionRoute: '/goals/${goal.id}',
          ),
        );
      }
    }

    // Add SIP recommendations as notifications
    for (final rec in analysis.recommendations.take(2)) {
      notifications.add(
        AppNotification(
          id: 'sip_rec_${rec.goalId}_${now.day}',
          type: NotificationType.goalProgress,
          title: 'Goal Optimization Tip',
          message: rec.message,
          createdAt: now,
          data: {'goalId': rec.goalId, 'type': rec.type.toString()},
          actionText: 'Take Action',
          actionRoute: '/goals/${rec.goalId}',
        ),
      );
    }

    return notifications;
  }

  // ==================== SUBSCRIPTION NOTIFICATIONS ====================

  static List<AppNotification> _generateSubscriptionNotifications(
    List<Subscription> subscriptions,
    DateTime now,
  ) {
    final notifications = <AppNotification>[];

    for (final sub in subscriptions.where((s) => s.isActive)) {
      final daysUntilDue = sub.nextDueDate.difference(now).inDays;

      // Due in 3 days
      if (daysUntilDue == 3) {
        notifications.add(
          AppNotification(
            id: 'sub_3day_${sub.id}_${sub.nextDueDate}',
            type: NotificationType.subscriptionReminder,
            title: '${sub.name} Due Soon',
            message:
                'Your ${sub.name} subscription (₹${sub.amount.toStringAsFixed(0)}) is due in 3 days.',
            createdAt: now,
            data: {'subscriptionId': sub.id, 'amount': sub.amount},
            actionText: 'View Subscription',
            actionRoute: '/subscriptions/${sub.id}',
          ),
        );
      }

      // Due tomorrow
      if (daysUntilDue == 1) {
        notifications.add(
          AppNotification(
            id: 'sub_1day_${sub.id}_${sub.nextDueDate}',
            type: NotificationType.subscriptionReminder,
            title: '${sub.name} Due Tomorrow',
            message:
                '${sub.name} subscription payment of ₹${sub.amount.toStringAsFixed(0)} is due tomorrow.',
            createdAt: now,
            data: {'subscriptionId': sub.id, 'amount': sub.amount},
            actionText: 'Mark as Paid',
            actionRoute: '/subscriptions/${sub.id}',
          ),
        );
      }

      // Due today
      if (daysUntilDue == 0) {
        notifications.add(
          AppNotification(
            id: 'sub_today_${sub.id}_${sub.nextDueDate}',
            type: NotificationType.subscriptionReminder,
            title: '${sub.name} Due Today',
            message:
                '${sub.name} subscription (₹${sub.amount.toStringAsFixed(0)}) is due today.',
            createdAt: now,
            data: {
              'subscriptionId': sub.id,
              'amount': sub.amount,
              'urgent': true,
            },
            actionText: 'Mark as Paid',
            actionRoute: '/subscriptions/${sub.id}',
          ),
        );
      }

      // Overdue
      if (sub.isOverdue) {
        final daysOverdue = now.difference(sub.nextDueDate).inDays;
        notifications.add(
          AppNotification(
            id: 'sub_overdue_${sub.id}_${sub.nextDueDate}',
            type: NotificationType.subscriptionReminder,
            title: '${sub.name} Overdue',
            message:
                '${sub.name} subscription is $daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue.',
            createdAt: now,
            data: {'subscriptionId': sub.id, 'daysOverdue': daysOverdue},
            actionText: 'Update',
            actionRoute: '/subscriptions/${sub.id}',
          ),
        );
      }
    }

    return notifications;
  }

  // ==================== INVESTMENT NOTIFICATIONS ====================

  static List<AppNotification> _generateInvestmentNotifications(
    List<Investment> investments,
    DateTime now,
  ) {
    final notifications = <AppNotification>[];

    for (final inv in investments.where((i) => i.isActive)) {
      // SIP due date reminder
      if (inv.sipAmount > 0 && inv.sipDay > 0) {
        final currentDay = now.day;
        final daysUntilSip = (inv.sipDay - currentDay + 30) % 30;

        if (daysUntilSip == 1) {
          notifications.add(
            AppNotification(
              id: 'sip_tomorrow_${inv.id}_${now.month}',
              type: NotificationType.billReminder,
              title: '${inv.name} SIP Tomorrow',
              message:
                  'Your SIP of ₹${inv.sipAmount.toStringAsFixed(0)} for ${inv.name} is due tomorrow.',
              createdAt: now,
              data: {'investmentId': inv.id, 'amount': inv.sipAmount},
            ),
          );
        }

        if (daysUntilSip == 0) {
          notifications.add(
            AppNotification(
              id: 'sip_today_${inv.id}_${now.month}',
              type: NotificationType.billReminder,
              title: '${inv.name} SIP Due Today',
              message:
                  'Your SIP of ₹${inv.sipAmount.toStringAsFixed(0)} for ${inv.name} is due today.',
              createdAt: now,
              data: {'investmentId': inv.id, 'amount': inv.sipAmount},
            ),
          );
        }
      }

      // Significant profit/loss (>10%)
      if (inv.investedAmount > 0) {
        final profitPercent = inv.profitPercent;

        if (profitPercent >= 20) {
          notifications.add(
            AppNotification(
              id: 'inv_profit_${inv.id}_${profitPercent.toStringAsFixed(0)}',
              type: NotificationType.transactionAlert,
              title: '📈 ${inv.name} Up ${profitPercent.toStringAsFixed(1)}%',
              message:
                  'Your ${inv.name} investment is performing well! Current value: ₹${inv.currentAmount.toStringAsFixed(0)}',
              createdAt: now,
              data: {'investmentId': inv.id, 'profitPercent': profitPercent},
            ),
          );
        } else if (profitPercent <= -15) {
          notifications.add(
            AppNotification(
              id: 'inv_loss_${inv.id}_${profitPercent.toStringAsFixed(0)}',
              type: NotificationType.unusualSpending,
              title:
                  '📉 ${inv.name} Down ${profitPercent.abs().toStringAsFixed(1)}%',
              message:
                  'Your ${inv.name} has declined. Consider reviewing your investment strategy.',
              createdAt: now,
              data: {'investmentId': inv.id, 'profitPercent': profitPercent},
              actionText: 'Review',
              actionRoute: '/investments/${inv.id}',
            ),
          );
        }
      }
    }

    return notifications;
  }

  // ==================== CROSS-MODULE NOTIFICATIONS ====================

  static List<AppNotification> _generateCrossModuleNotifications({
    required List<Budget> budgets,
    required List<Debt> debts,
    required List<Goal> goals,
    required List<Subscription> subscriptions,
    required List<Investment> investments,
    required List<models.Transaction> transactions,
    required double monthlyIncome,
  }) {
    final notifications = <AppNotification>[];
    final now = DateTime.now();

    // Calculate upcoming week's obligations
    final totalEMI = debts
        .where((d) => d.currentBalance > 0 && d.monthlyEMI != null)
        .fold(0.0, (sum, d) => sum + d.monthlyEMI!);

    final totalSubscriptions = subscriptions
        .where((s) => s.isActive)
        .fold(0.0, (sum, s) => sum + s.amount);

    final totalSIP = investments
        .where((i) => i.isActive && i.sipAmount > 0)
        .fold(0.0, (sum, i) => sum + i.sipAmount);

    final totalFixedCommitments = totalEMI + totalSubscriptions + totalSIP;

    // High fixed commitments warning
    if (monthlyIncome > 0) {
      final commitmentRatio = totalFixedCommitments / monthlyIncome;
      if (commitmentRatio > 0.6) {
        notifications.add(
          AppNotification(
            id: 'high_commitments_${now.month}',
            type: NotificationType.unusualSpending,
            title: 'High Fixed Commitments',
            message:
                '${(commitmentRatio * 100).toStringAsFixed(0)}% of your income goes to fixed payments (EMIs, subscriptions, SIPs). Consider reviewing.',
            createdAt: now,
            data: {
              'commitmentRatio': commitmentRatio,
              'total': totalFixedCommitments,
            },
            actionText: 'Review',
            actionRoute: '/finance',
          ),
        );
      }
    }

    // Detect unusual spending patterns
    final patterns = TransactionMatchService.detectRecurringPatterns(
      transactions: transactions,
      existingSubscriptions: subscriptions,
      existingDebts: debts,
    );

    if (patterns.isNotEmpty) {
      final topPattern = patterns.first;
      if (topPattern.confidence > 0.7) {
        notifications.add(
          AppNotification(
            id: 'detected_recurring_${topPattern.suggestedName}_${now.month}',
            type: NotificationType.transactionAlert,
            title: 'Recurring Payment Detected',
            message:
                'We noticed "${topPattern.suggestedName}" (₹${topPattern.amount.toStringAsFixed(0)}/${topPattern.frequencyLabel}) appears regularly. Track it as a subscription?',
            createdAt: now,
            data: {
              'pattern': topPattern.suggestedName,
              'amount': topPattern.amount,
            },
            actionText: 'Track It',
            actionRoute: '/subscriptions/add',
          ),
        );
      }
    }

    // Weekly summary (on Monday)
    if (now.weekday == DateTime.monday) {
      final weekStart = now.subtract(Duration(days: 7));
      final weekExpenses = transactions
          .where(
            (t) =>
                t.type == models.TransactionType.expense &&
                t.date.isAfter(weekStart) &&
                t.date.isBefore(now),
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      if (weekExpenses > 0) {
        notifications.add(
          AppNotification(
            id: 'weekly_summary_${now.year}_${now.month}_${now.day ~/ 7}',
            type: NotificationType.systemUpdate,
            title: 'Weekly Spending Summary',
            message:
                'You spent ₹${NumberFormat('#,##0').format(weekExpenses)} last week across ${transactions.length} transactions.',
            createdAt: now,
            data: {'weeklyTotal': weekExpenses},
            actionText: 'View Details',
            actionRoute: '/transactions',
          ),
        );
      }
    }

    return notifications;
  }

  static int _getNotificationPriority(NotificationType type) {
    switch (type) {
      case NotificationType.billReminder:
        return 1;
      case NotificationType.budgetWarning:
        return 2;
      case NotificationType.subscriptionReminder:
        return 3;
      case NotificationType.unusualSpending:
        return 4;
      case NotificationType.transactionAlert:
        return 5;
      case NotificationType.goalAchievement:
        return 6;
      case NotificationType.goalProgress:
        return 7;
      case NotificationType.systemUpdate:
        return 8;
      case NotificationType.fuelLogged:
        return 9;
    }
  }
}
