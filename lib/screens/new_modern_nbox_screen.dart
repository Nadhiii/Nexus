import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/providers/new_nbox_provider.dart';
import '../models/detected_sms_transaction.dart';
import '../modules/transactions/modern_add_transaction_screen.dart';

class NewModernNBoxScreen extends StatefulWidget {
  const NewModernNBoxScreen({super.key});

  @override
  State<NewModernNBoxScreen> createState() => _NewModernNBoxScreenState();
}

class _NewModernNBoxScreenState extends State<NewModernNBoxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedSmsIds = {}; // To track expanded cards

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleCardExpansion(String smsId) {
    setState(() {
      _expandedSmsIds.clear(); // Collapse all others
      if (!_expandedSmsIds.contains(smsId)) {
        _expandedSmsIds.add(smsId);
      }
    });
  }

  void _navigateToApproveScreen(DetectedSmsTransaction transaction) async {
    final nboxProvider = context.read<NewNboxProvider>();
    final success = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernAddTransactionScreen(
          detectedSmsTransaction: transaction,
        ),
      ),
    );

    if (success == true) {
      await nboxProvider.markAsApproved(transaction.smsId);
    }
  }

  // FINAL IMPROVEMENT: AppBar and TabBar style now has a premium, modern feel.
  AppBar _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final nbox = context.watch<NewNboxProvider>();

    return AppBar(
      title: Text('NBox', style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.sync, size: 28, color: colorScheme.onSurfaceVariant),
          onPressed: () => context.read<NewNboxProvider>().scanSmsInbox(),
          tooltip: 'Scan SMS',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: colorScheme.primaryContainer,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: colorScheme.onPrimaryContainer,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: textTheme.titleSmall,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Pending (${nbox.pendingTransactions.length})'),
              Tab(text: 'Rejected (${nbox.rejectedTransactions.length})'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nbox = context.watch<NewNboxProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context),
      body: nbox.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(context, nbox.pendingTransactions, false),
                _buildTransactionList(context, nbox.rejectedTransactions, true),
              ],
            ),
    );
  }

  Widget _buildTransactionList(BuildContext context, List<DetectedSmsTransaction> transactions, bool isRejectedList) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context, isRejectedList);
    }

    final Map<String, List<DetectedSmsTransaction>> grouped = {};
    for (final transaction in transactions) {
      final dateString = _getGroupHeader(transaction.date);
      if (grouped[dateString] == null) {
        grouped[dateString] = [];
      }
      grouped[dateString]!.add(transaction);
    }

    final List<Widget> listItems = [];
    grouped.forEach((dateString, transactions) {
      listItems.add(_buildDateHeader(context, dateString));
      listItems.addAll(transactions.map((t) {
        final isExpanded = _expandedSmsIds.contains(t.smsId);
        return isRejectedList
            ? _buildRejectedTransactionCard(context, t, context.read<NewNboxProvider>())
            : _buildTransactionCard(context, t, context.read<NewNboxProvider>(), isExpanded);
      }));
    });

    return RefreshIndicator(
      onRefresh: () => context.read<NewNboxProvider>().scanSmsInbox(),
      child: ListView(padding: const EdgeInsets.only(top: 8), children: listItems),
    );
  }

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Today';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMMd().format(date);
    }
  }

  Widget _buildDateHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isRejectedList) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isRejectedList ? Icons.history_toggle_off : Icons.mark_email_read_outlined, size: 100, color: colorScheme.secondary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              isRejectedList ? 'No Rejected Items' : 'NBox is Clear',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isRejectedList
                  ? 'Transactions you dismiss will appear here. Tap to restore.'
                  : 'When new transactions are detected, they will appear here.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, DetectedSmsTransaction transaction, NewNboxProvider nbox, bool isExpanded) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';

    return Dismissible(
      key: ValueKey(transaction.smsId),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) {
        nbox.rejectTransaction(transaction.smsId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction from ${transaction.merchant} rejected.'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => nbox.restoreTransaction(transaction.smsId),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: colorScheme.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggleCardExpansion(transaction.smsId),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                      child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green.shade600 : colorScheme.error, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(transaction.merchant, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(DateFormat.jm().format(transaction.date), style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: isIncome ? Colors.green.shade600 : colorScheme.error)),
                  ],
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => nbox.rejectTransaction(transaction.smsId),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('REJECT'),
                            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, side: BorderSide(color: colorScheme.error.withOpacity(0.4))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _navigateToApproveScreen(transaction),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('APPROVE'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedTransactionCard(BuildContext context, DetectedSmsTransaction transaction, NewNboxProvider nbox) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: colorScheme.surfaceVariant.withOpacity(0.5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => nbox.restoreTransaction(transaction.smsId),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(Icons.undo, color: Colors.grey, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.merchant, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(DateFormat.yMMMd().format(transaction.date), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text('₹${transaction.amount.toStringAsFixed(2)}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}
