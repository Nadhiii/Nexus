import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import 'widgets/chart_widgets.dart';
import 'widgets/report_widgets.dart';

enum TimeFilter { thisMonth, threeMonths, sixMonths, thisYear }

class ReportsAndAnalyticsScreen extends StatefulWidget {
  const ReportsAndAnalyticsScreen({super.key});

  @override
  State<ReportsAndAnalyticsScreen> createState() =>
      _ReportsAndAnalyticsScreenState();
}

class _ReportsAndAnalyticsScreenState extends State<ReportsAndAnalyticsScreen> {
  TimeFilter _selectedFilter = TimeFilter.thisMonth;

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilter) {
      case TimeFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimeFilter.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case TimeFilter.sixMonths:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case TimeFilter.thisYear:
        startDate = DateTime(now.year, 1, 1);
        break;
    }
    return allTransactions.where((t) => t.date.isAfter(startDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = Provider.of<TransactionProvider>(
      context,
    ).transactions;
    final filteredTransactions = _getFilteredTransactions(allTransactions);

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            elevation: 0,
            automaticallyImplyLeading: false, // Prevent overlap
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
              title: Text(
                'Analytics',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // 2. FILTER PILLS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildFilterRow(),
            ),
          ),

          if (filteredTransactions.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 3. HERO CARD (Cash Flow) - Moved to TOP
                  CashFlowHeroCard(transactions: filteredTransactions),
                  const SizedBox(height: 24),

                  // 4. CHART SECTION
                  Text("SPENDING BREAKDOWN", style: _headerStyle()),
                  const SizedBox(height: 12),
                  CategorySpendingChart(transactions: filteredTransactions),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimeFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: AppAnimations.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.white.withOpacity(0.05),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  _filterToText(filter),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No data available",
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            "Try selecting a different time range",
            style: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  String _filterToText(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.thisMonth:
        return 'This Month';
      case TimeFilter.threeMonths:
        return '3 Months';
      case TimeFilter.sixMonths:
        return '6 Months';
      case TimeFilter.thisYear:
        return 'This Year';
    }
  }
}
