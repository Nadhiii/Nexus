import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../net_worth_widget.dart';
import '../accounts_widget.dart';
import '../debts_widget.dart';
import '../goals_widget.dart';
import '../subscriptions_widget.dart';

class DashboardWidgetRenderer extends StatelessWidget {
  final String widgetType;

  const DashboardWidgetRenderer({Key? key, required this.widgetType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (widgetType) {
      case 'net_worth':
        return Consumer<AccountProvider>(
          builder: (context, provider, child) => NetWorthWidget(netWorth: provider.netWorth),
        );
      case 'accounts':
        return Consumer<AccountProvider>(
          builder: (context, provider, child) => AccountsWidget(accounts: provider.accounts),
        );
      case 'debts':
        return Consumer<DebtProvider>(
          builder: (context, provider, child) => DebtsWidget(debts: provider.debts),
        );
      case 'goals':
        return Consumer<GoalProvider>(
          builder: (context, provider, child) => GoalsWidget(goals: provider.goals),
        );
      case 'subscriptions':
        return Consumer<SubscriptionProvider>(
          builder: (context, provider, child) => SubscriptionsWidget(subscriptions: provider.dueToday),
        );
      default:
        return _buildPlaceholder(context, widgetType);
    }
  }

  Widget _buildPlaceholder(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 40),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Widget not implemented', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
