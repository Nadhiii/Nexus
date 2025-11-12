import 'package:flutter/material.dart';

// Import the new, modern screens
import '../budgets/modern_budgets_screen.dart';
import '../investments/modern_investment_portfolio_screen.dart';
import '../goals/modern_goals_screen.dart';
import '../subscriptions/modern_subscription_screen.dart';
import '../debts/modern_debts_screen.dart';

class FinanceHubScreen extends StatefulWidget {
  const FinanceHubScreen({super.key});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Finance Hub', style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: ShapeDecoration(
                shape: const StadiumBorder(),
                color: colorScheme.primaryContainer,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: colorScheme.onPrimaryContainer,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.titleSmall,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Budgets'),
                Tab(text: 'Investments'),
                Tab(text: 'Goals'),
                Tab(text: 'Subscriptions'),
                Tab(text: 'Debts'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ModernBudgetsScreen(),
          ModernInvestmentPortfolioScreen(),
          ModernGoalsScreen(),
          ModernSubscriptionScreen(),
          ModernDebtsScreen(),
        ],
      ),
    );
  }
}
