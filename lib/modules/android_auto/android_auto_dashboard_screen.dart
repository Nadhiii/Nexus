import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexus/core/providers/android_auto_provider.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_typography.dart';
import 'package:nexus/core/theme/app_spacing.dart';

/// Android Auto Dashboard Screen
/// Displays key financial information optimized for Android Auto display
class AndroidAutoDashboardScreen extends StatefulWidget {
  const AndroidAutoDashboardScreen({super.key});

  @override
  State<AndroidAutoDashboardScreen> createState() =>
      _AndroidAutoDashboardScreenState();
}

class _AndroidAutoDashboardScreenState
    extends State<AndroidAutoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndroidAuto();
  }

  Future<void> _initializeAndroidAuto() async {
    final provider = context.read<AndroidAutoProvider>();
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Consumer<AndroidAutoProvider>(
        builder: (context, provider, _) {
          if (!provider.isConnected) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 64,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Android Auto Not Connected',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Connect your device to Android Auto to view your financial dashboard on your car display.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  SizedBox(height: AppSpacing.lg),

                  // Dashboard Summary
                  _buildDashboardSummary(provider),
                  SizedBox(height: AppSpacing.lg),

                  // Recent Transactions
                  if (provider.state.recentTransactions.isNotEmpty)
                    _buildRecentTransactions(provider),
                  SizedBox(height: AppSpacing.lg),

                  // Last Alert
                  if (provider.state.lastAlert != null)
                    _buildAlertBanner(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Android Auto Dashboard',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Optimized for car display',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(AndroidAutoProvider provider) {
    final data = provider.state.dashboardData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _buildSummaryCard(
          icon: Icons.account_balance_wallet,
          title: 'Total Balance',
          value: data['totalBalance'] ?? 'N/A',
          color: AppColors.primaryBlue,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildSummaryCard(
          icon: Icons.trending_up,
          title: 'Monthly Income',
          value: data['monthlyIncome'] ?? 'N/A',
          color: AppColors.success,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildSummaryCard(
          icon: Icons.trending_down,
          title: 'Monthly Expense',
          value: data['monthlyExpense'] ?? 'N/A',
          color: AppColors.error,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildSummaryCard(
          icon: Icons.savings,
          title: 'Savings Rate',
          value: data['savingsRate'] ?? 'N/A',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTypography.headlineSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(AndroidAutoProvider provider) {
    final transactions = provider.state.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length.clamp(0, 3), // Show max 3 transactions
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = transaction['amount'] ?? '0';
    final description = transaction['description'] ?? 'Transaction';

    final isExpense =
        type.toString().toLowerCase().contains('expense') ||
        type.toString().toLowerCase().contains('debit');

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.error : AppColors.success)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? AppColors.error : AppColors.success,
              size: 16,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  type,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodySmall.copyWith(
              color: isExpense ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(AndroidAutoProvider provider) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: AppColors.warning, size: 20),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              provider.state.lastAlert ?? 'No alert',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
