import '../models/payday_checklist.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/family_debt_provider.dart';

/// Service to generate payday checklists
/// Aggregates data from all financial providers to create actionable items
class PaydayChecklistService {
  final DebtProvider? debtProvider;
  final SubscriptionProvider? subscriptionProvider;
  final GoalProvider? goalProvider;
  final BudgetProvider? budgetProvider;
  final FamilyDebtProvider? familyDebtProvider;

  /// Minimum income amount to trigger checklist (configurable)
  final double minimumIncomeThreshold;

  /// Days to look ahead for due items
  final int lookAheadDays;

  PaydayChecklistService({
    this.debtProvider,
    this.subscriptionProvider,
    this.goalProvider,
    this.budgetProvider,
    this.familyDebtProvider,
    this.minimumIncomeThreshold = 5000,
    this.lookAheadDays = 14,
  });

  /// Check if income should trigger a checklist
  bool shouldShowChecklist(double amount, String? category) {
    // Always show for salary category
    if (category?.toLowerCase() == 'salary') {
      return true;
    }

    // Show for significant income
    return amount >= minimumIncomeThreshold;
  }

  /// Generate a complete payday checklist
  PaydayChecklist generateChecklist({
    required double incomeAmount,
    String? incomeSource,
    DateTime? incomeDate,
  }) {
    final date = incomeDate ?? DateTime.now();
    final items = <PaydayChecklistItem>[];

    // 1. Add debt EMIs
    items.addAll(_getDebtItems());

    // 2. Add family debts (money you owe)
    items.addAll(_getFamilyDebtItems());

    // 3. Add subscriptions
    items.addAll(_getSubscriptionItems());

    // 4. Add goal contributions
    items.addAll(_getGoalItems(incomeAmount));

    // 5. Add budget allocations
    items.addAll(_getBudgetItems(incomeAmount));

    // Sort by priority, then by due date
    items.sort((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      if (a.dueDate == null && b.dueDate == null) {
        return 0;
      }
      if (a.dueDate == null) {
        return 1;
      }
      if (b.dueDate == null) {
        return -1;
      }
      return a.dueDate!.compareTo(b.dueDate!);
    });

    // Calculate totals
    final urgentAndHighItems = items.where(
      (i) =>
          i.priority == ChecklistItemPriority.urgent ||
          i.priority == ChecklistItemPriority.high,
    );
    final totalObligations = urgentAndHighItems.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    // Suggest savings (20% of remaining after obligations, or minimum 10% of income)
    final afterObligations = incomeAmount - totalObligations;
    final suggestedSavings = afterObligations > 0
        ? (afterObligations * 0.2).clamp(incomeAmount * 0.1, afterObligations)
        : 0.0;

    return PaydayChecklist(
      incomeAmount: incomeAmount,
      incomeSource: incomeSource,
      incomeDate: date,
      items: items,
      totalObligations: totalObligations,
      suggestedSavings: suggestedSavings,
    );
  }

  /// Get debt EMI items
  List<PaydayChecklistItem> _getDebtItems() {
    if (debtProvider == null) {
      return [];
    }

    final items = <PaydayChecklistItem>[];
    final now = DateTime.now();
    final lookAheadDate = now.add(Duration(days: lookAheadDays));

    for (final debt in debtProvider!.debts) {
      // Skip "owed to me" debts and fully paid debts
      if (debt.type == DebtType.owedToMe || debt.currentBalance <= 0) {
        continue;
      }

      // Skip debts without EMI
      if (debt.monthlyEMI == null || debt.monthlyEMI! <= 0) {
        continue;
      }

      final dueDate = debt.nextPaymentDate;
      if (dueDate == null) {
        continue;
      }

      // Only include if due within look-ahead period
      if (dueDate.isAfter(lookAheadDate)) {
        continue;
      }

      final priority = _getPriorityFromDueDate(dueDate);

      items.add(
        PaydayChecklistItem(
          id: 'debt_${debt.id}',
          type: ChecklistItemType.debtEMI,
          priority: priority,
          title: debt.name,
          subtitle: debt.lenderName ?? _getDebtTypeLabel(debt.type),
          amount: debt.monthlyEMI!,
          dueDate: dueDate,
          metadata: {
            'debtId': debt.id,
            'debtType': debt.type.name,
            'remainingBalance': debt.currentBalance,
            'linkedAccountId': debt.linkedAccountId,
          },
        ),
      );
    }

    return items;
  }

  /// Get family debt items (money you owe others)
  List<PaydayChecklistItem> _getFamilyDebtItems() {
    if (familyDebtProvider == null) {
      return [];
    }

    final items = <PaydayChecklistItem>[];
    final now = DateTime.now();

    // Get debts where user owes money
    for (final debt in familyDebtProvider!.debtsIOweTo) {
      if (debt.isSettled || debt.currentAmount <= 0) {
        continue;
      }

      final dueDate = debt.dueDate;
      ChecklistItemPriority priority;

      if (dueDate != null) {
        priority = _getPriorityFromDueDate(dueDate);
        // Only include if due within look-ahead or overdue
        if (dueDate.isAfter(now.add(Duration(days: lookAheadDays))) &&
            !debt.isOverdue) {
          continue;
        }
      } else {
        // No due date - medium priority as a reminder
        priority = ChecklistItemPriority.medium;
      }

      items.add(
        PaydayChecklistItem(
          id: 'family_debt_${debt.id}',
          type: ChecklistItemType.familyDebt,
          priority: priority,
          title: 'Pay ${debt.creditorName}',
          subtitle: debt.description ?? 'Personal debt',
          amount: debt.currentAmount,
          dueDate: dueDate,
          personName: debt.creditorName,
          metadata: {
            'debtId': debt.id,
            'creditorId': debt.creditorId,
            'originalAmount': debt.originalAmount,
          },
        ),
      );
    }

    return items;
  }

  /// Get subscription items
  List<PaydayChecklistItem> _getSubscriptionItems() {
    if (subscriptionProvider == null) {
      return [];
    }

    final items = <PaydayChecklistItem>[];
    final now = DateTime.now();
    final lookAheadDate = now.add(Duration(days: lookAheadDays));

    for (final sub in subscriptionProvider!.subscriptions) {
      if (!sub.isActive) {
        continue;
      }

      final dueDate = sub.nextDueDate;

      // Only include if due within look-ahead period
      if (dueDate.isAfter(lookAheadDate) && !sub.isOverdue) {
        continue;
      }

      final priority = _getPriorityFromDueDate(dueDate);

      items.add(
        PaydayChecklistItem(
          id: 'sub_${sub.id}',
          type: ChecklistItemType.subscription,
          priority: priority,
          title: sub.name,
          subtitle: '${sub.frequency} subscription',
          amount: sub.amount,
          dueDate: dueDate,
          accountId: sub.accountId,
          metadata: {
            'subscriptionId': sub.id,
            'frequency': sub.frequency,
            'categoryId': sub.categoryId,
          },
        ),
      );
    }

    return items;
  }

  /// Get goal contribution suggestions
  List<PaydayChecklistItem> _getGoalItems(double incomeAmount) {
    if (goalProvider == null) {
      return [];
    }

    final items = <PaydayChecklistItem>[];

    for (final goal in goalProvider!.goals) {
      if (goal.isCompleted) {
        continue;
      }

      // Calculate suggested contribution based on time remaining
      final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
      if (daysRemaining <= 0) continue; // Skip overdue goals for suggestions

      final monthsRemaining = (daysRemaining / 30).ceil().clamp(1, 120);
      final amountNeeded = goal.remainingAmount;
      final suggestedMonthly = amountNeeded / monthsRemaining;

      // Only suggest if meaningful amount (at least 1% of income or ₹500)
      final minSuggestion = (incomeAmount * 0.01).clamp(500, double.infinity);
      if (suggestedMonthly < minSuggestion) {
        continue;
      }

      // Cap suggestion at 20% of income
      final cappedSuggestion = suggestedMonthly
          .clamp(0.0, incomeAmount * 0.2)
          .toDouble();

      items.add(
        PaydayChecklistItem(
          id: 'goal_${goal.id}',
          type: ChecklistItemType.goalContribution,
          priority: ChecklistItemPriority.low,
          title: goal.name,
          subtitle:
              '${goal.progressPercentage.toStringAsFixed(0)}% complete • ${monthsRemaining}mo left',
          amount: cappedSuggestion,
          dueDate: goal.targetDate,
          accountId: goal.linkedAccountId,
          metadata: {
            'goalId': goal.id,
            'targetAmount': goal.targetAmount,
            'currentAmount': goal.currentAmount,
            'remainingAmount': goal.remainingAmount,
          },
        ),
      );
    }

    // Sort by urgency (less time remaining = higher priority)
    items.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return 0;
      }
      if (a.dueDate == null) {
        return 1;
      }
      if (b.dueDate == null) {
        return -1;
      }
      return a.dueDate!.compareTo(b.dueDate!);
    });

    // Limit to top 3 goals
    return items.take(3).toList();
  }

  /// Get budget allocation suggestions
  List<PaydayChecklistItem> _getBudgetItems(double incomeAmount) {
    if (budgetProvider == null) {
      return [];
    }

    final items = <PaydayChecklistItem>[];

    for (final budget in budgetProvider!.budgets) {
      if (!budget.isActive) {
        continue;
      }

      // Check if budget period is current
      final now = DateTime.now();
      if (now.isBefore(budget.startDate) || now.isAfter(budget.endDate)) {
        continue;
      }

      // Calculate remaining budget
      final remaining = budget.remainingAmount;
      if (remaining <= 0) continue; // Already spent

      // Suggest allocation based on remaining budget
      // For monthly budgets, suggest full remaining if early in month
      final daysInPeriod = budget.endDate.difference(budget.startDate).inDays;
      final daysRemaining = budget.endDate.difference(now).inDays;
      final percentRemaining = daysRemaining / daysInPeriod;

      // Only suggest if significant remaining and early in period
      if (percentRemaining < 0.5) {
        continue;
      }

      items.add(
        PaydayChecklistItem(
          id: 'budget_${budget.id}',
          type: ChecklistItemType.budgetAllocation,
          priority: ChecklistItemPriority.low,
          title: budget.categoryName,
          subtitle:
              '₹${remaining.toStringAsFixed(0)} remaining of ₹${budget.allocatedAmount.toStringAsFixed(0)}',
          amount: remaining,
          dueDate: budget.endDate,
          metadata: {
            'budgetId': budget.id,
            'categoryId': budget.categoryId,
            'allocatedAmount': budget.allocatedAmount,
            'spentAmount': budget.spentAmount,
          },
        ),
      );
    }

    return items.take(3).toList();
  }

  /// Get priority based on due date
  ChecklistItemPriority _getPriorityFromDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;

    if (daysUntilDue < 0) return ChecklistItemPriority.urgent; // Overdue
    if (daysUntilDue <= 3) {
      return ChecklistItemPriority.urgent;
    }
    if (daysUntilDue <= 7) {
      return ChecklistItemPriority.high;
    }
    if (daysUntilDue <= 14) {
      return ChecklistItemPriority.medium;
    }
    return ChecklistItemPriority.low;
  }

  /// Get human-readable debt type label
  String _getDebtTypeLabel(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.twoWheelerLoan:
        return 'Two Wheeler Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.owedByMe:
        return 'Personal';
      case DebtType.owedToMe:
        return 'Receivable';
      case DebtType.custom:
        return 'Custom';
      case DebtType.other:
        return 'Other';
    }
  }
}
