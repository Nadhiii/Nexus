import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/add_investment_modal.dart';

class ModernInvestmentScreen extends StatefulWidget {
  const ModernInvestmentScreen({super.key});

  @override
  State<ModernInvestmentScreen> createState() => _ModernInvestmentScreenState();
}

class _ModernInvestmentScreenState extends State<ModernInvestmentScreen> {
  InvestmentType? _filterType;

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assuming loadInvestments is handled by parent or init, but safe to call if needed
      // context.read<InvestmentProvider>().loadInvestments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<InvestmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAssets = provider.investments;
          final displayedAssets = _filterType == null
              ? allAssets
              : allAssets.where((a) => a.type == _filterType).toList();

          return CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                  title: Text(
                    'Portfolio',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // 2. WEALTH COMMAND (Hero Card)
              if (allAssets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildWealthCommandCard(allAssets),
                  ),
                ),

              // 3. ASSET CLASS PILLS
              if (allAssets.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildFilterRow(),
                  ),
                ),

              // 4. ASSET BENTO GRID
              if (displayedAssets.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    child: _buildAssetBentoGrid(
                      context,
                      displayedAssets,
                      provider,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          onPressed: () => showAddInvestmentModal(context),
          backgroundColor: AppColors.investmentIndigo,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Asset',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildWealthCommandCard(List<Investment> assets) {
    double currentVal = 0;
    double investedVal = 0;

    for (var a in assets) {
      currentVal += a.currentAmount;
      investedVal += a.investedAmount;
    }

    final profit = currentVal - investedVal;
    final isProfitable = profit >= 0;
    final percent = investedVal > 0 ? (profit / investedVal) * 100 : 0.0;

    // "Bloomberg" Gradient
    final gradient = isProfitable
        ? AppColors.profitGradient
        : AppColors.lossGradient;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
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
                'TOTAL PORTFOLIO',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isProfitable ? "PROFIT" : "LOSS",
                  style: TextStyle(
                    color: isProfitable ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(currentVal)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),

          // P&L Row
          Row(
            children: [
              Icon(
                isProfitable ? Icons.trending_up : Icons.trending_down,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isProfitable ? '+' : ''}₹${NumberFormat.compact().format(profit)} (${percent.toStringAsFixed(2)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill("All", null),
          _buildPill("Mutual Funds", InvestmentType.mutualFund),
          _buildPill("Stocks", InvestmentType.stock),
          _buildPill("Crypto", InvestmentType.crypto),
          _buildPill("Gold", InvestmentType.gold),
        ],
      ),
    );
  }

  Widget _buildPill(String label, InvestmentType? type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.investmentIndigo
                : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.investmentIndigo
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetBentoGrid(
    BuildContext context,
    List<Investment> assets,
    InvestmentProvider provider,
  ) {
    if (assets.isEmpty) return _buildEmptyState();

    List<Widget> tiles = [];

    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      // Pattern: Large, Small, Small, Wide, Small, Small, repeat
      final patternIndex = i % 6;
      final isLarge = patternIndex == 0;
      final isWide = patternIndex == 3;

      tiles.add(
        _buildPremiumAssetTile(
          context,
          asset,
          provider,
          isLarge: isLarge,
          isWide: isWide,
        ),
      );
    }

    // Build grid layout
    List<Widget> rows = [];
    int index = 0;

    while (index < tiles.length) {
      final patternIndex = index % 6;

      if (patternIndex == 0 && index < tiles.length) {
        // Large tile (full width) + 2 small tiles stacked
        final large = tiles[index];
        final smallTiles = <Widget>[];
        if (index + 1 < tiles.length) {
          smallTiles.add(Expanded(child: tiles[index + 1]));
        }
        if (index + 2 < tiles.length) {
          smallTiles.add(const SizedBox(height: 12));
        }
        if (index + 2 < tiles.length) {
          smallTiles.add(Expanded(child: tiles[index + 2]));
        }

        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: large),
                  if (smallTiles.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: smallTiles.isEmpty
                            ? [const Spacer()]
                            : smallTiles,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        index += 3;
      } else if (patternIndex == 3 && index < tiles.length) {
        // Wide tile (full width)
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: tiles[index],
          ),
        );
        index += 1;
      } else {
        // Two small tiles side by side
        final tile1 = tiles[index];
        Widget? tile2;
        if (index + 1 < tiles.length &&
            (index + 1) % 6 != 0 &&
            (index + 1) % 6 != 3) {
          tile2 = tiles[index + 1];
        }

        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 94,
              child: Row(
                children: [
                  Expanded(child: tile1),
                  if (tile2 != null) ...[
                    const SizedBox(width: 12),
                    Expanded(child: tile2),
                  ],
                ],
              ),
            ),
          ),
        );
        index += tile2 != null ? 2 : 1;
      }
    }

    return Column(children: rows);
  }

  Widget _buildPremiumAssetTile(
    BuildContext context,
    Investment asset,
    InvestmentProvider provider, {
    bool isLarge = false,
    bool isWide = false,
  }) {
    final profit = asset.totalProfit;
    final isProfitable = profit >= 0;
    final color = isProfitable ? AppColors.success : AppColors.error;
    final assetColor = _getAssetColor(asset.type);

    if (isLarge) {
      // Premium Large Tile with gradient
      return GestureDetector(
        onTap: () => showAddInvestmentModal(context, investmentToEdit: asset),
        onLongPress: () => _showDeleteDialog(context, asset, provider),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                assetColor.withOpacity(0.2),
                assetColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: assetColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: assetColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: assetColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAssetIcon(asset.type),
                      color: assetColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfitable
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: color,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isProfitable ? '+' : ''}${asset.profitPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                asset.name,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getAssetTypeName(asset.type),
                style: TextStyle(
                  color: assetColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${NumberFormat('#,##,###').format(asset.currentAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isWide) {
      // Wide horizontal tile
      return GestureDetector(
        onTap: () => showAddInvestmentModal(context, investmentToEdit: asset),
        onLongPress: () => _showDeleteDialog(context, asset, provider),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [assetColor.withOpacity(0.15), AppColors.cardSurface],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: assetColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assetColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getAssetIcon(asset.type),
                  color: assetColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      asset.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getAssetTypeName(asset.type),
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${NumberFormat.compact().format(asset.currentAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProfitable
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: color,
                        size: 18,
                      ),
                      Text(
                        '${isProfitable ? '+' : ''}${asset.profitPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Compact small tile
      return GestureDetector(
        onTap: () => showAddInvestmentModal(context, investmentToEdit: asset),
        onLongPress: () => _showDeleteDialog(context, asset, provider),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: assetColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getAssetIcon(asset.type), color: assetColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      asset.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${NumberFormat.compact().format(asset.currentAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isProfitable ? '+' : ''}${asset.profitPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    Investment asset,
    InvestmentProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete ${asset.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteInvestment(asset.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.candlestick_chart,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Portfolio Empty",
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            "Start building your wealth today",
            style: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAssetColor(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto:
        return Colors.orange;
      case InvestmentType.gold:
        return Colors.amber;
      case InvestmentType.stock:
        return Colors.blue;
      case InvestmentType.mutualFund:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getAssetTypeName(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto:
        return 'Cryptocurrency';
      case InvestmentType.gold:
        return 'Gold';
      case InvestmentType.stock:
        return 'Stocks';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      default:
        return 'Investment';
    }
  }

  IconData _getAssetIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.crypto:
        return Icons.currency_bitcoin;
      case InvestmentType.gold:
        return Icons.monetization_on;
      case InvestmentType.stock:
        return Icons.show_chart;
      case InvestmentType.mutualFund:
        return Icons.pie_chart;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
