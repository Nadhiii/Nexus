import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
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

              // 4. ASSET LIST
              if (displayedAssets.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final asset = displayedAssets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SwipeToDelete(
                          itemKey: ValueKey(asset.id),
                          itemId: asset.id,
                          itemName: asset.name,
                          onDelete: () => provider.deleteInvestment(asset.id),
                          child: _buildAssetTile(context, asset),
                        ),
                      );
                    }, childCount: displayedAssets.length),
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
          backgroundColor: const Color(0xFF6366F1), // Indigo
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
        ? const [Color(0xFF065F46), Color(0xFF064E3B)] // Emerald
        : const [Color(0xFF9F1239), Color(0xFF881337)]; // Rose

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
            color: isSelected ? const Color(0xFF6366F1) : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
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

  Widget _buildAssetTile(BuildContext context, Investment asset) {
    final profit = asset.totalProfit;
    final isProfitable = profit >= 0;
    final color = isProfitable ? AppColors.success : AppColors.error;

    return GestureDetector(
      // We will create showAddInvestmentModal next
      onTap: () => showAddInvestmentModal(context, investmentToEdit: asset),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getAssetColor(asset.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAssetIcon(asset.type),
                color: _getAssetColor(asset.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    asset.type == InvestmentType.mutualFund
                        ? (asset.mutualFundSchemeCode ??
                              "NAV: ${asset.purchasePrice}")
                        : (asset.symbol ?? "Qty: ${asset.quantity}"),
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Values
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${NumberFormat.compact().format(asset.currentAmount)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isProfitable
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: color,
                      size: 16,
                    ),
                    Text(
                      "${asset.profitPercent.abs().toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
