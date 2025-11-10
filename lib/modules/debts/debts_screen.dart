import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/widgets/apple_floating_action_button.dart';
import 'widgets/add_debt_modal.dart' as debt_modal;

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Management'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDebtDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.school_outlined),
            onPressed: () => _showEducationDialog(context),
          ),
        ],
      ),
      body: Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          if (debtProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (debtProvider.debts.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await debtProvider.refresh();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(context, debtProvider),
                  const SizedBox(height: 24),
                  _buildStrategySection(context, debtProvider),
                  const SizedBox(height: 24),
                  _buildDebtsList(context, debtProvider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: AppleFloatingActionButton(
        heroTag: 'fab-debts',
        onPressed: () => _showAddDebtDialog(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Debt Free!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no debts recorded. If you have any debts, add them to track your progress.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddDebtDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Debt'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showEducationDialog(context),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Learn About Debt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DebtProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Debt',
                provider.formattedTotalDebt,
                Icons.account_balance_wallet_outlined,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Monthly Payment',
                provider.formattedTotalMinimumPayments,
                Icons.payment_outlined,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Debt Free Date',
                _getFormattedDebtFreeDate(provider),
                Icons.event_available_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Interest/Month',
                provider.formattedTotalMonthlyInterest,
                Icons.trending_up_outlined,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySection(BuildContext context, DebtProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payoff Strategy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DebtPayoffStrategy>(
              initialValue: provider.selectedStrategy,
              decoration: const InputDecoration(
                labelText: 'Strategy',
                border: OutlineInputBorder(),
              ),
              items: DebtPayoffStrategy.values.map((strategy) {
                return DropdownMenuItem(
                  value: strategy,
                  child: Text(_getStrategyDisplayName(strategy)),
                );
              }).toList(),
              onChanged: (strategy) {
                if (strategy != null) {
                  provider.setPayoffStrategy(strategy);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _getStrategyDescription(provider.selectedStrategy),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context, DebtProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_list_bulleted,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Debts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.debts.length,
          itemBuilder: (context, index) {
            final debt = provider.debts[index];
            final isPriority = debt.priority <= 3; // Priority 1-3 are priority
            return _buildDebtCard(context, debt, isPriority, debt.priority);
          },
        ),
      ],
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    Debt debt,
    bool isPriority,
    int priority,
  ) {
    final progress = debt.currentBalance > 0
        ? (debt.originalAmount - debt.currentBalance) / debt.originalAmount
        : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDebtDetails(context, debt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Priority #$priority',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _getDebtTypeIcon(debt.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                debt.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                debt.typeDisplayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(debt.currentBalance),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min Payment',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(debt.monthlyEMI),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interest Rate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${debt.interestRate.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedDebtFreeDate(DebtProvider provider) {
    final calculation = provider.debtFreeCalculation;
    final date = calculation['debtFreeDate'] as DateTime?;
    if (date == null) {
      return 'Never';
    }
    final formatter = DateFormat('MMM yyyy');
    return formatter.format(date);
  }

  String _getStrategyDisplayName(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.avalanche:
        return 'Debt Avalanche (Highest Interest First)';
      case DebtPayoffStrategy.snowball:
        return 'Debt Snowball (Smallest Balance First)';
      case DebtPayoffStrategy.custom:
        return 'Custom Order';
    }
  }

  String _getStrategyDescription(DebtPayoffStrategy strategy) {
    switch (strategy) {
      case DebtPayoffStrategy.avalanche:
        return 'Pay minimums on all debts, then put extra money toward the debt with the highest interest rate. Saves the most money.';
      case DebtPayoffStrategy.snowball:
        return 'Pay minimums on all debts, then put extra money toward the smallest balance. Provides psychological wins.';
      case DebtPayoffStrategy.custom:
        return 'Pay debts in your preferred order. You can reorder debts by priority.';
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      case DebtType.businessLoan:
        return Icons.business;
      case DebtType.goldLoan:
        return Icons.star;
      case DebtType.other:
        return Icons.account_balance;
    }
  }

  void _showAddDebtDialog(BuildContext context) async {
    await debt_modal.showAddDebtModal(context);
  }

  void _showEducationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debt Education'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debt Strategies:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Debt Avalanche: Pay highest interest rate first. Saves most money mathematically.',
              ),
              SizedBox(height: 4),
              Text(
                '• Debt Snowball: Pay smallest balance first. Provides psychological motivation.',
              ),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '• Always pay minimum on all debts\n'
                '• Put extra money toward priority debt\n'
                '• Avoid taking on new debt\n'
                '• Consider debt consolidation for high rates\n'
                '• Build emergency fund alongside debt payoff',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDebtDetails(BuildContext context, Debt debt) {
    // TODO: Navigate to debt details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Debt details for ${debt.name} coming soon!')),
    );
  }
}
