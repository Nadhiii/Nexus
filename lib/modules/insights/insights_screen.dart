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
import '../../core/providers/budget_provider.dart';
import '../../core/providers/goal_provider.dart';

// Screens
import '../investments/investment_screen.dart';
import '../debts/screens/liabilities_screen.dart';
import '../subscriptions/subscription_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';

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
              final totalCash = accounts.totalBalance;
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
                      titlePadding: const EdgeInsets.only(
                        left: AppSpacing.xl,
                        bottom: AppSpacing.xl2,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl2,
                      AppSpacing.xl,
                      130,
                    ),
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
            '₹${NumberFormat('#,##,###').format(netWorth)}',
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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
          Text("Monthly Burn: ", style: AppTypography.bodySmall),
          Text(
            "₹${NumberFormat('#,##,###').format(monthlyBurn)}",
            style: AppTypography.labelLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        Text(
          "₹${NumberFormat.compact().format(value)}",
          style: AppTypography.labelLarge.copyWith(color: color),
        ),
      ],
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
    final budgetProvider = context.watch<BudgetProvider>();
    final goalProvider = context.watch<GoalProvider>();

    final activeBudgets = budgetProvider.activeBudgets;
    final budgetUsedPct = budgetProvider.totalAllocated <= 0
        ? 0.0
        : (budgetProvider.totalSpent / budgetProvider.totalAllocated) * 100;
    final budgetValue = activeBudgets.isEmpty
        ? '0%'
        : '${budgetUsedPct.round()}%';
    final budgetSubtitle = activeBudgets.isEmpty
        ? 'No active budgets'
        : '${activeBudgets.length} active';

    final activeGoals = goalProvider.goals
        .where((g) => !g.isCompleted)
        .toList();
    final goalsSaved = activeGoals.fold<double>(
      0,
      (sum, g) => sum + g.currentAmount,
    );
    final goalsValue = activeGoals.isEmpty
        ? '₹0'
        : '₹${NumberFormat.compact().format(goalsSaved)}';
    final goalsSubtitle = activeGoals.isEmpty
        ? 'No active targets'
        : '${activeGoals.length} in progress';

    const double gap = AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            "FINANCIAL OVERVIEW",
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // TOP SECTION: 1 Vertical (Left) + 2 Horizontal (Right)
        SizedBox(
          height: 210, // Fixed height forces perfect bento symmetry
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. VERTICAL CARD
              Expanded(
                flex: 5,
                child: _VerticalBentoCard(
                  title: "Investments",
                  value: "₹${NumberFormat.compact().format(totalInvestments)}",
                  subtitle: "$investmentCount Assets",
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.investmentIndigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ModernInvestmentScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: gap),

              // 2. HORIZONTAL CARDS (Stacked)
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(
                      child: _HorizontalBentoCard(
                        title: "Liabilities",
                        value:
                            "₹${NumberFormat.compact().format(totalLiabilities)}",
                        icon: Icons.credit_card_off_rounded,
                        accentColor: AppColors.error,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LiabilitiesScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: gap),
                    Expanded(
                      child: _HorizontalBentoCard(
                        title: "Subscriptions",
                        value: "₹${NumberFormat.compact().format(subCost)}/mo",
                        icon: Icons.all_inclusive_rounded,
                        accentColor: AppColors.accentOrange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModernSubscriptionScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: gap),

        // BOTTOM SECTION: The Pill-Fill Cards
        Row(
          children: [
            Expanded(
              child: _PillFillBentoCard(
                title: "Budgets",
                value: budgetValue,
                subtitle: budgetSubtitle,
                icon: Icons.pie_chart_outline_rounded,
                accentColor: AppColors.pastelTeal,
                progress: (budgetUsedPct / 100).clamp(0.0, 1.0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModernBudgetsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: _PillFillBentoCard(
                title: "Goals",
                value: goalsValue,
                subtitle: goalsSubtitle,
                icon: Icons.flag_circle_rounded,
                accentColor: AppColors.pastelPink,
                progress: activeGoals.isEmpty ? 0.0 : 0.65,
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
}

// ---------------------------------------------------------
// SUPPORTING BENTO GRID WIDGETS
// ---------------------------------------------------------

class _VerticalBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _VerticalBentoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HorizontalBentoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillFillBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final double progress;
  final VoidCallback onTap;

  const _PillFillBentoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLg,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(progress >= 1.0 ? 0 : 16),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(icon, color: accentColor, size: 18),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
