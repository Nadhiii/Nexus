import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../investments/mutual_fund_portfolio_screen.dart'; // Only mutual fund portfolio remains, legacy investment screens removed
import '../crypto/crypto_portfolio_screen.dart';
import '../debts/modern_debts_screen.dart';
import '../subscriptions/modern_subscription_screen.dart';
import '../budgets/modern_budgets_screen.dart';
import '../goals/modern_goals_screen.dart';

class ModernInsightsScreen extends StatelessWidget {
  const ModernInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('Insights', style: AppTypography.headlineMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNetWorthCard(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildFinanceToolsGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Only mutual fund logic remains, legacy investment logic removed
    return Consumer3<AccountProvider, InvestmentProvider, DebtProvider>(
      builder: (context, accountProvider, investmentProvider, debtProvider, child) {
        final totalAccounts = accountProvider.totalBalance;
        final totalInvestments = investmentProvider.investments.fold<double>(
          0.0,
          (sum, investment) => sum + (investment.currentValue ?? 0.0),
        );
        final totalDebts = debtProvider.totalDebt;
        final netWorth = totalAccounts + totalInvestments - totalDebts;

        return Container(
          padding: AppSpacing.cardPaddingXl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Worth',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.9),
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
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      netWorth.toStringAsFixed(2),
                      style: AppTypography.currencyLarge.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Accounts: ₹${totalAccounts.toStringAsFixed(0)} | Investments: ₹${totalInvestments.toStringAsFixed(0)} | Debts: ₹${totalDebts.toStringAsFixed(0)}',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceToolsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tools = [
      {
        'title': 'Mutual Funds',
        'subtitle': 'Manage portfolio',
        'icon': Icons.show_chart_rounded,
        'color': colorScheme.secondary,
        'route': const MutualFundPortfolioScreen(),
      },
      {
        'title': 'Crypto',
        'subtitle': 'Track crypto holdings',
        'icon': Icons.currency_bitcoin,
        'color': AppColors.accentTeal,
        'route': const CryptoPortfolioScreen(),
      },
      {
        'title': 'Goals',
        'subtitle': 'Track savings goals',
        'icon': Icons.savings_outlined,
        'color': colorScheme.tertiary,
        'route': const ModernGoalsScreen(),
      },
      {
        'title': 'Budgets',
        'subtitle': 'Plan your spending',
        'icon': Icons.donut_large_rounded,
        'color': colorScheme.primary,
        'route': const ModernBudgetsScreen(),
      },
      {
        'title': 'Debts & Loans',
        'subtitle': 'Track your debts',
        'icon': Icons.payment_rounded,
        'color': colorScheme.error,
        'route': const ModernDebtsScreen(),
      },
      {
        'title': 'Subscriptions',
        'subtitle': 'Manage recurring',
        'icon': Icons.autorenew_rounded,
        'color': AppColors.accentOrange,
        'route': const ModernSubscriptionScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildFinanceToolCard(
          context,
          title: tool['title'] as String,
          subtitle: tool['subtitle'] as String,
          icon: tool['icon'] as IconData,
          color: tool['color'] as Color,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => tool['route'] as Widget)),
        );
      },
    );
  }

  Widget _buildFinanceToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
