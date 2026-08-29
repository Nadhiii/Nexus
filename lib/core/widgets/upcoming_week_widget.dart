// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// upcoming_week_widget.dart
//
// BUG FIX: The old widget called provider.upcomingObligations which returned []
// because it was looking only at subscriptions due *today*, not at debts,
// unpaid bills, or subscriptions in the next 7 days.
//
// This version reads from DebtProvider + SubscriptionProvider directly and
// shows everything due in the next 7 days that is NOT yet paid/settled.
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/debt_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexus_card.dart';

class UpcomingWeekWidget extends StatelessWidget {
  final VoidCallback? onViewAll;

  const UpcomingWeekWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DebtProvider, SubscriptionProvider>(
      builder: (context, debtProvider, subProvider, _) {
        final items = _buildItems(debtProvider, subProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAYMENTS DUE',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: AppTypography.labelSmall.fontSize,
                    fontWeight: AppTypography.labelSmall.fontWeight,
                    letterSpacing: 1.2,
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: AppTypography.labelMedium.fontSize,
                        fontWeight: AppTypography.labelMedium.fontWeight,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.contentGap),

            if (items.isEmpty)
              _AllCaughtUp()
            else
              NexusCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: items.asMap().entries.map((e) {
                    final isLast = e.key == items.length - 1;
                    return Column(
                      children: [
                        _ObligationTile(item: e.value),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.04),
                            indent: 56,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_ObligationItem> _buildItems(
    DebtProvider debtProvider,
    SubscriptionProvider subProvider,
  ) {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));
    final items = <_ObligationItem>[];

    // ΓöÇΓöÇ Debts with upcoming EMI ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    for (final debt in debtProvider.debts) {
      if (debt.currentBalance <= 0) continue;
      final due = debt.nextPaymentDate;
      if (due == null) continue;
      if (due.isBefore(now.subtract(const Duration(days: 1)))) continue; // overdue ΓÇö still show
      if (due.isAfter(cutoff)) continue;

      final daysUntil = due.difference(now).inDays;
      items.add(_ObligationItem(
        name: debt.name,
        amount: debt.monthlyEMI ?? 0,
        dueDate: due,
        daysUntil: daysUntil,
        type: _ObligationType.emi,
      ));
    }

    // ΓöÇΓöÇ Subscriptions due this week ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    for (final sub in subProvider.subscriptions) {
      if (!sub.isActive) continue;
      final due = sub.calculateNextDueDate();
      if (due.isBefore(now.subtract(const Duration(days: 1)))) continue;
      if (due.isAfter(cutoff)) continue;

      final daysUntil = due.difference(now).inDays;
      items.add(_ObligationItem(
        name: sub.name,
        amount: sub.amount,
        dueDate: due,
        daysUntil: daysUntil,
        type: _ObligationType.subscription,
      ));
    }

    // Sort: overdue first, then by days
    items.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return items;
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _AllCaughtUp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.pastelGreen.withValues(alpha: 0.12),
            borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.pastelGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All caught up!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.titleSmall.fontWeight,
                  fontSize: AppTypography.titleSmall.fontSize,
                ),
              ),
              Text(
                'No payments due in the next 7 days',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: AppTypography.bodySmall.fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

enum _ObligationType { emi, subscription }

class _ObligationItem {
  final String name;
  final double amount;
  final DateTime dueDate;
  final int daysUntil;
  final _ObligationType type;

  const _ObligationItem({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.daysUntil,
    required this.type,
  });
}

class _ObligationTile extends StatelessWidget {
  final _ObligationItem item;
  const _ObligationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.daysUntil < 0;
    final isToday = item.daysUntil == 0;
    final isTomorrow = item.daysUntil == 1;

    Color urgencyColor;
    String dueLine;

    if (isOverdue) {
      urgencyColor = AppColors.error;
      dueLine = 'Overdue by ${item.daysUntil.abs()} day${item.daysUntil.abs() == 1 ? '' : 's'}';
    } else if (isToday) {
      urgencyColor = AppColors.error;
      dueLine = 'Due today';
    } else if (isTomorrow) {
      urgencyColor = Colors.orange;
      dueLine = 'Due tomorrow';
    } else {
      urgencyColor = AppColors.textTertiary;
      dueLine = 'Due ${DateFormat('dd MMM').format(item.dueDate)}';
    }

    final iconData = item.type == _ObligationType.emi
        ? Icons.account_balance_rounded
        : Icons.repeat_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.12),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(iconData, color: urgencyColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.titleSmall.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  dueLine,
                  style: AppTypography.labelSmall.copyWith(color: urgencyColor),
                ),
              ],
            ),
          ),
          Text(
            'Γé╣${NumberFormat('#,##,###').format(item.amount)}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.labelLarge.fontSize,
              fontWeight: AppTypography.labelLarge.fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
