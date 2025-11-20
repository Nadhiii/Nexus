import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart';
import 'widgets/add_investment_modal.dart' as investment_modal;
import 'investment_detail_screen.dart';

class ModernInvestmentPortfolioScreen extends StatefulWidget {
  const ModernInvestmentPortfolioScreen({super.key});

  @override
  State<ModernInvestmentPortfolioScreen> createState() =>
      _ModernInvestmentPortfolioScreenState();
}

class _ModernInvestmentPortfolioScreenState
    extends State<ModernInvestmentPortfolioScreen> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Consumer<InvestmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.investments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _buildErrorState(context, provider);
          }
          if (provider.investments.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: provider.refreshPrices,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, provider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildPortfolioCard(context, provider),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFilterTabs(context),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                _buildInvestmentList(context, provider),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => investment_modal.showAddInvestmentModal(context),
          backgroundColor: colorScheme.secondary,
          icon: const Icon(Icons.add),
          label: const Text('Add Investment'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, InvestmentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Investments',
          style: AppTypography.headlineMedium,
        ),
      ),
      actions: [
        if (provider.lastPriceUpdate != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                provider.getTimeSinceLastUpdate() ?? '',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: provider.isUpdatingPrices
              ? null
              : () => _refreshPrices(provider),
          icon: provider.isUpdatingPrices
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Refresh Prices',
        ),
        IconButton(
          onPressed: () => _showPriceUpdateSettings(context, provider),
          icon: Icon(
            provider.autoRefreshEnabled ? Icons.sync : Icons.sync_disabled,
            color: provider.autoRefreshEnabled ? Colors.green : null,
          ),
          tooltip: 'Auto-Refresh Settings',
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(
    BuildContext context,
    InvestmentProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary,
            colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Value',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSecondary.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: AppTypography.headlineMedium.copyWith(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  provider.totalPortfolioValue.toStringAsFixed(2),
                  style: AppTypography.currencyLarge.copyWith(
                    color: colorScheme.onSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Invested ${provider.formattedTotalInvested} • ${provider.investments.length} Assets • ${provider.formattedGainLoss}',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tabs = ['All', 'Stocks', 'Mutual Funds', 'ETFs', 'Crypto'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvestmentList(
    BuildContext context,
    InvestmentProvider provider,
  ) {
    List<Investment> filteredInvestments = _getFilteredInvestments(provider);
    final colorScheme = Theme.of(context).colorScheme;

    if (filteredInvestments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No ${_selectedTab.toLowerCase()} investments found',
                style: AppTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final investment = filteredInvestments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildInvestmentCard(context, investment),
          );
        }, childCount: filteredInvestments.length),
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, Investment investment) {
    final colorScheme = Theme.of(context).colorScheme;
    final isProfit = investment.gainLoss > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                InvestmentDetailScreen(investment: investment),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getInvestmentTypeColor(
                      investment.type,
                      colorScheme,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _getInvestmentTypeIcon(investment.type),
                    color: _getInvestmentTypeColor(
                      investment.type,
                      colorScheme,
                    ),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        investment.symbol.isNotEmpty
                            ? investment.symbol
                            : _getInvestmentTypeLabel(investment.type),
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Value',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${investment.currentValue.toStringAsFixed(2)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P&L',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${isProfit ? '+' : ''}₹${investment.gainLoss.toStringAsFixed(2)}',
                          style: AppTypography.titleSmall.copyWith(
                            color: isProfit ? Colors.green : colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isProfit ? Colors.green : colorScheme.error)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            '${isProfit ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(1)}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: isProfit
                                  ? Colors.green
                                  : colorScheme.error,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 120,
              color: colorScheme.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Start Your Investment Journey',
              style: AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Track your stocks, mutual funds, and other investments all in one place.',
              style: AppTypography.bodyLarge.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => investment_modal.showAddInvestmentModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.lg,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add First Investment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, InvestmentProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              provider.error!,
              style: AppTypography.bodyLarge.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: provider.initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Investment> _getFilteredInvestments(InvestmentProvider provider) {
    switch (_selectedTab) {
      case 'Stocks':
        return provider.getInvestmentsByType(InvestmentType.stock);
      case 'Mutual Funds':
        return provider.getInvestmentsByType(InvestmentType.mutualFund);
      case 'ETFs':
        return provider.getInvestmentsByType(InvestmentType.etf);
      case 'Crypto':
        return provider.getInvestmentsByType(InvestmentType.crypto);
      default:
        return provider.investments;
    }
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

  Color _getInvestmentTypeColor(InvestmentType type, ColorScheme colorScheme) {
    switch (type) {
      case InvestmentType.stock:
        return colorScheme.secondary;
      case InvestmentType.mutualFund:
        return colorScheme.tertiary;
      case InvestmentType.etf:
        return Colors.blue;
      case InvestmentType.bond:
        return Colors.green;
      case InvestmentType.crypto:
        return Colors.orange;
      case InvestmentType.commodity:
        return Colors.amber;
      case InvestmentType.reit:
        return Colors.pink;
      case InvestmentType.other:
        return Colors.grey;
    }
  }

  Future<void> _refreshPrices(InvestmentProvider provider) async {
    final result = await provider.updateAllPrices();

    if (!mounted) return;

    if (result['success'] == true) {
      final updated = result['updated'] ?? 0;
      final failed = result['failed'] ?? 0;

      showTopSnackBar(
        context,
        updated > 0
            ? 'Updated $updated ${updated == 1 ? 'investment' : 'investments'}${failed > 0 ? ', $failed failed' : ''}'
            : result['message'] ?? 'No investments to update',
      );
    } else {
      showTopSnackBar(
        context,
        result['message'] ?? 'Failed to update prices',
        isError: true,
      );
    }
  }

  void _showPriceUpdateSettings(
    BuildContext context,
    InvestmentProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => Consumer<InvestmentProvider>(
        builder: (context, provider, child) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Auto-Refresh Settings',
                      style: AppTypography.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable Auto-Refresh'),
                    subtitle: Text(
                      provider.autoRefreshEnabled
                          ? 'Prices update automatically every ${provider.autoRefreshIntervalMinutes} minutes'
                          : 'Prices only update manually',
                    ),
                    value: provider.autoRefreshEnabled,
                    onChanged: (value) {
                      provider.setAutoRefreshEnabled(value);
                      if (value) {
                        showTopSnackBar(
                          context,
                          'Auto-refresh enabled. Updating prices...',
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (provider.lastPriceUpdate != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.update),
                      title: const Text('Last Updated'),
                      subtitle: Text(
                        '${provider.getTimeSinceLastUpdate()}\n${provider.lastPriceUpdate}',
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (provider.autoRefreshEnabled) ...[
                  Text('Update Frequency', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<int>(
                          title: const Text('Every 5 minutes'),
                          subtitle: const Text('For active traders'),
                          value: 5,
                          groupValue: provider.autoRefreshIntervalMinutes,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setAutoRefreshInterval(value);
                            }
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('Every 15 minutes'),
                          subtitle: const Text('Balanced (recommended)'),
                          value: 15,
                          groupValue: provider.autoRefreshIntervalMinutes,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setAutoRefreshInterval(value);
                            }
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('Every 30 minutes'),
                          subtitle: const Text('Moderate updates'),
                          value: 30,
                          groupValue: provider.autoRefreshIntervalMinutes,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setAutoRefreshInterval(value);
                            }
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('Every hour'),
                          subtitle: const Text('Conservative'),
                          value: 60,
                          groupValue: provider.autoRefreshIntervalMinutes,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setAutoRefreshInterval(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: provider.isUpdatingPrices
                      ? null
                      : () {
                          Navigator.pop(context);
                          _refreshPrices(provider);
                        },
                  icon: provider.isUpdatingPrices
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Refresh Now'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Auto-Refresh',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Only Mutual Funds update automatically\n'
                          '• Uses free Indian Mutual Fund API\n'
                          '• Updates NAV (Net Asset Value) in real-time\n'
                          '• Portfolio value recalculates automatically',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
