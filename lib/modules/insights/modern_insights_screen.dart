import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../investments/modern_investment_portfolio_screen.dart';
import '../debts/modern_debts_screen.dart';
import '../subscriptions/modern_subscription_screen.dart';
import '../budgets/modern_budgets_screen.dart';
import '../goals/modern_goals_screen.dart';

class ModernInsightsScreen extends StatelessWidget {
  const ModernInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.background,
                  colorScheme.background.withOpacity(0.8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights',
                    style: AppTypography.displaySmall.copyWith(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
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

    return Consumer2<AccountProvider, InvestmentProvider>(
      builder: (context, accountProvider, investmentProvider, child) {
        final totalAccounts = accountProvider.totalBalance;
        final totalInvestments = investmentProvider.totalPortfolioValue;
        final netWorth = totalAccounts + totalInvestments;
        
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
                      style: AppTypography.currencyLarge.copyWith(color: colorScheme.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Accounts ₹${totalAccounts.toStringAsFixed(0)} • Investments ₹${totalInvestments.toStringAsFixed(0)}',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
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
      {'title': 'Investments', 'subtitle': 'Manage portfolio', 'icon': Icons.trending_up, 'color': colorScheme.secondary, 'route': const ModernInvestmentPortfolioScreen()},
      {'title': 'Goals', 'subtitle': 'Track savings goals', 'icon': Icons.flag_outlined, 'color': colorScheme.tertiary, 'route': const ModernGoalsScreen()},
      {'title': 'Budgets', 'subtitle': 'Plan your spending', 'icon': Icons.pie_chart_outline, 'color': colorScheme.primary, 'route': const ModernBudgetsScreen()},
      {'title': 'Debts & Loans', 'subtitle': 'Track your debts', 'icon': Icons.credit_card_outlined, 'color': colorScheme.error, 'route': const ModernDebtsScreen()},
      {'title': 'Subscriptions', 'subtitle': 'Manage recurring', 'icon': Icons.subscriptions_outlined, 'color': colorScheme.surfaceVariant, 'route': const ModernSubscriptionScreen()},
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
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tool['route'] as Widget)),
        );
      },
    );
  }

  Widget _buildFinanceToolCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
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
            Text(title, style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
