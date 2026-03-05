import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/transaction_display.dart';

class CategorySpendingChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CategorySpendingChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final expenseTransactions = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final Map<String, double> categoryTotals = {};
    double totalSpent = 0;

    for (var tx in expenseTransactions) {
      final category = resolveTransactionDisplayLabel(
        tx,
        categories,
        emptyLabel: 'Uncategorized',
      );
      categoryTotals[category] = (categoryTotals[category] ?? 0) + tx.amount;
      totalSpent += tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (totalSpent == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            "No expenses recorded",
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: sortedEntries.take(5).map((e) {
          final percentage = e.value / totalSpent;
          // Dynamic color based on intensity
          final barColor = AppColors.primaryBlue.withValues(alpha: 
            0.4 + (percentage * 0.6),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${(percentage * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${e.value.toStringAsFixed(0)}",
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
