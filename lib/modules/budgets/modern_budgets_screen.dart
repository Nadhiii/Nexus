import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/budget_provider.dart';
import 'widgets/add_budget_modal.dart';

class ModernBudgetsScreen extends StatefulWidget {
  const ModernBudgetsScreen({super.key});

  @override
  State<ModernBudgetsScreen> createState() => _ModernBudgetsScreenState();
}

class _ModernBudgetsScreenState extends State<ModernBudgetsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BudgetProvider>(context, listen: false).initialize(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          'Delete Budget',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${budget.categoryName}" budget?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<BudgetProvider>(
                context,
                listen: false,
              ).deleteBudget(budget.id);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = provider.budgets;

          return CustomScrollView(
            slivers: [
              // 1. GOLDEN HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                  title: Text(
                    'Budgets',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 10),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: AppColors.accentPurple,
                          size: 20,
                        ),
                      ),
                      tooltip: "Auto Setup",
                      onPressed: () => showQuickSetupModal(context),
                    ),
                  ),
                ],
              ),

              // 2. HERO OVERVIEW (Monthly Cap)
              if (budgets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildOverviewCard(context, provider),
                  ),
                ),

              // 3. BUDGET LIST
              if (budgets.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final budget = budgets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildBudgetCard(context, budget),
                      );
                    }, childCount: budgets.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          onPressed: () => showAddBudgetModal(context),
          backgroundColor: AppColors.cardSurface,
          elevation: 0,
          icon: Icon(Icons.add, color: AppColors.accentPurple),
          label: Text(
            'New Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.accentPurple,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, BudgetProvider provider) {
    final totalAllocated = provider.totalAllocated;
    final totalSpent = provider.totalSpent;
    final totalRemaining = provider.totalRemaining;
    final percentSpent = totalAllocated > 0
        ? (totalSpent / totalAllocated)
        : 0.0;

    // Color logic
    final isOver = totalSpent > totalAllocated;
    final statusColor = isOver
        ? AppColors.error
        : (percentSpent > 0.8 ? AppColors.warning : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withOpacity(0.15),
            AppColors.accentPurple.withOpacity(0.05),
          ],
        ),
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REMAINING MONTHLY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(percentSpent * 100).clamp(0, 999).toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_formatAmount(totalRemaining)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          // Neon Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth * percentSpent.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ₹${_formatAmount(totalSpent)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Cap: ₹${_formatAmount(totalAllocated)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final progress = budget.progress;
    final isOverspent = budget.isOverspent;
    final statusColor = isOverspent
        ? AppColors.error
        : (progress > 0.85 ? AppColors.warning : AppColors.success);

    return Slidable(
      key: ValueKey(budget.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => showAddBudgetModal(context, budget: budget),
            backgroundColor: AppColors.accentPurple,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (_) => _showDeleteConfirmation(context, budget),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => showAddBudgetModal(context, budget: budget),
        onLongPress: () => showAddBudgetModal(context, budget: budget),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(budget.categoryId),
                      color: statusColor,
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
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          budget.isOverspent
                              ? 'Over by ₹${_formatAmount(budget.spentAmount - budget.allocatedAmount)}'
                              : '₹${_formatAmount(budget.remainingAmount)} left',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_formatAmount(budget.allocatedAmount)}',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        budget.period.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: statusColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No budgets set",
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            "Take control of your spending",
            style: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => showQuickSetupModal(context),
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text("Auto Setup"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentPurple,
              side: const BorderSide(color: AppColors.accentPurple),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
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
