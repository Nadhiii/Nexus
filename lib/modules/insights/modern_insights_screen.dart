import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// Providers
import '../../core/providers/account_provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/providers/subscription_provider.dart';
// import '../../core/providers/budget_provider.dart'; // Uncomment when available
// import '../../core/providers/goal_provider.dart';   // Uncomment when available

// Screens
import '../investments/investment_portfolio_screen.dart';
import '../debts/modern_debts_screen.dart';
import '../subscriptions/modern_subscription_screen.dart';
import '../budgets/modern_budgets_screen.dart'; // Assuming this exists
import '../goals/modern_goals_screen.dart'; // Assuming this exists
// import '../accounts/accounts_screen.dart';    // Uncomment if you have an accounts screen

class ModernInsightsScreen extends StatelessWidget {
  const ModernInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
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
                if (s.frequency == 'monthly') return sum + s.amount;
                if (s.frequency == 'yearly') return sum + (s.amount / 12);
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
                    backgroundColor: AppColors.backgroundBlack,
                    surfaceTintColor: AppColors.backgroundBlack,
                    elevation: 0,
                    automaticallyImplyLeading: false, // Top-level tab
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                      title: Text(
                        'Command Center',
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildNetWorthCard(
                            netWorth,
                            totalCash,
                            totalInvestments,
                            totalLiabilities,
                          ),
                          const SizedBox(height: 12),
                          _buildBurnRateTicker(monthlyBurn),
                        ],
                      ),
                    ),
                  ),

                  // 2. TOOLS GRID
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        // INVESTMENTS
                        _buildNavTile(
                          context,
                          title: "Investments",
                          value:
                              "₹${NumberFormat.compact().format(totalInvestments)}",
                          subtitle: "${investments.investments.length} Assets",
                          icon: Icons.show_chart,
                          color: const Color(0xFF6366F1), // Indigo
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModernInvestmentScreen(),
                            ),
                          ),
                        ),

                        // LIABILITIES
                        _buildNavTile(
                          context,
                          title: "Liabilities",
                          value:
                              "₹${NumberFormat.compact().format(totalLiabilities)}",
                          subtitle: "${activeDebts.length} Active Loans",
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.error,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModernDebtsScreen(),
                            ),
                          ),
                        ),

                        // SUBSCRIPTIONS
                        _buildNavTile(
                          context,
                          title: "Subscriptions",
                          value:
                              "₹${NumberFormat.compact().format(subCost)}/mo",
                          subtitle: "${activeSubs.length} Active Services",
                          icon: Icons.autorenew,
                          color: AppColors.accentOrange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModernSubscriptionScreen(),
                            ),
                          ),
                        ),

                        // LIQUID CASH
                        _buildNavTile(
                          context,
                          title: "Liquid Cash",
                          value: "₹${NumberFormat.compact().format(totalCash)}",
                          subtitle: "${accounts.accounts.length} Accounts",
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                          onTap: () {
                            // Navigate to Accounts Screen if available
                            // Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()));
                          },
                        ),

                        // BUDGETS
                        _buildNavTile(
                          context,
                          title: "Budgets",
                          value: "Plan",
                          subtitle: "Track Spending",
                          icon: Icons.pie_chart_outline,
                          color: Colors.teal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModernBudgetsScreen(),
                            ),
                          ),
                        ),

                        // GOALS
                        _buildNavTile(
                          context,
                          title: "Goals",
                          value: "Targets",
                          subtitle: "Save for Future",
                          icon: Icons.flag_outlined,
                          color: Colors.pinkAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModernGoalsScreen(),
                            ),
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] // Slate
              : [const Color(0xFF450A0A), const Color(0xFF7F1D1D)], // Red
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.privacy_tip_outlined,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(netWorth)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),

          // Mini Breakdown
          Row(
            children: [
              _buildMiniStat("Liquid", cash, Colors.blue),
              const SizedBox(width: 16),
              _buildMiniStat("Invested", invested, const Color(0xFF6366F1)),
              const SizedBox(width: 16),
              _buildMiniStat("Debt", debt, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurnRateTicker(double monthlyBurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.accentOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            "Monthly Burn: ",
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          Text(
            "₹${NumberFormat('#,##,###').format(monthlyBurn)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
        Text(
          "₹${NumberFormat.compact().format(value)}",
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
