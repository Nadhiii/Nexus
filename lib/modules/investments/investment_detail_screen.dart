import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isProfit = investment.isProfitable;

    return Scaffold(
      appBar: AppBar(
        title: Text(investment.name),
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Investment'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete Investment',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getInvestmentTypeIcon(investment.type),
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investment.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      investment.symbol,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getInvestmentTypeLabel(investment.type),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Current Value and P&L
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Value',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            Text(
                              '₹${investment.currentValue.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isProfit
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: isProfit ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'P&L',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              investment.formattedGainLoss,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: isProfit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isProfit ? Colors.green : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${isProfit ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(2)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isProfit ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Investment Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailRow(
                      context,
                      'Holdings',
                      '${investment.units.toStringAsFixed(2)} ${_getUnitsLabel(investment.type)}',
                      Icons.inventory,
                    ),

                    _buildDetailRow(
                      context,
                      'Average Price',
                      '₹${investment.averagePrice.toStringAsFixed(2)}',
                      Icons.price_change,
                    ),

                    _buildDetailRow(
                      context,
                      'Current Price',
                      '₹${investment.currentPrice.toStringAsFixed(2)}',
                      Icons.trending_up,
                    ),

                    _buildDetailRow(
                      context,
                      'Total Invested',
                      '₹${investment.totalInvested.toStringAsFixed(2)}',
                      Icons.savings,
                    ),

                    _buildDetailRow(
                      context,
                      'Last Updated',
                      _formatDate(investment.lastUpdated),
                      Icons.update,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Performance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildPerformanceMetric(
                            context,
                            'Total Return',
                            investment.formattedGainLoss,
                            isProfit ? Colors.green : Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildPerformanceMetric(
                            context,
                            'Return %',
                            '${isProfit ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(2)}%',
                            isProfit ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildPerformanceMetric(
                            context,
                            'Price Change',
                            '₹${(investment.currentPrice - investment.averagePrice).toStringAsFixed(2)}',
                            investment.currentPrice >= investment.averagePrice
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildPerformanceMetric(
                            context,
                            'Days Held',
                            '${DateTime.now().difference(investment.createdAt).inDays}',
                            theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpdatePriceDialog(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update Price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showTransactionDialog(context),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPerformanceMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getInvestmentTypeLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'Stock';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.etf:
        return 'ETF';
      case InvestmentType.bond:
        return 'Bond';
      case InvestmentType.crypto:
        return 'Cryptocurrency';
      case InvestmentType.commodity:
        return 'Commodity';
      case InvestmentType.reit:
        return 'REIT';
      case InvestmentType.other:
        return 'Other';
    }
  }

  IconData _getInvestmentTypeIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return Icons.trending_up;
      case InvestmentType.mutualFund:
        return Icons.account_balance;
      case InvestmentType.etf:
        return Icons.pie_chart;
      case InvestmentType.bond:
        return Icons.receipt_long;
      case InvestmentType.crypto:
        return Icons.currency_bitcoin;
      case InvestmentType.commodity:
        return Icons.agriculture;
      case InvestmentType.reit:
        return Icons.apartment;
      case InvestmentType.other:
        return Icons.category;
    }
  }

  String _getUnitsLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'shares';
      case InvestmentType.mutualFund:
        return 'units';
      case InvestmentType.etf:
        return 'units';
      case InvestmentType.bond:
        return 'units';
      case InvestmentType.crypto:
        return 'coins';
      case InvestmentType.commodity:
        return 'units';
      case InvestmentType.reit:
        return 'units';
      case InvestmentType.other:
        return 'units';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text(
          'Are you sure you want to delete "${investment.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _deleteInvestment(context),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteInvestment(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      final provider = Provider.of<InvestmentProvider>(context, listen: false);
      await provider.deleteInvestment(investment.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to portfolio
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete investment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdatePriceDialog(BuildContext context) {
    final priceController = TextEditingController(
      text: investment.currentPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Current Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update the current market price for ${investment.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Current Price (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _updatePrice(context, priceController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updatePrice(BuildContext context, String priceText) async {
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    try {
      final updatedInvestment = investment.copyWith(
        currentPrice: price,
        currentValue: investment.units * price,
        lastUpdated: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<InvestmentProvider>(context, listen: false);
      await provider.updateInvestment(updatedInvestment);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update price: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTransactionDialog(BuildContext context) {
    // TODO: Implement transaction dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction tracking coming soon!')),
    );
  }
}
