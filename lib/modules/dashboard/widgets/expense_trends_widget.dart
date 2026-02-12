import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/expense_trend_service.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Expense Trends Widget for Dashboard
class ExpenseTrendsWidget extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const ExpenseTrendsWidget({super.key, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final trendService = ExpenseTrendService();
        final transactions = provider.transactions;

        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        final velocity = trendService.getSpendingVelocity(transactions);
        final forecast = trendService.forecastNextMonth(transactions);
        final monthlyData = trendService.getMonthlySpending(
          transactions,
          months: 6,
        );

        if (compact) {
          return _buildCompactView(context, velocity, forecast);
        }

        return _buildFullView(
          context,
          velocity,
          forecast,
          monthlyData,
          trendService,
          transactions,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 48, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Add transactions to see spending trends',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(
    BuildContext context,
    SpendingVelocity velocity,
    SpendingForecast forecast,
  ) {
    final statusColor = switch (velocity.status) {
      'Under budget' => AppColors.success,
      'On track' => AppColors.info,
      'Over budget' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                velocity.status == 'Over budget'
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: statusColor,
                size: 24,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    velocity.status,
                    style: AppTypography.labelMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${velocity.dailyRate.toStringAsFixed(0)}/day average',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${velocity.projectedMonthEnd.toStringAsFixed(0)}',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'projected',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(
    BuildContext context,
    SpendingVelocity velocity,
    SpendingForecast forecast,
    List<MonthlySpending> monthlyData,
    ExpenseTrendService trendService,
    List transactions,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Spending Trends',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Spending Velocity Card
          _buildVelocityCard(velocity),
          SizedBox(height: AppSpacing.md),

          // Monthly Chart
          _buildMonthlyChart(monthlyData),
          SizedBox(height: AppSpacing.lg),

          // Forecast Section
          _buildForecastCard(forecast),
          SizedBox(height: AppSpacing.lg),

          // Budget Guidance
          _buildBudgetGuidance(velocity),
        ],
      ),
    );
  }

  Widget _buildVelocityCard(SpendingVelocity velocity) {
    final statusColor = switch (velocity.status) {
      'Under budget' => AppColors.success,
      'On track' => AppColors.info,
      'Over budget' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹${velocity.currentMonthSpent.toStringAsFixed(0)}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  velocity.status,
                  style: AppTypography.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Daily Rate',
                  '₹${velocity.dailyRate.toStringAsFixed(0)}',
                  Icons.today,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  'Projected',
                  '₹${velocity.projectedMonthEnd.toStringAsFixed(0)}',
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  'Days Left',
                  '${velocity.daysRemaining}',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<MonthlySpending> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxExpense = data
        .map((d) => d.totalExpenses)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Overview',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((month) {
              final height = maxExpense > 0
                  ? (month.totalExpenses / maxExpense) * 80
                  : 0.0;
              final monthName = _getMonthAbbr(month.month.month);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_formatAmount(month.totalExpenses)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        monthName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(SpendingForecast forecast) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, size: 20, color: AppColors.pastelPurple),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Next Month Forecast',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted Expenses',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '₹${forecast.predictedExpenses.toStringAsFixed(0)}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Confidence',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '${forecast.confidence.toStringAsFixed(0)}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Based on ${forecast.basedOnMonths} months of data using ${forecast.method}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetGuidance(SpendingVelocity velocity) {
    final hasLastMonth = velocity.lastMonthTotal > 0;

    if (!hasLastMonth) return const SizedBox.shrink();

    final dailyBudget = velocity.dailyBudgetRemaining;
    final isOverBudget = dailyBudget <= 0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isOverBudget ? AppColors.error : AppColors.success).withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: (isOverBudget ? AppColors.error : AppColors.success)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverBudget ? Icons.warning_amber : Icons.lightbulb_outline,
            color: isOverBudget ? AppColors.error : AppColors.success,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverBudget ? 'Over your target!' : 'Daily Budget Remaining',
                  style: AppTypography.labelMedium.copyWith(
                    color: isOverBudget ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOverBudget
                      ? 'You\'ve exceeded last month\'s spending'
                      : 'You can spend ₹${dailyBudget.toStringAsFixed(0)}/day to stay on track',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
