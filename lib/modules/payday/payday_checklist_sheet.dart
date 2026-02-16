import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/payday_checklist.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';

/// Bottom sheet to display payday checklist
/// Shows actionable items after receiving income
class PaydayChecklistSheet extends StatefulWidget {
  final PaydayChecklist checklist;
  final VoidCallback? onDismiss;
  final Function(PaydayChecklistItem item)? onItemTap;

  const PaydayChecklistSheet({
    super.key,
    required this.checklist,
    this.onDismiss,
    this.onItemTap,
  });

  /// Show the payday checklist as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required PaydayChecklist checklist,
    Function(PaydayChecklistItem item)? onItemTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaydayChecklistSheet(
        checklist: checklist,
        onItemTap: onItemTap,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<PaydayChecklistSheet> createState() => _PaydayChecklistSheetState();
}

class _PaydayChecklistSheetState extends State<PaydayChecklistSheet> {
  final Set<String> _completedItems = {};

  @override
  Widget build(BuildContext context) {
    final checklist = widget.checklist;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              _buildDragHandle(),

              // Header
              _buildHeader(checklist),

              // Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    final mediumItems = checklist.getByPriority(
                      ChecklistItemPriority.medium,
                    );
                    final suggestedItems = checklist.getByPriority(
                      ChecklistItemPriority.low,
                    );

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        // Summary Card
                        _buildSummaryCard(checklist),
                        const SizedBox(height: 24),

                        // Urgent Items
                        if (checklist.urgentItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Urgent',
                            Icons.warning_amber_rounded,
                            AppColors.error,
                            checklist.urgentItems.length,
                          ),
                          const SizedBox(height: 12),
                          ...checklist.urgentItems.map(_buildChecklistItem),
                          const SizedBox(height: 20),
                        ],

                        // High Priority Items
                        if (checklist.highPriorityItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Due Soon',
                            Icons.schedule,
                            AppColors.warning,
                            checklist.highPriorityItems.length,
                          ),
                          const SizedBox(height: 12),
                          ...checklist.highPriorityItems.map(
                            _buildChecklistItem,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Medium Priority Items
                        if (mediumItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Coming Up',
                            Icons.event,
                            AppColors.primaryBlue,
                            mediumItems.length,
                          ),
                          const SizedBox(height: 12),
                          ...mediumItems.map(_buildChecklistItem),
                          const SizedBox(height: 20),
                        ],

                        // Suggested Items (Goals & Budgets)
                        if (suggestedItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Suggested',
                            Icons.lightbulb_outline,
                            AppColors.success,
                            suggestedItems.length,
                          ),
                          const SizedBox(height: 12),
                          ...suggestedItems.map(_buildChecklistItem),
                          const SizedBox(height: 20),
                        ],

                        // Empty State
                        if (checklist.items.isEmpty) _buildEmptyState(),

                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),

              // Bottom Action
              _buildBottomAction(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(PaydayChecklist checklist) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.celebration, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payday!',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${NumberFormat.compact().format(checklist.incomeAmount)} received${checklist.incomeSource != null ? ' • ${checklist.incomeSource}' : ''}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Close Button
          IconButton(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PaydayChecklist checklist) {
    final canCover = checklist.canCoverObligations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canCover
              ? [
                  AppColors.success.withValues(alpha: 0.15),
                  AppColors.success.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canCover
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Main Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Income',
                  '₹${NumberFormat.compact().format(checklist.incomeAmount)}',
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  'Obligations',
                  '₹${NumberFormat.compact().format(checklist.totalObligations)}',
                  AppColors.warning,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  'Remaining',
                  '₹${NumberFormat.compact().format(checklist.remainingAfterObligations)}',
                  canCover ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (checklist.obligationPercentage / 100).clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                checklist.obligationPercentage > 80
                    ? AppColors.error
                    : checklist.obligationPercentage > 50
                    ? AppColors.warning
                    : AppColors.success,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${checklist.obligationPercentage.toStringAsFixed(0)}% of income goes to pending obligations',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(PaydayChecklistItem item) {
    final isCompleted = _completedItems.contains(item.id);

    return GestureDetector(
      onTap: () {
        if (widget.onItemTap != null) {
          widget.onItemTap!(item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : _getBorderColor(item.priority),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => _toggleItem(item.id),
              child: AnimatedContainer(
                duration: AppAnimations.standard,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.textTertiary,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(item.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(item.type),
                color: _getTypeColor(item.type),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isCompleted
                          ? AppColors.textTertiary
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (item.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          item.isOverdue ? Icons.warning : Icons.schedule,
                          size: 12,
                          color: item.isOverdue
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.dueStatus,
                          style: AppTypography.bodySmall.copyWith(
                            color: item.isOverdue
                                ? AppColors.error
                                : AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Text(
              '₹${NumberFormat.compact().format(item.amount)}',
              style: AppTypography.labelLarge.copyWith(
                color: isCompleted ? AppColors.textTertiary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending obligations right now.\nEnjoy your payday!',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final completedCount = _completedItems.length;
    final totalCount = widget.checklist.items.length;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completedCount of $totalCount done',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Done Button
          ElevatedButton(
            onPressed: widget.onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_completedItems.contains(itemId)) {
        _completedItems.remove(itemId);
      } else {
        _completedItems.add(itemId);
      }
    });
  }

  Color _getBorderColor(ChecklistItemPriority priority) {
    switch (priority) {
      case ChecklistItemPriority.urgent:
        return AppColors.error.withValues(alpha: 0.3);
      case ChecklistItemPriority.high:
        return AppColors.warning.withValues(alpha: 0.3);
      case ChecklistItemPriority.medium:
        return AppColors.primaryBlue.withValues(alpha: 0.3);
      case ChecklistItemPriority.low:
        return Colors.white.withValues(alpha: 0.1);
    }
  }

  Color _getTypeColor(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.debtEMI:
        return AppColors.error;
      case ChecklistItemType.familyDebt:
        return Colors.purple;
      case ChecklistItemType.subscription:
        return AppColors.accentOrange;
      case ChecklistItemType.budgetAllocation:
        return Colors.teal;
      case ChecklistItemType.goalContribution:
        return AppColors.primaryBlue;
      case ChecklistItemType.savingsTransfer:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.debtEMI:
        return Icons.credit_card;
      case ChecklistItemType.familyDebt:
        return Icons.people;
      case ChecklistItemType.subscription:
        return Icons.autorenew;
      case ChecklistItemType.budgetAllocation:
        return Icons.pie_chart;
      case ChecklistItemType.goalContribution:
        return Icons.flag;
      case ChecklistItemType.savingsTransfer:
        return Icons.savings;
    }
  }
}
