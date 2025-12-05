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
        title: Text('Debts & Loans', style: AppTypography.headlineMedium),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, DebtProvider provider) {
    // Calculate additional stats
    final totalDebt = provider.totalDebt;
    final totalEMI = provider.debts.fold<double>(
      0,
      (sum, debt) => sum + (debt.monthlyEMI ?? 0),
    );
    final overdueCount = provider.debts.where((d) => d.isPaymentOverdue).length;
    final dueSoonCount = provider.debts
        .where((d) => d.isPaymentDueSoon && !d.isPaymentOverdue)
        .length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Outstanding',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
              if (overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$overdueCount overdue',
                        style: AppTypography.bodySmall.copyWith(
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
                  NumberFormat('#,##,###').format(totalDebt),
                  style: AppTypography.currencyLarge.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly EMI',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##,###').format(totalEMI)}',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Loans',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.debts.length}',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (dueSoonCount > 0) ...[
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Soon',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dueSoonCount',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final progressValue = debt.totalMonths != null
        ? debt.progressByMonths
        : progress;
    final isPaymentDue = debt.isPaymentDueSoon;
    final isOverdue = debt.isPaymentOverdue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isOverdue
            ? Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5)
            : isPaymentDue
            ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment due banner
          if (isOverdue || isPaymentDue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.error.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_rounded : Icons.schedule,
                    size: 16,
                    color: isOverdue ? AppColors.error : Colors.orange,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isOverdue
                        ? 'Payment overdue!'
                        : 'Payment due in ${debt.daysUntilNextPayment} days',
                    style: AppTypography.bodySmall.copyWith(
                      color: isOverdue ? AppColors.error : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with type icon, name, and action buttons
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getDebtTypeColor(debt.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(
                        _getDebtTypeIcon(debt.type),
                        color: _getDebtTypeColor(debt.type),
                        size: 22,
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
                          Row(
                            children: [
                              Text(
                                _getDebtTypeDisplayName(debt),
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              if (debt.lenderName != null &&
                                  debt.lenderName!.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    debt.lenderName!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Small action buttons
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.white54,
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ModernAddDebtScreen(debtToEdit: debt),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error.withOpacity(0.7),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showDeleteDialog(context, debt),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Balance and EMI row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outstanding Balance',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              locale: 'en_IN',
                              symbol: '₹',
                              decimalDigits: 0,
                            ).format(debt.currentBalance),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (debt.monthlyEMI != null && debt.monthlyEMI! > 0)
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'EMI',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.5),
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
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Progress bar
                if (debt.originalAmount > 0 || debt.totalMonths != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppColors.cardDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressValue > 0.7
                            ? Colors.green
                            : progressValue > 0.3
                            ? Colors.orange
                            : AppColors.error,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Stats row
                Row(
                  children: [
                    if (debt.totalMonths != null) ...[
                      _buildStatChip(
                        Icons.calendar_month,
                        '${debt.paidMonths ?? 0}/${debt.totalMonths} EMIs',
                        Colors.blue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (debt.interestRate != null &&
                        debt.interestRate! > 0) ...[
                      _buildStatChip(
                        Icons.percent,
                        '${debt.interestRate!.toStringAsFixed(1)}% p.a.',
                        Colors.purple,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        '${(progressValue * 100).toStringAsFixed(0)}% paid',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Prominent Pay EMI Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showQuickPayDialog(context, debt),
                    icon: const Icon(Icons.payment, size: 20),
                    label: Text(
                      debt.monthlyEMI != null
                          ? 'Pay EMI (₹${NumberFormat('#,##,###').format(debt.monthlyEMI)})'
                          : 'Record Payment',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOverdue
                          ? AppColors.error
                          : isPaymentDue
                          ? Colors.orange
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                // Additional info if available
                if (debt.remainingMonths != null &&
                    debt.remainingMonths! > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '${debt.remainingMonths} months remaining • Est. payoff: ${DateFormat('MMM yyyy').format(debt.estimatedPayoffDate ?? DateTime.now())}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
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
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.owedByMe:
        return 'Owed by Me';
      case DebtType.owedToMe:
        return 'Owed to Me';
      case DebtType.custom:
        return 'Custom';
      case DebtType.other:
        return 'Other';
    }
  }

  // Get display name for debt (uses custom name if available)
  String _getDebtTypeDisplayName(Debt debt) {
    if (debt.type == DebtType.custom &&
        debt.customTypeName != null &&
        debt.customTypeName!.isNotEmpty) {
      return debt.customTypeName!;
    }
    return _getDebtTypeName(debt.type);
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
        return Icons.monetization_on;
      case DebtType.owedByMe:
        return Icons.arrow_outward;
      case DebtType.owedToMe:
        return Icons.arrow_downward;
      case DebtType.custom:
        return Icons.tune;
      case DebtType.other:
        return Icons.more_horiz;
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
      case DebtType.custom:
        return AppColors.primaryBlue;
      case DebtType.other:
        return Colors.grey;
    }
  }

  void _showQuickPayDialog(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    if (debt.monthlyEMI != null && debt.monthlyEMI! > 0) {
      amountController.text = debt.monthlyEMI!.toStringAsFixed(0);
    }
    bool incrementMonth = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Payment',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      debt.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Outstanding',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##,###').format(debt.currentBalance)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (debt.totalMonths != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EMIs Paid',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${debt.paidMonths ?? 0} of ${debt.totalMonths}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick amount buttons
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (debt.monthlyEMI != null && debt.monthlyEMI! > 0)
                    _buildQuickAmountButton(
                      amountController,
                      debt.monthlyEMI!,
                      'EMI',
                    ),
                  _buildQuickAmountButton(amountController, 1000, '₹1K'),
                  _buildQuickAmountButton(amountController, 5000, '₹5K'),
                  _buildQuickAmountButton(amountController, 10000, '₹10K'),
                  _buildQuickAmountButton(
                    amountController,
                    debt.currentBalance,
                    'Full',
                  ),
                ],
              ),

              if (debt.totalMonths != null) ...[
                const SizedBox(height: AppSpacing.lg),
                // Option to increment month
                InkWell(
                  onTap: () =>
                      setDialogState(() => incrementMonth = !incrementMonth),
                  child: Row(
                    children: [
                      Checkbox(
                        value: incrementMonth,
                        onChanged: (v) =>
                            setDialogState(() => incrementMonth = v ?? true),
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          'Count as EMI payment (+1 month)',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Record Payment'),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                final newBalance = (debt.currentBalance - amount).clamp(
                  0.0,
                  debt.currentBalance,
                );

                // Increment paid months if selected
                int? newPaidMonths;
                if (incrementMonth && debt.totalMonths != null) {
                  newPaidMonths = (debt.paidMonths ?? 0) + 1;
                }

                // Calculate next payment date if we have payment day
                DateTime? newNextPaymentDate;
                if (incrementMonth && debt.paymentDay != null) {
                  final now = DateTime.now();
                  final nextMonth = DateTime(now.year, now.month + 1, 1);
                  final paymentDay = debt.paymentDay!.clamp(1, 28);
                  newNextPaymentDate = DateTime(
                    nextMonth.year,
                    nextMonth.month,
                    paymentDay,
                  );
                }

                final updatedDebt = debt.copyWith(
                  currentBalance: newBalance,
                  paidMonths: newPaidMonths ?? debt.paidMonths,
                  nextPaymentDate: newNextPaymentDate ?? debt.nextPaymentDate,
                  updatedAt: DateTime.now(),
                );

                await context.read<DebtProvider>().updateDebt(updatedDebt);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment of ₹${NumberFormat('#,##,###').format(amount)} recorded!',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(
    TextEditingController controller,
    double amount,
    String label,
  ) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.cardDarkElevated,
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () {
        controller.text = amount.toStringAsFixed(0);
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Delete Debt',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${debt.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await context.read<DebtProvider>().deleteDebt(debt.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${debt.name}" deleted'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
