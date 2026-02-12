import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/financial_health.dart';
import '../../../core/providers/financial_health_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Financial Health Score Dashboard Widget
class FinancialHealthDashboard extends StatefulWidget {
  final bool compact;
  final VoidCallback? onTap;

  const FinancialHealthDashboard({super.key, this.compact = false, this.onTap});

  @override
  State<FinancialHealthDashboard> createState() =>
      _FinancialHealthDashboardState();
}

class _FinancialHealthDashboardState extends State<FinancialHealthDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateHealthScore(BuildContext context) {
    final healthProvider = context.read<FinancialHealthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final debtProvider = context.read<DebtProvider>();
    final accountProvider = context.read<AccountProvider>();

    healthProvider.updateData(
      transactions: transactionProvider.transactions,
      budgets: budgetProvider.budgets,
      debts: debtProvider.debts,
      accounts: accountProvider.accounts,
    );

    // Start animation
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialHealthProvider>(
      builder: (context, healthProvider, child) {
        // Trigger calculation on first build
        if (healthProvider.healthScore == null && !healthProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateHealthScore(context);
          });
        }

        final score = healthProvider.healthScore;

        if (healthProvider.isLoading) {
          return _buildLoadingState();
        }

        if (score == null) {
          return _buildEmptyState();
        }

        if (widget.compact) {
          return _buildCompactView(score);
        }

        return _buildFullView(score);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
          Icon(Icons.insights, size: 48, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Add transactions to see your Financial Health Score',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(FinancialHealthScore score) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              score.scoreColor.withOpacity(0.2),
              score.scoreColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: score.scoreColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            _buildMiniScoreCircle(score),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Financial Health',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    score.status,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScoreCircle(FinancialHealthScore score) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: score.scoreColor.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          score.grade,
          style: AppTypography.titleLarge.copyWith(
            color: score.scoreColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFullView(FinancialHealthScore score) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Health Score',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () => _updateHealthScore(context),
                tooltip: 'Refresh Score',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // Score Circle
          Center(child: _buildScoreCircle(score)),
          SizedBox(height: AppSpacing.lg),

          // Status
          Center(
            child: Text(
              score.status,
              style: AppTypography.titleSmall.copyWith(
                color: score.scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),

          // Component Breakdown
          Text(
            'Score Breakdown',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ...score.components.map((component) => _buildComponentRow(component)),

          // Tips Section
          if (score.tips.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xl),
            Text(
              'Suggestions',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            ...score.tips.take(3).map((tip) => _buildTipRow(tip)),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCircle(FinancialHealthScore score) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final animatedScore = (score.overallScore * _scoreAnimation.value)
            .round();
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: AppColors.cardElevated,
                  valueColor: AlwaysStoppedAnimation(AppColors.cardElevated),
                ),
              ),
              // Progress arc
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: (score.overallScore / 100) * _scoreAnimation.value,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(score.scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedScore.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: score.scoreColor,
                    ),
                  ),
                  Text(
                    score.grade,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComponentRow(ScoreComponent component) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                component.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${component.score}/${component.maxPoints}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: component.percentage / 100,
                    backgroundColor: AppColors.cardElevated,
                    valueColor: AlwaysStoppedAnimation(
                      _getComponentColor(component.percentage),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 100,
                child: Text(
                  component.description,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
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

  Color _getComponentColor(double percentage) {
    if (percentage >= 70) return AppColors.success;
    if (percentage >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildTipRow(HealthTip tip) {
    final priorityColor = switch (tip.priority) {
      TipPriority.high => AppColors.error,
      TipPriority.medium => AppColors.warning,
      TipPriority.low => AppColors.success,
    };

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(tip.icon, color: priorityColor, size: 24),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tip.description,
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
}
