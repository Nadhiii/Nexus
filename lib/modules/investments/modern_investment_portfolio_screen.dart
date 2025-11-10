import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
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
                const SliverToBoxAdapter(
                  child: SizedBox(height: 140),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => investment_modal.showAddInvestmentModal(context),
          backgroundColor: AppColors.accentTeal,
          icon: const Icon(Icons.add),
          label: const Text('Add Investment'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, InvestmentProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkGradient.first,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Investments',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          onPressed: provider.isLoading ? null : () => provider.refreshPrices(),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Refresh Prices',
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(BuildContext context, InvestmentProvider provider) {
    return Container(
      padding: AppSpacing.cardPaddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.tealGradient,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealGradient.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Value',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  provider.totalPortfolioValue.toStringAsFixed(2),
                  style: AppTypography.currencyLarge.copyWith(
                    color: Colors.white,
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
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cardDarkElevated
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedTab = tab),
                child: Center(
                  child: Text(
                    tab,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.accentTeal
                          : Colors.white.withOpacity(0.6),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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

    if (filteredInvestments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No ${_selectedTab.toLowerCase()} investments found',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.7),
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
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final investment = filteredInvestments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildInvestmentCard(context, investment),
            );
          },
          childCount: filteredInvestments.length,
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, Investment investment) {
    final isProfit = investment.gainLoss > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvestmentDetailScreen(investment: investment),
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
                    color: _getInvestmentTypeColor(investment.type)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _getInvestmentTypeIcon(investment.type),
                    color: _getInvestmentTypeColor(investment.type),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        investment.symbol.isNotEmpty
                            ? investment.symbol
                            : _getInvestmentTypeLabel(investment.type),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
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
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${investment.currentValue.toStringAsFixed(2)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
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
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${isProfit ? '+' : ''}₹${investment.gainLoss.toStringAsFixed(2)}',
                          style: AppTypography.titleSmall.copyWith(
                            color: isProfit ? Colors.green : Colors.red,
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
                            color: (isProfit ? Colors.green : Colors.red)
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            '${isProfit ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(1)}%',
                            style: AppTypography.bodySmall.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 120,
              color: AppColors.accentTeal.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Start Your Investment Journey',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Track your stocks, mutual funds, and other investments all in one place.',
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton.icon(
              onPressed: () => investment_modal.showAddInvestmentModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              provider.error!,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: provider.initialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
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

  Color _getInvestmentTypeColor(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return AppColors.accentTeal;
      case InvestmentType.mutualFund:
        return AppColors.accentPurple;
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
}
