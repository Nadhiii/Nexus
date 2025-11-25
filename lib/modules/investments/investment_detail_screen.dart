import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/mutualfunds.dart';
import '../../core/providers/investment_provider.dart';
import 'add_investment_screen.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final investmentProvider = Provider.of<InvestmentProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isProfit =
        (investmentProvider.getInvestmentById(investment.id)?.currentValue ??
                0) -
            (investmentProvider
                    .getInvestmentById(investment.id)
                    ?.totalInvested ??
                0) >
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(investment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) =>
                    AddInvestmentScreen(investmentToEdit: investment),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text(
                    'Are you sure you want to delete this investment?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                investmentProvider.deleteInvestment(investment.id);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, investment, textTheme, colorScheme, isProfit),
            const SizedBox(height: 24),
            _buildKeyStats(context, investment, textTheme, colorScheme),
            const SizedBox(height: 24),
            // Add more widgets for charts, recent transactions, etc.
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Investment investment,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isProfit,
  ) {
    final investmentProvider = Provider.of<InvestmentProvider>(
      context,
      listen: false,
    );
    final currentInvestment = investmentProvider.getInvestmentById(
      investment.id,
    );
    final currentValue = currentInvestment?.currentValue ?? 0;
    final gainLoss = currentValue - (currentInvestment?.totalInvested ?? 0);
    final gainLossPercent = (currentInvestment?.totalInvested ?? 0) == 0
        ? 0
        : (gainLoss / (currentInvestment?.totalInvested ?? 0)) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Current Value',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${currentValue.toStringAsFixed(2)}',
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                color: isProfit ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isProfit ? '+' : ''}₹${gainLoss.toStringAsFixed(2)} (${gainLossPercent.toStringAsFixed(2)}%)',
                style: textTheme.titleMedium?.copyWith(
                  color: isProfit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStats(
    BuildContext context,
    Investment investment,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final investmentProvider = Provider.of<InvestmentProvider>(
      context,
      listen: false,
    );
    final currentInvestment = investmentProvider.getInvestmentById(
      investment.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Information',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatRow(
                  context,
                  'Invested Amount',
                  '₹${(currentInvestment?.totalInvested ?? 0).toStringAsFixed(2)}',
                ),
                _buildStatRow(
                  context,
                  'SIP Amount',
                  '₹${investment.sipAmount.toStringAsFixed(2)}',
                ),
                _buildStatRow(
                  context,
                  'SIP Day',
                  '${investment.sipDay} of every month',
                ),
                _buildStatRow(
                  context,
                  'Start Date',
                  DateFormat.yMMMd().format(investment.startDate),
                ),
                _buildStatRow(
                  context,
                  'Scheme Name',
                  investment.mutualFundSchemeName,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isLast) const Divider(height: 24, thickness: 0.5),
        ],
      ),
    );
  }
}
