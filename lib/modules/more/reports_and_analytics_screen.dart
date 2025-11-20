import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/chart_widgets.dart';
import 'widgets/report_widgets.dart';

enum TimeFilter { thisMonth, threeMonths, sixMonths, thisYear }

class ReportsAndAnalyticsScreen extends StatefulWidget {
  const ReportsAndAnalyticsScreen({super.key});

  @override
  _ReportsAndAnalyticsScreenState createState() =>
      _ReportsAndAnalyticsScreenState();
}

class _ReportsAndAnalyticsScreenState extends State<ReportsAndAnalyticsScreen> {
  TimeFilter _selectedFilter = TimeFilter.thisMonth;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedFilter.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(
      List<Transaction> allTransactions, TimeFilter filter) {
    final now = DateTime.now();
    DateTime startDate;

    switch (filter) {
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
    final allTransactions =
        Provider.of<TransactionProvider>(context, listen: false).transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: _buildPeriodSelector(),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: TimeFilter.values.length,
              onPageChanged: (index) {
                // This is now the single source of truth for state changes
                setState(() {
                  _selectedFilter = TimeFilter.values[index];
                });
              },
              itemBuilder: (context, index) {
                final filter = TimeFilter.values[index];
                final filteredTransactions = _getFilteredTransactions(allTransactions, filter);

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyState(filter: filter);
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      CategorySpendingChart(transactions: filteredTransactions),
                      const SizedBox(height: AppSpacing.lg),
                      TransactionAnalysisSummary(transactions: filteredTransactions),
                      const SizedBox(height: AppSpacing.xl2), // Bottom padding
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TimeFilter>(
        segments: const [
          ButtonSegment(
              value: TimeFilter.thisMonth,
              label: Text('This Month'),
              icon: Icon(Icons.calendar_view_month_outlined)),
          ButtonSegment(value: TimeFilter.threeMonths, label: Text('3M')),
          ButtonSegment(value: TimeFilter.sixMonths, label: Text('6M')),
          ButtonSegment(
              value: TimeFilter.thisYear,
              label: Text('This Year'),
              icon: Icon(Icons.calendar_today_outlined)),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (newSelection) {
          // The conflicting setState is removed. We only command the controller.
          _pageController.animateToPage(
            newSelection.first.index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        },
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
          selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required TimeFilter filter}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No transactions found for \'${_filterToText(filter)}\'.'),
          const Text('Your financial reports will appear here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _filterToText(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.thisMonth:
        return 'This Month';
      case TimeFilter.threeMonths:
        return 'Last 3 Months';
      case TimeFilter.sixMonths:
        return 'Last 6 Months';
      case TimeFilter.thisYear:
        return 'This Year';
    }
  }
}
