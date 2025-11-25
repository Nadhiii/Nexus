import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/models/budget.dart';
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
    // Ensure data is loaded when screen opens
    Future.microtask(
      () => Provider.of<BudgetProvider>(context, listen: false).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = provider.budgets;

          if (budgets.isEmpty) {
            return _buildEmptyState(context);
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCard(context, provider),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Budgets',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Quick Setup Button for Predefined Budgets
                          TextButton.icon(
                            onPressed: () => showQuickSetupModal(context),
                            icon: const Icon(
                              Icons.auto_fix_high,
                              size: 16,
                              color: AppColors.accentPurple,
                            ),
                            label: Text(
                              'Auto Setup',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              _buildBudgetsList(context, budgets),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => showAddBudgetModal(context),
          backgroundColor: AppColors.accentPurple,
          icon: const Icon(Icons.add),
          label: const Text('New Budget'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Budgets',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, BudgetProvider provider) {
    final totalAllocated = provider.totalAllocated;
    final totalSpent = provider.totalSpent;
    final totalRemaining = provider.totalRemaining;
    final percentSpent = totalAllocated > 0
        ? (totalSpent / totalAllocated) * 100
        : 0.0;

    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.purpleGradient,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleGradient.first.withOpacity(0.3),
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
                'Total Remaining',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentSpent.toStringAsFixed(0)}% Spent',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatAmount(totalRemaining),
                  style: AppTypography.currencyLarge.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.arrow_downward,
                color: Colors.white.withOpacity(0.8),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Spent ₹${_formatAmount(totalSpent)}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 12,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Text(
                'Budgeted ₹${_formatAmount(totalAllocated)}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(BuildContext context, List<Budget> budgets) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final budget = budgets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildBudgetCard(context, budget),
          );
        }, childCount: budgets.length),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final progress = budget.progress;
    final percentage = (progress * 100).round();
    final isOverspent = budget.isOverspent;

    // Color logic: Green (safe) -> Orange (warning) -> Red (danger)
    Color statusColor;
    if (isOverspent) {
      statusColor = AppColors.error;
    } else if (progress > 0.8) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return GestureDetector(
      onTap: () => showAddBudgetModal(context, budget: budget),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isOverspent
                ? AppColors.error.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _getCategoryIcon(budget.categoryId),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.categoryName,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        budget.period.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          letterSpacing: 1.0,
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
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        isOverspent ? 'Over!' : '$percentage%',
                        style: AppTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ₹${_formatAmount(budget.allocatedAmount)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatAmount(budget.spentAmount)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: isOverspent ? AppColors.error : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Left',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatAmount(budget.remainingAmount)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.cardDark,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 120,
              color: AppColors.accentPurple.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'No Budgets Set',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Create a budget or use the quick setup to start managing your expenses.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => showAddBudgetModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Manual'),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => showQuickSetupModal(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto Setup'),
                ),
              ],
            ),
          ],
        ),
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
