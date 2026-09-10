import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/budget.dart';
import '../../../core/models/goal.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/models/transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../budgets/budgets_screen.dart';
import '../../goals/goals_screen.dart';

/// Home pulse: this-month cash flow, top budgets, and active goals.
class HomeMoneyPulse extends StatelessWidget {
  const HomeMoneyPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MonthPulseCard(),
        const SizedBox(height: AppSpacing.lg),
        const _BudgetsPulseCard(),
        const SizedBox(height: AppSpacing.lg),
        const _GoalsPulseCard(),
      ],
    );
  }
}

class _MonthPulseCard extends StatelessWidget {
  const _MonthPulseCard();

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, BudgetProvider>(
      builder: (context, tx, budgets, _) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final monthTx = tx.transactions.where((t) => !t.date.isBefore(start));
        final income = monthTx
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (s, t) => s + t.amount);
        final expense = monthTx
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (s, t) => s + t.amount);
        final net = income - expense;
        final adherence = budgets.activeBudgets.isEmpty || budgets.totalAllocated <= 0
            ? null
            : (budgets.totalSpent / budgets.totalAllocated);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS MONTH',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Income',
                      value: _inr(income),
                      color: AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Spent',
                      value: _inr(expense),
                      color: AppColors.error,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Net',
                      value: _inr(net),
                      color: net >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              if (adherence != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      'Budget used',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(adherence * 100).clamp(0, 999).toStringAsFixed(0)}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: adherence > 1
                            ? AppColors.error
                            : (adherence >= 0.8
                                ? AppColors.accentOrange
                                : AppColors.success),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: adherence.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: adherence > 1
                        ? AppColors.error
                        : (adherence >= 0.8
                            ? AppColors.accentOrange
                            : AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BudgetsPulseCard extends StatelessWidget {
  const _BudgetsPulseCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final budgets = provider.activeBudgets.toList()
          ..sort((a, b) => b.spentPercentage.compareTo(a.spentPercentage));
        final top = budgets.take(3).toList();

        return _SectionCard(
          title: 'BUDGETS',
          actionLabel: 'View all',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ModernBudgetsScreen()),
          ),
          child: top.isEmpty
              ? _EmptyHint(
                  message: 'No active budgets yet',
                  cta: 'Create a budget',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ModernBudgetsScreen(),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < top.length; i++) ...[
                      _BudgetRow(budget: top[i]),
                      if (i < top.length - 1)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _GoalsPulseCard extends StatelessWidget {
  const _GoalsPulseCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, provider, _) {
        final goals = provider.goals
            .where((g) => !g.isCompleted)
            .toList()
          ..sort(
            (a, b) => b.progressPercentage.compareTo(a.progressPercentage),
          );
        final top = goals.take(2).toList();

        return _SectionCard(
          title: 'GOALS',
          actionLabel: 'View all',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ModernGoalsScreen()),
          ),
          child: top.isEmpty
              ? _EmptyHint(
                  message: 'No savings goals yet',
                  cta: 'Add a goal',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ModernGoalsScreen(),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < top.length; i++) ...[
                      _GoalRow(goal: top[i]),
                      if (i < top.length - 1)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.contentGap),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Budget budget;
  const _BudgetRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    final color = budget.isOverspent
        ? AppColors.error
        : (budget.isNearLimit ? AppColors.accentOrange : AppColors.pastelTeal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budget.categoryName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_inr(budget.spentAmount)} / ${_inr(budget.allocatedAmount)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: budget.progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            budget.statusDescription,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal;
  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.pastelPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: AppColors.pastelPink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_inr(goal.currentAmount)} of ${_inr(goal.targetAmount)}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final String cta;
  final VoidCallback onTap;

  const _EmptyHint({
    required this.message,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              cta,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _inr(double amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 10000000) {
    return '$sign₹${(abs / 10000000).toStringAsFixed(1)}Cr';
  }
  if (abs >= 100000) {
    return '$sign₹${(abs / 100000).toStringAsFixed(1)}L';
  }
  if (abs >= 1000) {
    return '$sign₹${NumberFormat('#,##,###').format(abs.round())}';
  }
  return '$sign₹${abs.toStringAsFixed(0)}';
}
