import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class TransactionAnalysisSummary extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionAnalysisSummary({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;
    int expenseCount = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        expenseCount++;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final avgExpense = expenseCount > 0 ? totalExpense / expenseCount : 0.0;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                Icon(Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    "Cash Flow Analysis",
                    style: AppTypography.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildRow(context, "Total Income", totalIncome, isPositive: true),
            const Divider(height: AppSpacing.xl),
            _buildRow(context, "Total Expense", totalExpense, isNegative: true),
            const Divider(height: AppSpacing.xl),
            _buildRow(context, "Net Savings", netSavings, isPositive: netSavings >= 0, isNegative: netSavings < 0),
            const Divider(height: AppSpacing.xl),
            _buildRow(context, "Avg. Expense Size", avgExpense),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, double value, {bool isPositive = false, bool isNegative = false}) {
    Color valueColor = Theme.of(context).colorScheme.onSurface;
    if (isPositive) valueColor = Colors.green; // Or use a custom success color from your theme
    if (isNegative) valueColor = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.lg), // Add spacing
          Text(
            "₹${value.abs().toStringAsFixed(2)}",
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
