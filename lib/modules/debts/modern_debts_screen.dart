import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/add_debt_modal.dart' as debt_modal;

class ModernDebtsScreen extends StatefulWidget {
  const ModernDebtsScreen({super.key});

  @override
  State<ModernDebtsScreen> createState() => _ModernDebtsScreenState();
}

class _ModernDebtsScreenState extends State<ModernDebtsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          if (debtProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (debtProvider.debts.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              debtProvider.refresh();
            },
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(context, debtProvider),
                        const SizedBox(height: AppSpacing.lg),
                        _buildStrategyCard(context, debtProvider),
                        const SizedBox(height: AppSpacing.lg),
                        _buildQuickStats(context, debtProvider),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Your Debts',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                _buildDebtsList(context, debtProvider),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => debt_modal.showAddDebtModal(context),
          backgroundColor: AppColors.error,
          icon: const Icon(Icons.add),
          label: const Text('Add Debt'),
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
          'Debts & Loans',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.school_outlined),
          onPressed: () => _showEducationDialog(context),
          tooltip: 'Debt Education',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, DebtProvider provider) {
    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Debt',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
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
                  provider.totalDebt.toStringAsFixed(2),
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
          Text(
            'Monthly Payment ${provider.formattedTotalMinimumPayments} • ${_getFormattedDebtFreeDate(provider)}',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(BuildContext context, DebtProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Payoff Strategy',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: DropdownButton<DebtPayoffStrategy>(
              value: provider.selectedStrategy,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.cardDarkElevated,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              items: DebtPayoffStrategy.values.map((strategy) {
                return DropdownMenuItem(
                  value: strategy,
                  child: Text(_getStrategyDisplayName(strategy)),
                );
              }).toList(),
              onChanged: (strategy) {
                if (strategy != null) {
                  provider.setPayoffStrategy(strategy);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _getStrategyDescription(provider.selectedStrategy),
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DebtProvider provider) {
    final calculation = provider.debtFreeCalculation;
    final monthsLeft = calculation?['months'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Debts',
            '${provider.debts.length}',
            Icons.receipt_long,
            Colors.orange,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Months Left',
            monthsLeft > 0 ? '$monthsLeft' : '∞',
            Icons.calendar_month,
            AppColors.accentPurple,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Interest/Mo',
            provider.formattedTotalMonthlyInterest,
            Icons.trending_up,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context, DebtProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final debt = provider.debts[index];
          final isPriority = (debt.priority ?? 999) <= 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildDebtCard(context, debt, isPriority),
          );
        }, childCount: provider.debts.length),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, bool isPriority) {
    final progress = debt.currentBalance > 0
        ? (debt.originalAmount - debt.currentBalance) / debt.originalAmount
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isPriority
            ? Border.all(color: AppColors.error.withOpacity(0.3), width: 1)
            : null,
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
                  color: _getDebtTypeColor(debt.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _getDebtTypeIcon(debt.type),
                  color: _getDebtTypeColor(debt.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            debt.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isPriority)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              'Priority #${debt.priority}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      debt.typeDisplayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(debt.currentBalance),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
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
                      'Min Payment',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(debt.monthlyEMI),
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
                      'Interest',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${debt.interestRate?.toStringAsFixed(1) ?? '0.0'}%',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.7 ? Colors.green : Colors.orange,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% paid off',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
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
              Icons.celebration,
              size: 120,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Debt Free!',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'You have no debts recorded. If you have any debts, add them to track your progress.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => debt_modal.showAddDebtModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.lg,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Debt'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _showEducationDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Learn About Debt'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDebtFreeDate(DebtProvider provider) {
    final calculation = provider.debtFreeCalculation;
    if (calculation == null) return 'Never';
    final months = calculation['months'] as int? ?? 0;
    if (months == 0) return 'Never';
    final date = DateTime.now().add(Duration(days: months * 30));
    final formatter = DateFormat('MMM yyyy');
    return 'Free by ${formatter.format(date)}';
  }

  String _getStrategyDisplayName(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.avalanche:
        return 'Avalanche (Highest Interest)';
      case DebtPayoffStrategy.snowball:
        return 'Snowball (Smallest Balance)';
      case DebtPayoffStrategy.custom:
        return 'Custom Order';
    }
  }

  String _getStrategyDescription(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.avalanche:
        return 'Pay minimums on all debts, then extra toward highest interest. Saves the most money.';
      case DebtPayoffStrategy.snowball:
        return 'Pay minimums on all debts, then extra toward smallest balance. Provides quick wins.';
      case DebtPayoffStrategy.custom:
        return 'Pay debts in your preferred order.';
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      case DebtType.businessLoan:
        return Icons.business;
      case DebtType.goldLoan:
        return Icons.star;
      case DebtType.owedToMe:
        return Icons.call_received;
      case DebtType.owedByMe:
        return Icons.call_made;
      case DebtType.other:
        return Icons.account_balance;
    }
  }

  Color _getDebtTypeColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return AppColors.error;
      case DebtType.personalLoan:
        return Colors.orange;
      case DebtType.homeLoan:
        return AppColors.primaryBlue;
      case DebtType.carLoan:
        return AppColors.accentTeal;
      case DebtType.educationLoan:
        return AppColors.accentPurple;
      case DebtType.businessLoan:
        return Colors.amber;
      case DebtType.goldLoan:
        return Colors.yellow;
      case DebtType.owedToMe:
        return Colors.green;
      case DebtType.owedByMe:
        return Colors.red;
      case DebtType.other:
        return Colors.grey;
    }
  }

  void _showEducationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDarkElevated,
        title: Text(
          'Debt Education',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debt Strategies:',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Debt Avalanche: Pay highest interest rate first. Saves most money mathematically.\n\n'
                '• Debt Snowball: Pay smallest balance first. Provides psychological motivation.\n',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tips:',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Always pay minimum on all debts\n'
                '• Put extra money toward priority debt\n'
                '• Avoid taking on new debt\n'
                '• Consider debt consolidation for high rates\n'
                '• Build emergency fund alongside debt payoff',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(color: AppColors.accentTeal),
            ),
          ),
        ],
      ),
    );
  }
}
