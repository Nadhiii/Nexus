import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/widgets/nexus_initial_loading.dart';
import '../../core/widgets/nexus_empty_state.dart';
import '../../core/widgets/nexus_error_state.dart';
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

  DateTime _startDateForFilter(TimeFilter filter, DateTime now) {
    switch (filter) {
      case TimeFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TimeFilter.threeMonths:
        // Calendar-accurate: 3 months back, handling year rollover.
        final month = now.month - 3;
        if (month <= 0) {
          return DateTime(now.year - 1, month + 12, now.day);
        }
        return DateTime(now.year, month, now.day);
      case TimeFilter.sixMonths:
        final month = now.month - 6;
        if (month <= 0) {
          return DateTime(now.year - 1, month + 12, now.day);
        }
        return DateTime(now.year, month, now.day);
      case TimeFilter.thisYear:
        return DateTime(now.year, 1, 1);
    }
  }

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    final now = DateTime.now();
    final startDate = _startDateForFilter(_selectedFilter, now);
    return allTransactions.where((t) => t.date.isAfter(startDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.select<TransactionProvider, bool>(
      (p) => p.isLoading && !p.isInitialized,
    );
    final error = context.select<TransactionProvider, String?>(
      (p) => p.error,
    );
    final allTransactions = context.select<TransactionProvider, List<Transaction>>(
      (p) => p.transactions,
    );
    final filteredTransactions = _getFilteredTransactions(allTransactions);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surface,
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

          if (isLoading)
            const SliverFillRemaining(child: NexusInitialLoading())
          else if (error != null)
            SliverFillRemaining(
              child: NexusErrorState(
                message: "Couldn't load analytics\n$error",
                inCard: false,
              ),
            )
          else if (filteredTransactions.isEmpty)
            const SliverFillRemaining(
              child: NexusEmptyState(
                icon: Icons.pie_chart_outline,
                title: 'No data available',
                message: 'Try selecting a different time range',
                inCard: false,
              ),
            )
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
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
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

