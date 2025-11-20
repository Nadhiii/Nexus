import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/models/budget.dart';
import 'widgets/add_budget_modal.dart';
import 'package:intl/intl.dart';

class ModernBudgetsScreen extends StatelessWidget {
  const ModernBudgetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBudgetList(context, budgetProvider.budgets),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudgetModal(BuildContext context, {Budget? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBudgetModal(budget: budget),
    );
  }

  Widget _buildBudgetList(BuildContext context, List<Budget> budgets) {
    if (budgets.isEmpty) {
      return const Center(child: Text('No budgets yet. Add one!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return _buildBudgetCard(context, budget);
      },
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final Color progressColor = budget.isOverspent
        ? colorScheme.error
        : (budget.progress > 0.8 ? colorScheme.tertiary : colorScheme.primary);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () => _showAddBudgetModal(context, budget: budget),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: getCategoryColor(context, budget.categoryId).withOpacity(0.2),
                    child: Icon(Icons.category, color: getCategoryColor(context, budget.categoryId)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      budget.categoryName,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${currencyFormat.format(budget.allocatedAmount)} / month',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: budget.progress,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currencyFormat.format(budget.spentAmount)} spent',
                    style: textTheme.bodySmall,
                  ),
                  Text(
                    '${currencyFormat.format(budget.remainingAmount)} left',
                    style: textTheme.bodySmall?.copyWith(
                      color: budget.isOverspent ? colorScheme.error : colorScheme.onSurfaceVariant,
                      fontWeight: budget.isOverspent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Color getCategoryColor(BuildContext context, String categoryId) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = {
      'food': Colors.red,
      'transport': Colors.blue,
      'shopping': Colors.green,
      'entertainment': Colors.orange,
      'bills': Colors.purple,
      'health': Colors.pink,
      'education': Colors.teal,
      'miscellaneous': colorScheme.onSurface.withOpacity(0.4),
    };
    return colors[categoryId] ?? colorScheme.onSurface.withOpacity(0.4);
  }
}
