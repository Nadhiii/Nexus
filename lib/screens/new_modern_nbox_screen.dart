import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/new_nbox_provider.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../models/detected_transaction.dart';
import '../../modules/transactions/modern_add_transaction_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NewModernNBoxScreen extends StatefulWidget {
  const NewModernNBoxScreen({super.key});

  @override
  State<NewModernNBoxScreen> createState() => _NewModernNBoxScreenState();
}

class _NewModernNBoxScreenState extends State<NewModernNBoxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedCardIds = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_isSelectionMode) {
        _exitSelectionMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleCardExpansion(String id, String source) {
    final uniqueId = '$source:$id';
    setState(() {
      if (_expandedCardIds.contains(uniqueId)) {
        _expandedCardIds.remove(uniqueId);
      } else {
        _expandedCardIds.clear();
        _expandedCardIds.add(uniqueId);
      }
    });
  }

  void _enterSelectionMode(DetectedTransaction transaction) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add('${transaction.source}:${transaction.id}');
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(DetectedTransaction transaction) {
    final uniqueId = '${transaction.source}:${transaction.id}';
    setState(() {
      if (_selectedItems.contains(uniqueId)) {
        _selectedItems.remove(uniqueId);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(uniqueId);
      }
    });
  }

  void _toggleSelectAll() {
    final nbox = context.read<NewNboxProvider>();
    final currentList = _tabController.index == 0
        ? nbox.pendingSms
        : nbox.pendingEmails;
    final allIds = currentList.map((t) => '${t.source}:${t.id}').toSet();

    setState(() {
      if (_selectedItems.length == allIds.length) {
        _selectedItems.clear();
        _isSelectionMode = false;
      } else {
        _selectedItems.addAll(allIds);
      }
    });
  }

  void _rejectSelectedItems() {
    final nbox = context.read<NewNboxProvider>();
    if (_selectedItems.isEmpty) return;

    for (final uniqueId in _selectedItems) {
      final parts = uniqueId.split(':');
      final source = parts[0];
      final id = parts[1];
      nbox.rejectTransaction(id, source, silent: true);
    }

    final count = _selectedItems.length;
    showTopNotification(
      context,
      '$count transaction${count > 1 ? 's' : ''} rejected.',
      isError: true,
    );
    _exitSelectionMode();
  }

  void _navigateToApproveScreen(DetectedTransaction transaction) async {
    if (_isSelectionMode) return;
    final nboxProvider = context.read<NewNboxProvider>();
    final success = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ModernAddTransactionScreen(detectedTransaction: transaction),
      ),
    );

    if (success == true) {
      nboxProvider.markAsApproved(transaction.id, transaction.source);
      showTopNotification(
        context,
        'Transaction from ${transaction.merchant} approved!',
      );
    }
  }

  Future<void> _refreshCurrentTab() async {
    final nboxProvider = context.read<NewNboxProvider>();
    switch (_tabController.index) {
      case 0:
        await nboxProvider.scanSmsInbox();
        break;
      case 1:
        if (nboxProvider.isGmailLinked) {
          await nboxProvider.scanEmails();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbox = context.watch<NewNboxProvider>();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkGradient.first,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.darkGradient,
                ),
              ),
            ),
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                if (_isSelectionMode) {
                  return [_buildSelectionSliverAppBar(context)];
                }
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: _buildSliverAppBar(context, innerBoxIsScrolled),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                physics: _isSelectionMode
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  _buildTransactionList(context, nbox.pendingSms, 'sms'),
                  _buildTransactionList(context, nbox.pendingEmails, 'email'),
                  _buildTransactionList(context, nbox.rejected, 'rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final nbox = context.watch<NewNboxProvider>();

    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: AppColors.darkGradient.first,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Text('NBox', style: AppTypography.headlineMedium),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.sync, size: 28, color: colorScheme.onSurfaceVariant),
          onPressed: _isSelectionMode ? null : _refreshCurrentTab,
          tooltip: 'Refresh Current Tab',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: AppColors.darkGradient.first,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: AbsorbPointer(
              absorbing: _isSelectionMode,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: colorScheme.primaryContainer,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colorScheme.onPrimaryContainer,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: textTheme.titleSmall,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'SMS (${nbox.pendingSms.length})'),
                  Tab(text: 'Email (${nbox.pendingEmails.length})'),
                  Tab(text: 'Rejected (${nbox.rejected.length})'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nbox = context.read<NewNboxProvider>();
    final currentList = _tabController.index == 0
        ? nbox.pendingSms
        : nbox.pendingEmails;
    final allSelected = _selectedItems.length == currentList.length;

    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedItems.length} selected'),
      backgroundColor: colorScheme.primaryContainer,
      actions: [
        TextButton(
          onPressed: _toggleSelectAll,
          child: Text(
            allSelected ? 'DESELECT ALL' : 'SELECT ALL',
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: _rejectSelectedItems,
          tooltip: 'Reject Selected',
        ),
      ],
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<DetectedTransaction> transactions,
    String type,
  ) {
    final nboxProvider = context.read<NewNboxProvider>();

    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            if (!_isSelectionMode)
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
            if (transactions.isEmpty)
              SliverFillRemaining(
                child: RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  child: _buildEmptyState(context, type),
                ),
              )
            else
              _buildGroupedSliverList(
                context,
                transactions,
                type,
                nboxProvider,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        );
      },
    );
  }

  Widget _buildGroupedSliverList(
    BuildContext context,
    List<DetectedTransaction> transactions,
    String type,
    NewNboxProvider nbox,
  ) {
    final Map<String, List<DetectedTransaction>> grouped = {};
    for (final transaction in transactions) {
      final dateString = _getGroupHeader(transaction.date);
      if (grouped[dateString] == null) grouped[dateString] = [];
      grouped[dateString]!.add(transaction);
    }

    final flatList = <Widget>[];
    grouped.forEach((dateString, txs) {
      flatList.add(_buildDateHeader(context, dateString));
      flatList.addAll(
        txs.map((t) {
          final uniqueId = '${t.source}:${t.id}';
          final isExpanded = _expandedCardIds.contains(uniqueId);
          final isSelected = _selectedItems.contains(uniqueId);
          return type == 'rejected'
              ? _buildRejectedTransactionCard(context, t, nbox)
              : _buildTransactionCard(context, t, nbox, isExpanded, isSelected);
        }),
      );
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => flatList[index],
        childCount: flatList.length,
      ),
    );
  }

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare.isAtSameMomentAs(today)) return 'Today';
    if (dateToCompare.isAtSameMomentAs(yesterday)) return 'Yesterday';

    return DateFormat.yMMMMd().format(date);
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

  Widget _buildEmptyState(BuildContext context, String type) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final icons = {
      'sms': Icons.sms_failed_outlined,
      'email': Icons.mark_email_read_outlined,
      'rejected': Icons.history_toggle_off,
    };
    final titles = {
      'sms': 'No SMS Transactions',
      'email': 'Email Inbox Clear',
      'rejected': 'No Rejected Items',
    };
    final subtitles = {
      'sms': 'Pull down to scan for new SMS transactions.',
      'email': 'Pull down to scan for new email transactions.',
      'rejected': 'Transactions you dismiss will appear here. Tap to restore.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icons[type],
              size: 100,
              color: colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              titles[type]!,
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subtitles[type]!,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    DetectedTransaction transaction,
    NewNboxProvider nbox,
    bool isExpanded,
    bool isSelected,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';

    return Dismissible(
      key: ValueKey('${transaction.source}:${transaction.id}'),
      direction: _isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      onDismissed: (_) {
        nbox.rejectTransaction(transaction.id, transaction.source);
        showTopNotification(
          context,
          'Transaction from ${transaction.merchant} rejected.',
          isError: true,
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Reject',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_sweep_outlined,
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : const Color(0xFF2C2C35),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _isSelectionMode
              ? _toggleSelection(transaction)
              : _toggleCardExpansion(transaction.id, transaction.source),
          onLongPress: () => _isSelectionMode
              ? _toggleSelection(transaction)
              : _enterSelectionMode(transaction),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F3F46),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            transaction.source == 'sms'
                                ? Icons.sms
                                : Icons.email,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.merchant,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.jm().format(
                                  transaction.date.toLocal(),
                                ),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isIncome
                                ? Colors.green.shade400
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const Divider(height: 30, color: Colors.white10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          transaction.body ?? 'No content available.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                nbox.rejectTransaction(
                                  transaction.id,
                                  transaction.source,
                                );
                                showTopNotification(
                                  context,
                                  'Transaction from ${transaction.merchant} rejected.',
                                  isError: true,
                                );
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('REJECT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(
                                  color: colorScheme.error.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _navigateToApproveScreen(transaction),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('APPROVE'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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

  Widget _buildRejectedTransactionCard(
    BuildContext context,
    DetectedTransaction transaction,
    NewNboxProvider nbox,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white10,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          nbox.restoreTransaction(transaction.id, transaction.source);
          showTopNotification(
            context,
            'Transaction from ${transaction.merchant} restored.',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.undo, color: colorScheme.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().format(transaction.date.toLocal()),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '₹${transaction.amount.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
