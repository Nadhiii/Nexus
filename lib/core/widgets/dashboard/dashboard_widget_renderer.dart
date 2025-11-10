import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../dashboard_widget_preferences.dart';
import '../../models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_provider.dart';
import '../dashboard_card.dart';
import '../upcoming_bills_widget.dart';
import '../goal_tracker_widget.dart';

class DashboardWidgetRenderer extends StatelessWidget {
  final DashboardWidget widget;
  final bool isEditMode;

  const DashboardWidgetRenderer({
    super.key,
    required this.widget,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = _buildWidgetContent(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: content,
    );
  }

  Widget _buildWidgetContent(BuildContext context) {
    switch (widget.type) {
      case DashboardWidgetType.netWorth:
        return _buildNetWorthWidget(context);
      case DashboardWidgetType.quickActions:
        return _buildQuickActionsWidget(context);
      case DashboardWidgetType.upcomingBills:
        return _buildUpcomingBillsWidget(context);
      case DashboardWidgetType.goalProgress:
        return _buildGoalProgressWidget(context);
      case DashboardWidgetType.recentTransactions:
        return _buildRecentTransactionsWidget(context);
      case DashboardWidgetType.monthlySpending:
        return _buildMonthlySpendingWidget(context);
      case DashboardWidgetType.investments:
        return _buildInvestmentsWidget(context);
      case DashboardWidgetType.cashFlow:
        return _buildCashFlowWidget(context);
    }
  }

  Widget _buildNetWorthWidget(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        final accounts = accountProvider.accounts;
        final totalBalance = accounts.fold<double>(
          0,
          (sum, account) => sum + account.balance,
        );

        return DashboardCard(
          title: widget.title,
          subtitle: 'Total Account Balance',
          value: totalBalance > 0
              ? '₹${totalBalance.toStringAsFixed(2)}'
              : '₹0.00',
          trend: accounts.isNotEmpty
              ? 'Based on ${accounts.length} account(s)'
              : 'No accounts added',
          trendPositive: totalBalance > 0,
          icon: widget.icon,
          onTap: isEditMode ? null : () {
            // Navigate to detailed net worth view
          },
        );
      },
    );
  }

  Widget _buildQuickActionsWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            widget.size == DashboardWidgetSize.small
                ? _buildCompactQuickActions(context)
                : _buildExpandedQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(
          icon: Icons.add,
          label: 'Add',
          onTap: isEditMode ? null : () {},
        ),
        _buildQuickAction(
          icon: Icons.swap_horiz,
          label: 'Transfer',
          onTap: isEditMode ? null : () {},
        ),
      ],
    );
  }

  Widget _buildExpandedQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickAction(
              icon: Icons.add,
              label: 'Add Expense',
              onTap: isEditMode ? null : () {},
            ),
            _buildQuickAction(
              icon: Icons.trending_up,
              label: 'Add Income',
              onTap: isEditMode ? null : () {},
            ),
            _buildQuickAction(
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onTap: isEditMode ? null : () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickAction(
              icon: Icons.flag,
              label: 'New Goal',
              onTap: isEditMode ? null : () {},
            ),
            _buildQuickAction(
              icon: Icons.account_balance,
              label: 'Add Account',
              onTap: isEditMode ? null : () {},
            ),
            _buildQuickAction(
              icon: Icons.receipt,
              label: 'Scan Bill',
              onTap: isEditMode ? null : () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        constraints: const BoxConstraints(minWidth: 70),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBillsWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const UpcomingBillsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const GoalTrackerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsWidget(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final recentTransactions = transactionProvider.transactions
            .take(widget.size == DashboardWidgetSize.small ? 3 : 5)
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recentTransactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent transactions'),
                    ),
                  )
                else
                  ...recentTransactions.map((transaction) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Icon(
                        transaction.type == TransactionType.income 
                            ? Icons.arrow_upward 
                            : transaction.type == TransactionType.transfer
                                ? Icons.swap_horiz
                                : Icons.arrow_downward,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.description ?? 'No description',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.type == TransactionType.income 
                            ? Colors.green 
                            : transaction.type == TransactionType.transfer
                                ? Colors.blue
                                : Colors.red,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySpendingWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Placeholder for monthly spending chart
            Container(
              height: widget.size == DashboardWidgetSize.large ? 200 : 100,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Monthly Spending Chart\n(Coming Soon)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentsWidget(BuildContext context) {
    return Consumer<InvestmentProvider>(
      builder: (context, investmentProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInvestmentStat(
                        'Portfolio Value',
                        investmentProvider.formattedTotalValue,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInvestmentStat(
                        'Gain/Loss',
                        investmentProvider.formattedGainLoss,
                        investmentProvider.isPortfolioProfitable 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvestmentStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Placeholder for cash flow chart
            Container(
              height: widget.size == DashboardWidgetSize.large ? 250 : 150,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Cash Flow Chart\n(Coming Soon)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
