import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/providers/subscription_provider.dart';

class DashboardWidgetRenderer extends StatelessWidget {
  final String widgetType;

  const DashboardWidgetRenderer({super.key, required this.widgetType});

  @override
  Widget build(BuildContext context) {
    switch (widgetType) {
      case 'net_worth':
        return Consumer<AccountProvider>(
          builder: (context, provider, child) =>
              _buildNetWorthWidget(netWorth: provider.netWorth),
        );
      case 'accounts':
        return Consumer<AccountProvider>(
          builder: (context, provider, child) =>
              _buildAccountsWidget(accounts: provider.accounts),
        );
      case 'debts':
        return Consumer<DebtProvider>(
          builder: (context, provider, child) =>
              _buildDebtsWidget(debts: provider.debts),
        );
      case 'goals':
        return Consumer<GoalProvider>(
          builder: (context, provider, child) =>
              _buildGoalsWidget(goals: provider.goals),
        );
      case 'subscriptions':
        return Consumer<SubscriptionProvider>(
          builder: (context, provider, child) =>
              _buildSubscriptionsWidget(subscriptions: provider.dueToday),
        );
      default:
        return _buildPlaceholder(context, widgetType);
    }
  }

  Widget _buildNetWorthWidget({required double netWorth}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Net Worth', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '\$$netWorth',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsWidget({required List accounts}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accounts', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${accounts.length} accounts',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsWidget({required List debts}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Debts', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${debts.length} debts',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsWidget({required List goals}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Goals', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${goals.length} goals',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsWidget({required List subscriptions}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscriptions', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${subscriptions.length} due today',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String label) {
    // Replaced Theme.of(context) with static colors to prevent unnecessary rebuilds.
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Widget not implemented',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
