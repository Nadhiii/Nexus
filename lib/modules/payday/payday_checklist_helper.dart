import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction.dart';
import '../../core/models/payday_checklist.dart';
import '../../core/services/payday_checklist_service.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/goal_provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/providers/family_debt_provider.dart';
import 'payday_checklist_sheet.dart';

/// Helper to trigger payday checklist when income is added
class PaydayChecklistHelper {
  /// Minimum income amount to trigger checklist
  static const double minimumIncomeThreshold = 5000;

  /// Check if a transaction should trigger the payday checklist
  static bool shouldTrigger(Transaction transaction) {
    // Only for income transactions
    if (transaction.type != TransactionType.income) return false;

    // Check amount threshold
    if (transaction.amount < minimumIncomeThreshold) return false;

    return true;
  }

  /// Check if income category should trigger (e.g., salary)
  static bool isSalaryCategory(String? categoryId) {
    if (categoryId == null) return false;
    final lower = categoryId.toLowerCase();
    return lower == 'salary' ||
        lower == 'income' ||
        lower == 'freelance' ||
        lower == 'bonus';
  }

  /// Show the payday checklist if appropriate
  static Future<void> checkAndShowChecklist(
    BuildContext context, {
    required Transaction transaction,
    VoidCallback? onItemTap,
  }) async {
    // Only for income
    if (transaction.type != TransactionType.income) return;

    // Check if should trigger
    final isSalary = isSalaryCategory(transaction.categoryId);
    final isSignificantAmount = transaction.amount >= minimumIncomeThreshold;

    if (!isSalary && !isSignificantAmount) return;

    // Build the service with available providers
    final service = PaydayChecklistService(
      debtProvider: _tryGetProvider<DebtProvider>(context),
      subscriptionProvider: _tryGetProvider<SubscriptionProvider>(context),
      goalProvider: _tryGetProvider<GoalProvider>(context),
      budgetProvider: _tryGetProvider<BudgetProvider>(context),
      familyDebtProvider: _tryGetProvider<FamilyDebtProvider>(context),
      minimumIncomeThreshold: minimumIncomeThreshold,
    );

    // Generate checklist
    final checklist = service.generateChecklist(
      incomeAmount: transaction.amount,
      incomeSource: transaction.description ?? transaction.categoryId,
      incomeDate: transaction.date,
    );

    // Only show if there are items
    if (checklist.items.isEmpty) return;

    // Small delay to let the transaction screen close
    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      await PaydayChecklistSheet.show(
        context,
        checklist: checklist,
        onItemTap: onItemTap != null
            ? (_) => onItemTap()
            : (item) => _handleItemTap(context, item),
      );
    }
  }

  /// Try to get a provider, return null if not available
  static T? _tryGetProvider<T>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } catch (e) {
      return null;
    }
  }

  /// Handle tapping on a checklist item
  static void _handleItemTap(BuildContext context, PaydayChecklistItem item) {
    // For now, just log the tap
    // In the future, this could navigate to the relevant screen
    debugPrint('Tapped checklist item: ${item.title} (${item.type})');

    // Could navigate based on type:
    // - debtEMI -> debt detail screen
    // - familyDebt -> family debt screen
    // - subscription -> subscription screen
    // - goalContribution -> goal detail screen
    // - budgetAllocation -> budget screen
  }

  /// Generate checklist without showing (for preview/testing)
  static PaydayChecklist? generateChecklist(
    BuildContext context, {
    required double incomeAmount,
    String? incomeSource,
  }) {
    final service = PaydayChecklistService(
      debtProvider: _tryGetProvider<DebtProvider>(context),
      subscriptionProvider: _tryGetProvider<SubscriptionProvider>(context),
      goalProvider: _tryGetProvider<GoalProvider>(context),
      budgetProvider: _tryGetProvider<BudgetProvider>(context),
      familyDebtProvider: _tryGetProvider<FamilyDebtProvider>(context),
    );

    return service.generateChecklist(
      incomeAmount: incomeAmount,
      incomeSource: incomeSource,
    );
  }
}
