import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class CategorySpendingChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CategorySpendingChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenseTransactions =
        transactions.where((tx) => tx.type == TransactionType.expense).toList();

    final Map<String, double> categoryTotals = {};
    double totalSpent = 0;

    for (var tx in expenseTransactions) {
      final category = tx.categoryId ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + tx.amount;
      totalSpent += tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color:
          Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    "Spending by Category",
                    style: AppTypography.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (totalSpent == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    "No expenses for this period.",
                    style: AppTypography.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              ...sortedEntries.map((e) {
                final percentage = e.value / totalSpent;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key.toUpperCase(),
                              style: AppTypography.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            "${(percentage * 100).toStringAsFixed(1)}%",
                            style: AppTypography.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        color: _getColorForIndex(sortedEntries.indexOf(e), context),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${e.value.toStringAsFixed(2)}",
                        style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index, BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final opacity = (1.0 - (index * 0.1)).clamp(0.3, 1.0);
    return primary.withOpacity(opacity);
  }
}
