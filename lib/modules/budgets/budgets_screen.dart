import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/models/budget.dart';
import '../../core/widgets/apple_floating_action_button.dart';
import 'widgets/add_budget_modal.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.budgets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.budgets.isEmpty) {
            return _buildEmptyState(context, provider);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildOverviewCard(provider)),
              SliverToBoxAdapter(child: _buildQuickActions(context, provider)),
              SliverToBoxAdapter(child: _buildStatusSummary(provider)),
              SliverToBoxAdapter(child: _buildBudgetChart(provider)),
              ..._buildCategorizedBudgets(provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: AppleFloatingActionButton(
        heroTag: 'fab-budgets',
        onPressed: () => _showBudgetOptions(context),
      ),
    );
  }

  void _showBudgetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Create Budget',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          context,
                          'Quick Setup',
                          'Create multiple budgets using proven methods',
                          Icons.auto_awesome,
                          Colors.blue,
                          () {
                            Navigator.pop(context);
                            showQuickSetupModal(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionButton(
                          context,
                          'Add Budget',
                          'Create a custom budget category',
                          Icons.add_circle_outline,
                          Colors.green,
                          () {
                            Navigator.pop(context);
                            showAddBudgetModal(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, BudgetProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to track\nyour spending categories',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showQuickSetupModal(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Quick Setup'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showAddBudgetModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BudgetProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(provider.overallProgress * 100).toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider.formattedTotalSpent,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'of ${provider.formattedTotalAllocated} allocated',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: provider.overallProgress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              provider.overallProgress > 1.0
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${provider.formattedTotalRemaining} remaining',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, BudgetProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              'Quick Setup',
              Icons.auto_awesome,
              Colors.blue,
              () => showQuickSetupModal(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              'Add Budget',
              Icons.add,
              Colors.green,
              () => showAddBudgetModal(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              'Analytics',
              Icons.analytics,
              Colors.purple,
              () => _showBudgetAnalytics(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(BudgetProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'On Track',
                  provider.onTrackCount.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Near Limit',
                  provider.nearLimitCount.toString(),
                  Colors.orange,
                  Icons.warning,
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Over Budget',
                  provider.overBudgetCount.toString(),
                  Colors.red,
                  Icons.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBudgetChart(BudgetProvider provider) {
    if (provider.budgets.isEmpty) return const SizedBox.shrink();

    // Sort budgets by allocated amount for better visualization
    final sortedBudgets = List<Budget>.from(provider.budgets)
      ..sort((a, b) => b.allocatedAmount.compareTo(a.allocatedAmount));

    final displayBudgets = sortedBudgets.take(6).toList();
    final maxAmount = displayBudgets.isNotEmpty
        ? displayBudgets.first.allocatedAmount
        : 1.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Budget Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${provider.totalAllocated.toStringAsFixed(0)} total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayBudgets.map((budget) {
            final color = _getCategoryColor(budget.categoryId);
            final percentage = provider.totalAllocated > 0
                ? (budget.allocatedAmount / provider.totalAllocated * 100)
                : 0.0;
            final barWidth = maxAmount > 0
                ? (budget.allocatedAmount / maxAmount)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${budget.allocatedAmount.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: barWidth.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (sortedBudgets.length > 6) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${sortedBudgets.length - 6} more categories',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedBudgets(BudgetProvider provider) {
    final categories = {
      'Essential': ['housing', 'food', 'transportation', 'health'],
      'Financial': ['savings', 'investments'],
      'Lifestyle': ['entertainment', 'shopping', 'personal'],
      'Other': ['education', 'miscellaneous', 'custom'],
    };

    List<Widget> widgets = [];

    for (final entry in categories.entries) {
      final categoryName = entry.key;
      final categoryIds = entry.value;

      final categoryBudgets = provider.budgets
          .where((budget) => categoryIds.contains(budget.categoryId))
          .toList();

      if (categoryBudgets.isNotEmpty) {
        // Add category header
        widgets.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getCategoryGroupColor(categoryName),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getCategoryGroupColor(categoryName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryGroupColor(
                        categoryName,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryBudgets.length}',
                      style: TextStyle(
                        color: _getCategoryGroupColor(categoryName),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Add budgets for this category
        widgets.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final budget = categoryBudgets[index];
              return _buildBudgetCard(budget, provider);
            }, childCount: categoryBudgets.length),
          ),
        );
      }
    }

    return widgets;
  }

  Color _getCategoryGroupColor(String groupName) {
    switch (groupName) {
      case 'Essential':
        return Colors.blue;
      case 'Financial':
        return Colors.green;
      case 'Lifestyle':
        return Colors.purple;
      case 'Other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBudgetCard(Budget budget, BudgetProvider provider) {
    final progressColor = budget.isOverspent
        ? Colors.red
        : budget.isNearLimit
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(budget.id),
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Edit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _editBudget(context, budget, provider);
            return false;
          } else {
            return await _confirmDeleteBudget(context, budget);
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteBudget(context, budget, provider);
          }
        },
        child: Card(
          elevation: 2,
          shadowColor: _getCategoryColor(budget.categoryId).withOpacity(0.3),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getCategoryColor(budget.categoryId).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showBudgetDetails(context, budget, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(budget.categoryId).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            budget.categoryId,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(budget.categoryId),
                          color: _getCategoryColor(budget.categoryId),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.categoryName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${budget.spentAmount.toStringAsFixed(2)} of ₹${budget.allocatedAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: progressColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              budget.statusDescription,
                              style: TextStyle(
                                color: progressColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(budget.spentPercentage * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: budget.spentPercentage.clamp(0.0, 1.0),
                    backgroundColor: progressColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ₹${budget.remainingAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (budget.daysRemaining > 0)
                        Text(
                          '${budget.daysRemaining} days left',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final colors = {
      'housing': Colors.blue,
      'food': Colors.green,
      'transportation': Colors.orange,
      'savings': Colors.purple,
      'investments': Colors.teal,
      'entertainment': Colors.pink,
      'shopping': Colors.red,
      'health': Colors.cyan,
      'personal': Colors.amber,
      'education': Colors.indigo,
      'miscellaneous': Colors.grey,
    };
    return colors[categoryId] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String categoryId) {
    final icons = {
      'housing': Icons.home,
      'food': Icons.restaurant,
      'transportation': Icons.directions_car,
      'savings': Icons.savings,
      'investments': Icons.trending_up,
      'entertainment': Icons.movie,
      'shopping': Icons.shopping_bag,
      'health': Icons.local_hospital,
      'personal': Icons.face,
      'education': Icons.school,
      'miscellaneous': Icons.more_horiz,
    };
    return icons[categoryId] ?? Icons.category;
  }

  void _editBudget(
    BuildContext context,
    Budget budget,
    BudgetProvider provider,
  ) {
    // TODO: Implement budget editing - for now show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget editing coming soon!')),
    );
  }

  Future<bool> _confirmDeleteBudget(BuildContext context, Budget budget) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Budget'),
            content: Text(
              'Are you sure you want to delete the "${budget.categoryName}" budget? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteBudget(
    BuildContext context,
    Budget budget,
    BudgetProvider provider,
  ) async {
    try {
      await provider.deleteBudget(budget.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${budget.categoryName} budget deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBudgetDetails(
    BuildContext context,
    Budget budget,
    BudgetProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    budget.categoryName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _BudgetDetailsView(budget: budget, provider: provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    'Budget Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _BudgetAnalyticsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Additional form widgets would be implemented here
class _AddBudgetForm extends StatefulWidget {
  const _AddBudgetForm();

  @override
  State<_AddBudgetForm> createState() => _AddBudgetFormState();
}

class _AddBudgetFormState extends State<_AddBudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _allocatedAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategoryId = 'miscellaneous';
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  bool _isLoading = false;

  final List<Map<String, dynamic>> _predefinedCategories = [
    {
      'id': 'housing',
      'name': 'Housing & Utilities',
      'icon': Icons.home,
      'color': Colors.blue,
    },
    {
      'id': 'food',
      'name': 'Food & Groceries',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'id': 'transportation',
      'name': 'Transportation',
      'icon': Icons.directions_car,
      'color': Colors.orange,
    },
    {
      'id': 'savings',
      'name': 'Savings',
      'icon': Icons.savings,
      'color': Colors.purple,
    },
    {
      'id': 'investments',
      'name': 'Investments',
      'icon': Icons.trending_up,
      'color': Colors.teal,
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Colors.pink,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.red,
    },
    {
      'id': 'health',
      'name': 'Health & Insurance',
      'icon': Icons.local_hospital,
      'color': Colors.cyan,
    },
    {
      'id': 'personal',
      'name': 'Personal Care',
      'icon': Icons.face,
      'color': Colors.amber,
    },
    {
      'id': 'education',
      'name': 'Education',
      'icon': Icons.school,
      'color': Colors.indigo,
    },
    {
      'id': 'miscellaneous',
      'name': 'Miscellaneous',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  final List<Map<String, String>> _periodOptions = [
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
    {'value': 'custom', 'label': 'Custom Period'},
  ];

  @override
  void initState() {
    super.initState();
    _updateCategoryName();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _allocatedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCategoryName() {
    final selectedCategory = _predefinedCategories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Custom Category'},
    );
    _categoryNameController.text = selectedCategory['name'];
  }

  void _updatePeriodDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'weekly':
        _startDate = now;
        _endDate = now.add(const Duration(days: 7));
        break;
      case 'monthly':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'yearly':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year + 1, 1, 0);
        break;
      case 'custom':
        // Keep current dates for custom period
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selection
            Text(
              'Budget Category',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _predefinedCategories.length,
                      itemBuilder: (context, index) {
                        final category = _predefinedCategories[index];
                        final isSelected =
                            category['id'] == _selectedCategoryId;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category['id'];
                              _updateCategoryName();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (category['color'] as Color).withOpacity(
                                      0.2,
                                    )
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: category['color'] as Color,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category['icon'] as IconData,
                                  color: isSelected
                                      ? category['color'] as Color
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (category['name'] as String).split(' ').first,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 10,
                                        color: isSelected
                                            ? category['color'] as Color
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Name
            Text(
              'Category Name',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryNameController,
              decoration: InputDecoration(
                hintText: 'Enter category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Allocated Amount
            Text(
              'Budget Amount',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _allocatedAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter budget amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter budget amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Period Selection
            Text(
              'Budget Period',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              items: _periodOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _updatePeriodDates();
                });
              },
            ),
            const SizedBox(height: 24),

            // Date Range (for custom period)
            if (_selectedPeriod == 'custom') ...[
              Text(
                'Custom Period',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectStartDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEndDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'End: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Notes (Optional)
            Text(
              'Notes (Optional)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes about this budget...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 32),

            // Create Budget Button
            FilledButton(
              onPressed: _isLoading ? null : _createBudget,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Budget'),
            ),

            // Add some bottom padding to ensure button is always visible
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final budget = Budget(
        id: '', // Will be generated by service
        categoryId: _selectedCategoryId,
        categoryName: _categoryNameController.text.trim(),
        allocatedAmount: double.parse(_allocatedAmountController.text),
        spentAmount: 0.0,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        accountId: 'default', // Will be updated by service if needed
        isActive: true,
        metadata: _notesController.text.trim().isNotEmpty
            ? {'notes': _notesController.text.trim()}
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.createBudget(budget);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _QuickSetupForm extends StatefulWidget {
  final BudgetProvider provider;

  const _QuickSetupForm({required this.provider});

  @override
  State<_QuickSetupForm> createState() => _QuickSetupFormState();
}

class _QuickSetupFormState extends State<_QuickSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyIncomeController = TextEditingController();

  String _selectedBudgetRule = '50-30-20';
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _budgetRules = {
    '50-30-20': {
      'name': '50/30/20 Rule',
      'description': 'Popular budgeting method',
      'categories': {
        'housing': {'percentage': 30, 'name': 'Housing & Utilities'},
        'food': {'percentage': 15, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 5, 'name': 'Transportation'},
        'savings': {'percentage': 20, 'name': 'Savings'},
        'entertainment': {'percentage': 15, 'name': 'Entertainment'},
        'personal': {'percentage': 10, 'name': 'Personal Care'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
    'zero-based': {
      'name': 'Zero-Based Budget',
      'description': 'Every rupee has a purpose',
      'categories': {
        'housing': {'percentage': 25, 'name': 'Housing & Utilities'},
        'food': {'percentage': 15, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 15, 'name': 'Transportation'},
        'savings': {'percentage': 20, 'name': 'Savings'},
        'investments': {'percentage': 10, 'name': 'Investments'},
        'entertainment': {'percentage': 10, 'name': 'Entertainment'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
    'essentials-first': {
      'name': 'Essentials First',
      'description': 'Priority on needs over wants',
      'categories': {
        'housing': {'percentage': 35, 'name': 'Housing & Utilities'},
        'food': {'percentage': 20, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 15, 'name': 'Transportation'},
        'savings': {'percentage': 15, 'name': 'Savings'},
        'health': {'percentage': 10, 'name': 'Health & Insurance'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
  };

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Budget Setup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create multiple budgets based on proven methods',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monthly Income Input
            Text(
              'Monthly Income',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _monthlyIncomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your monthly income',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your monthly income';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Budget Method Selection
            Text(
              'Choose Budget Method',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ..._budgetRules.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedBudgetRule,
                  onChanged: (value) {
                    setState(() {
                      _selectedBudgetRule = value!;
                    });
                  },
                  title: Text(
                    entry.value['name'],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    entry.value['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Create Budgets Button
            FilledButton(
              onPressed: _isLoading ? null : _createBudgets,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Budgets'),
            ),

            // Add some bottom padding to ensure button is always visible
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _createBudgets() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final monthlyIncome = double.parse(_monthlyIncomeController.text);
      final selectedRule = _budgetRules[_selectedBudgetRule]!;
      final categories = selectedRule['categories'] as Map<String, dynamic>;

      // Create budgets for each category
      for (final entry in categories.entries) {
        final categoryId = entry.key;
        final categoryData = entry.value as Map<String, dynamic>;
        final percentage = categoryData['percentage'] as int;
        final categoryName = categoryData['name'] as String;

        final allocatedAmount = (monthlyIncome * percentage) / 100;

        final budget = Budget(
          id: '', // Will be generated by service
          categoryId: categoryId,
          categoryName: categoryName,
          allocatedAmount: allocatedAmount,
          spentAmount: 0.0,
          period: 'monthly',
          startDate: DateTime.now(),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
          accountId: 'default', // Will be updated by service if needed
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await widget.provider.createBudget(budget);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${categories.length} budgets created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _BudgetDetailsView extends StatelessWidget {
  final Budget budget;
  final BudgetProvider provider;

  const _BudgetDetailsView({required this.budget, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with category icon and name
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(budget.categoryId),
                  _getCategoryColor(budget.categoryId).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  _getCategoryIcon(budget.categoryId),
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  budget.categoryName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${budget.spentAmount.toStringAsFixed(2)} of ₹${budget.allocatedAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Progress Section
          _buildProgressSection(context),
          const SizedBox(height: 20),

          // Period Information
          _buildPeriodSection(context),
          const SizedBox(height: 20),

          // Status and Actions
          _buildStatusSection(context),
          const SizedBox(height: 20),

          // Spending Trend (if available)
          if (budget.metadata?['spending_trend'] != null)
            _buildSpendingTrendSection(context),

          // Notes
          if (budget.metadata?['notes'] != null) _buildNotesSection(context),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editBudget(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: budget.isActive
                      ? () => _pauseBudget(context)
                      : () => _activateBudget(context),
                  icon: Icon(budget.isActive ? Icons.pause : Icons.play_arrow),
                  label: Text(budget.isActive ? 'Pause' : 'Activate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progressColor = budget.isOverspent
        ? Colors.red
        : budget.isNearLimit
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  budget.statusDescription,
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: budget.spentPercentage.clamp(0.0, 1.0),
            backgroundColor: progressColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ₹${budget.spentAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Remaining: ₹${budget.remainingAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period Type',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      budget.period.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days Remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${budget.daysRemaining} days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${budget.startDate.day}/${budget.startDate.month}/${budget.startDate.year} - ${budget.endDate.day}/${budget.endDate.month}/${budget.endDate.year}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status & Health',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  context,
                  'Budget Status',
                  budget.isActive ? 'Active' : 'Paused',
                  budget.isActive ? Colors.green : Colors.orange,
                  budget.isActive ? Icons.check_circle : Icons.pause_circle,
                ),
              ),
              Expanded(
                child: _buildStatusMetric(
                  context,
                  'Spending Rate',
                  '${(budget.spentPercentage * 100).toStringAsFixed(0)}%',
                  budget.isOverspent ? Colors.red : Colors.blue,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpendingTrendSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trend',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            budget.metadata!['spending_trend'] as String,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            budget.metadata!['notes'] as String,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final colors = {
      'housing': Colors.blue,
      'food': Colors.green,
      'transportation': Colors.orange,
      'savings': Colors.purple,
      'investments': Colors.teal,
      'entertainment': Colors.pink,
      'shopping': Colors.red,
      'health': Colors.cyan,
      'personal': Colors.amber,
      'education': Colors.indigo,
      'miscellaneous': Colors.grey,
    };
    return colors[categoryId] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String categoryId) {
    final icons = {
      'housing': Icons.home,
      'food': Icons.restaurant,
      'transportation': Icons.directions_car,
      'savings': Icons.savings,
      'investments': Icons.trending_up,
      'entertainment': Icons.movie,
      'shopping': Icons.shopping_bag,
      'health': Icons.local_hospital,
      'personal': Icons.face,
      'education': Icons.school,
      'miscellaneous': Icons.more_horiz,
    };
    return icons[categoryId] ?? Icons.category;
  }

  void _editBudget(BuildContext context) {
    // Navigate to edit budget screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit budget functionality coming soon!')),
    );
  }

  void _pauseBudget(BuildContext context) async {
    try {
      final updatedBudget = Budget(
        id: budget.id,
        categoryId: budget.categoryId,
        categoryName: budget.categoryName,
        allocatedAmount: budget.allocatedAmount,
        spentAmount: budget.spentAmount,
        period: budget.period,
        startDate: budget.startDate,
        endDate: budget.endDate,
        accountId: budget.accountId,
        isActive: false,
        metadata: budget.metadata,
        createdAt: budget.createdAt,
        updatedAt: DateTime.now(),
      );

      await provider.updateBudget(updatedBudget);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget paused'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _activateBudget(BuildContext context) async {
    try {
      final updatedBudget = Budget(
        id: budget.id,
        categoryId: budget.categoryId,
        categoryName: budget.categoryName,
        allocatedAmount: budget.allocatedAmount,
        spentAmount: budget.spentAmount,
        period: budget.period,
        startDate: budget.startDate,
        endDate: budget.endDate,
        accountId: budget.accountId,
        isActive: true,
        metadata: budget.metadata,
        createdAt: budget.createdAt,
        updatedAt: DateTime.now(),
      );

      await provider.updateBudget(updatedBudget);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _BudgetAnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.budgets.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No budget data for analytics',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Create some budgets to see analytics',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview Cards
              _buildOverviewCards(context, provider),
              const SizedBox(height: 20),

              // Spending Distribution Chart
              _buildSpendingDistributionChart(context, provider),
              const SizedBox(height: 20),

              // Budget Performance
              _buildBudgetPerformance(context, provider),
              const SizedBox(height: 20),

              // Category Breakdown
              _buildCategoryBreakdown(context, provider),
              const SizedBox(height: 20),

              // Recommendations
              _buildRecommendations(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(BuildContext context, BudgetProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            context,
            'Total Allocated',
            '₹${provider.totalAllocated.toStringAsFixed(0)}',
            Icons.wallet,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            context,
            'Total Spent',
            '₹${provider.totalSpent.toStringAsFixed(0)}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            context,
            'Avg. Usage',
            '${(provider.overallProgress * 100).toStringAsFixed(0)}%',
            Icons.speed,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingDistributionChart(
    BuildContext context,
    BudgetProvider provider,
  ) {
    final budgetsWithSpending =
        provider.budgets.where((budget) => budget.spentAmount > 0).toList()
          ..sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    if (budgetsWithSpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.insights,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Spending Data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start making transactions to see your spending distribution',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final totalSpent = budgetsWithSpending.fold<double>(
      0,
      (sum, budget) => sum + budget.spentAmount,
    );
    final displayBudgets = budgetsWithSpending.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${totalSpent.toStringAsFixed(0)} spent',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayBudgets.map((budget) {
            final color = _getCategoryColor(budget.categoryId);
            final percentage = totalSpent > 0
                ? (budget.spentAmount / totalSpent * 100)
                : 0.0;
            final progressValue = budget.allocatedAmount > 0
                ? (budget.spentAmount / budget.allocatedAmount).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: budget.isOverspent
                      ? Theme.of(context).colorScheme.error
                      : color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.categoryName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: budget.isOverspent
                              ? Theme.of(context).colorScheme.error
                              : budget.isNearLimit
                              ? Theme.of(context).colorScheme.tertiary
                              : color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${budget.spentAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: budget.isOverspent
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                      Text(
                        'of ₹${budget.allocatedAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budget.isOverspent
                          ? Theme.of(context).colorScheme.error
                          : budget.isNearLimit
                          ? Theme.of(context).colorScheme.tertiary
                          : color,
                    ),
                  ),
                  if (budget.isOverspent || budget.isNearLimit) ...[
                    const SizedBox(height: 4),
                    Text(
                      budget.isOverspent
                          ? 'Over budget by ₹${(budget.spentAmount - budget.allocatedAmount).toStringAsFixed(0)}'
                          : 'Approaching limit (${(progressValue * 100).toStringAsFixed(0)}% used)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: budget.isOverspent
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (budgetsWithSpending.length > 5) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${budgetsWithSpending.length - 5} more categories with spending',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetPerformance(
    BuildContext context,
    BudgetProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Performance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  context,
                  'On Track',
                  provider.onTrackCount,
                  provider.budgets.length,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  context,
                  'Near Limit',
                  provider.nearLimitCount,
                  provider.budgets.length,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  context,
                  'Over Budget',
                  provider.overBudgetCount,
                  provider.budgets.length,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      children: [
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count of $total',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    BudgetProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...provider.budgets.map((budget) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        budget.categoryId,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(budget.categoryId),
                      color: _getCategoryColor(budget.categoryId),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        LinearProgressIndicator(
                          value: budget.spentPercentage.clamp(0.0, 1.0),
                          backgroundColor: _getCategoryColor(
                            budget.categoryId,
                          ).withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getCategoryColor(budget.categoryId),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${budget.spentAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'of ₹${budget.allocatedAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, BudgetProvider provider) {
    final recommendations = <Map<String, dynamic>>[];

    // Generate recommendations based on budget data
    if (provider.overBudgetCount > 0) {
      recommendations.add({
        'title': 'Review Over-Budget Categories',
        'description':
            '${provider.overBudgetCount} categories are over budget. Consider adjusting spending or increasing allocations.',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }

    if (provider.totalSpent < provider.totalAllocated * 0.5) {
      recommendations.add({
        'title': 'Low Spending Activity',
        'description':
            'You\'re using less than 50% of your budget. Consider saving the surplus or adjusting allocations.',
        'icon': Icons.trending_down,
        'color': Colors.green,
      });
    }

    if (provider.budgets.where((b) => b.period == 'monthly').length < 3) {
      recommendations.add({
        'title': 'Add More Categories',
        'description':
            'Consider adding budgets for more spending categories to get better control over your finances.',
        'icon': Icons.add_circle,
        'color': Colors.blue,
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'title': 'Great Job!',
        'description':
            'Your budgets are well balanced. Keep monitoring your spending patterns.',
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (rec['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (rec['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    rec['icon'] as IconData,
                    color: rec['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'] as String,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: rec['color'] as Color,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final colors = {
      'housing': Colors.blue,
      'food': Colors.green,
      'transportation': Colors.orange,
      'savings': Colors.purple,
      'investments': Colors.teal,
      'entertainment': Colors.pink,
      'shopping': Colors.red,
      'health': Colors.cyan,
      'personal': Colors.amber,
      'education': Colors.indigo,
      'miscellaneous': Colors.grey,
    };
    return colors[categoryId] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String categoryId) {
    final icons = {
      'housing': Icons.home,
      'food': Icons.restaurant,
      'transportation': Icons.directions_car,
      'savings': Icons.savings,
      'investments': Icons.trending_up,
      'entertainment': Icons.movie,
      'shopping': Icons.shopping_bag,
      'health': Icons.local_hospital,
      'personal': Icons.face,
      'education': Icons.school,
      'miscellaneous': Icons.more_horiz,
    };
    return icons[categoryId] ?? Icons.category;
  }
}
