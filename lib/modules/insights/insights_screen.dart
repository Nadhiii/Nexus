import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

// Providers
import '../../core/providers/account_provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/providers/subscription_provider.dart';
// import '../../core/providers/budget_provider.dart'; // Uncomment when available
// import '../../core/providers/goal_provider.dart';   // Uncomment when available

// Screens
import '../investments/investment_screen.dart';
import '../debts/screens/liabilities_screen.dart';
import '../subscriptions/subscription_screen.dart';
import '../budgets/budgets_screen.dart'; // Assuming this exists
import '../goals/goals_screen.dart'; // Assuming this exists
// import '../accounts/accounts_screen.dart';    // Uncomment if you have an accounts screen

class ModernInsightsScreen extends StatelessWidget {
  const ModernInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
          Consumer4<
            AccountProvider,
            DebtProvider,
            InvestmentProvider,
            SubscriptionProvider
          >(
            builder: (context, accounts, debts, investments, subscriptions, _) {
              // --- 1. CALCULATE WEALTH DATA ---
              final totalCash = accounts.accounts.fold(
                0.0,
                (sum, a) => sum + a.balance,
              );
              final totalInvestments = investments.investments.fold(
                0.0,
                (sum, i) => sum + i.currentAmount,
              );

              // Active Debts only (> 1.0 tolerance)
              final activeDebts = debts.debts
                  .where((d) => d.currentBalance > 1.0)
                  .toList();
              final totalLiabilities = activeDebts.fold(
                0.0,
                (sum, d) => sum + d.currentBalance,
              );

              final netWorth =
                  (totalCash + totalInvestments) - totalLiabilities;

              // --- 2. CALCULATE BURN RATE ---
              final activeSubs = subscriptions.subscriptions
                  .where((s) => s.isActive)
                  .toList();
              final subCost = activeSubs.fold(0.0, (sum, s) {
                if (s.frequency == 'monthly') {
                  return sum + s.amount;
                }
                if (s.frequency == 'yearly') {
                  return sum + (s.amount / 12);
                }
                return sum + s.amount; // Simplify
              });

              final debtEMI = activeDebts.fold(
                0.0,
                (sum, d) => sum + (d.monthlyEMI ?? 0),
              );
              final monthlyBurn = subCost + debtEMI;

              return CustomScrollView(
                slivers: [
                  // HEADER
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 110,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false, // Top-level tab
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: AppSpacing.xl, bottom: AppSpacing.xl2),
                      title: Text(
                        'Wealth',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // 1. HERO SECTION (Net Worth + Burn)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        children: [
                          _buildNetWorthCard(
                            netWorth,
                            totalCash,
                            totalInvestments,
                            totalLiabilities,
                          ),
                          const SizedBox(height: 12),
                          _buildBurnRateTicker(context, monthlyBurn),
                        ],
                      ),
                    ),
                  ),

                  // 2. BENTO GRID - Financial Tools
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl2, AppSpacing.xl, 130),
                    sliver: SliverToBoxAdapter(
                      child: _buildBentoGrid(
                        context,
                        totalInvestments: totalInvestments,
                        investmentCount: investments.investments.length,
                        totalLiabilities: totalLiabilities,
                        activeDebtCount: activeDebts.length,
                        subCost: subCost,
                        activeSubCount: activeSubs.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildNetWorthCard(
    double netWorth,
    double cash,
    double invested,
    double debt,
  ) {
    final isPositive = netWorth >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? AppColors.netWorthPositiveGradient
              : AppColors.netWorthNegativeGradient,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
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
                'NET WORTH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.privacy_tip_outlined,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Γé╣${NumberFormat('#,##,###').format(netWorth)}',
            style: AppTypography.currencyLarge,
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Mini Breakdown
          Row(
            children: [
              _buildMiniStat("Liquid", cash, AppColors.info),
              const SizedBox(width: AppSpacing.lg),
              _buildMiniStat("Invested", invested, AppColors.investmentIndigo),
              const SizedBox(width: AppSpacing.lg),
              _buildMiniStat("Debt", debt, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurnRateTicker(BuildContext context, double monthlyBurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.accentOrange,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            "Monthly Burn: ",
            style: AppTypography.bodySmall,
          ),
          Text(
            "Γé╣${NumberFormat('#,##,###').format(monthlyBurn)}",
            style: AppTypography.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(
    BuildContext context, {
    required double totalInvestments,
    required int investmentCount,
    required double totalLiabilities,
    required int activeDebtCount,
    required double subCost,
    required int activeSubCount,
  }) {
    const double spacing = AppSpacing.md;

    return Column(
      children: [
        // Row 1: Investments (large) + Liabilities (medium)
        Row(
          children: [
            // INVESTMENTS - Large tile (takes more space)
            Expanded(
              flex: 3,
              child: _buildBentoTile(
                context,
                title: "Investments",
                value: "Γé╣${NumberFormat.compact().format(totalInvestments)}",
                subtitle: "$investmentCount Assets",
                icon: Icons.show_chart,
                color: AppColors.investmentIndigo,
                height: 160,
                isLarge: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernInvestmentScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            // LIABILITIES
            Expanded(
              flex: 2,
              child: _buildBentoTile(
                context,
                title: "Liabilities",
                value: "Γé╣${NumberFormat.compact().format(totalLiabilities)}",
                subtitle: "$activeDebtCount Loans",
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                height: 160,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiabilitiesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing),

        // Row 2: Subscriptions (wide)
        _buildBentoTile(
          context,
          title: "Subscriptions",
          value: "Γé╣${NumberFormat.compact().format(subCost)}/mo",
          subtitle: "$activeSubCount Active",
          icon: Icons.autorenew,
          color: AppColors.accentOrange,
          height: 100,
          isWide: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ModernSubscriptionScreen()),
          ),
        ),
        const SizedBox(height: spacing),

        // Row 3: Budgets + Goals (small tiles)
        Row(
          children: [
            // BUDGETS
            Expanded(
              child: _buildBentoTile(
                context,
                title: "Budgets",
                value: "Plan",
                subtitle: "Spending",
                icon: Icons.pie_chart_outline,
                color: AppColors.pastelTeal,
                height: 130,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernBudgetsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            // GOALS
            Expanded(
              child: _buildBentoTile(
                context,
                title: "Goals",
                value: "Targets",
                subtitle: "Save",
                icon: Icons.flag_outlined,
                color: AppColors.pastelPink,
                height: 130,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ModernGoalsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double height,
    required VoidCallback onTap,
    bool isLarge = false,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: isWide
            ? _buildWideTileContent(title, value, subtitle, icon, color)
            : _buildStandardTileContent(
                title,
                value,
                subtitle,
                icon,
                color,
                isLarge,
              ),
      ),
    );
  }

  Widget _buildWideTileContent(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ],
    );
  }

  Widget _buildStandardTileContent(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isLarge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.all(isLarge ? 12 : 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          ),
          child: Icon(icon, color: color, size: isLarge ? 26 : 20),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 22 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isLarge ? 13 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: isLarge ? 11 : 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
        Text(
          "Γé╣${NumberFormat.compact().format(value)}",
          style: AppTypography.labelLarge.copyWith(color: color),
        ),
      ],
    );
  }
}
