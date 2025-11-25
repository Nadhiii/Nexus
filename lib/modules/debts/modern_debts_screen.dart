import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'modern_add_debt_screen.dart';

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

          return CustomScrollView(
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
                    ],
                  ),
                ),
              ),
              _buildDebtsList(context, debtProvider),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ModernAddDebtScreen(),
              ),
            );
          },
          backgroundColor: AppColors.error,
          icon: const Icon(Icons.add),
          label: const Text('Add Debt'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Debts & Loans',
          style: AppTypography.headlineMedium,
        ),
      ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildDebtCard(context, debt),
          );
        }, childCount: provider.debts.length),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    final progress = debt.currentBalance > 0
        ? (debt.originalAmount - debt.currentBalance) / debt.originalAmount
        : 1.0;

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
                    Text(
                      debt.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getDebtTypeName(debt.type),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ModernAddDebtScreen(debtToEdit: debt),
                    ),
                  );
                },
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
          if (debt.originalAmount > 0)
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
          if (debt.originalAmount > 0)
            const SizedBox(height: AppSpacing.sm),
          if (debt.originalAmount > 0)
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ModernAddDebtScreen(),
                  ),
                );
              },
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
          ],
        ),
      ),
    );
  }

  String _getDebtTypeName(DebtType type) {
    switch (type) {
      case DebtType.creditCard: return 'Credit Card';
      case DebtType.personalLoan: return 'Personal Loan';
      case DebtType.homeLoan: return 'Home Loan';
      case DebtType.carLoan: return 'Car Loan';
      case DebtType.educationLoan: return 'Education Loan';
      case DebtType.businessLoan: return 'Business Loan';
      case DebtType.goldLoan: return 'Gold Loan';
      case DebtType.owedByMe: return 'Owed by Me';
      case DebtType.owedToMe: return 'Owed to Me';
      case DebtType.other: return 'Other';
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard: return Icons.credit_card;
      case DebtType.personalLoan: return Icons.person;
      case DebtType.homeLoan: return Icons.home;
      case DebtType.carLoan: return Icons.directions_car;
      case DebtType.educationLoan: return Icons.school;
      case DebtType.businessLoan: return Icons.business;
      case DebtType.goldLoan: return Icons.monetization_on;
      case DebtType.owedByMe: return Icons.arrow_outward;
      case DebtType.owedToMe: return Icons.arrow_downward;
      case DebtType.other: return Icons.more_horiz;
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
}
