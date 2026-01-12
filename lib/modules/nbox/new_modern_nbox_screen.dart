import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/new_nbox_provider.dart';
import '../../core/widgets/top_notification.dart';
import '../../core/models/detected_transaction.dart';
import '../transactions/modern_add_transaction_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum NBoxFilter { all, sms, email, trash }

class NewModernNBoxScreen extends StatefulWidget {
  const NewModernNBoxScreen({super.key});
  @override
  State<NewModernNBoxScreen> createState() => _NewModernNBoxScreenState();
}

class _NewModernNBoxScreenState extends State<NewModernNBoxScreen>
    with TickerProviderStateMixin {
  NBoxFilter _currentFilter = NBoxFilter.all;
  final Set<String> _expandedIds = {};
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    final nbox = context.read<NewNboxProvider>();
    await nbox.scanSmsInbox();
    if (nbox.isGmailLinked) await nbox.scanEmails();
  }

  // --- SELECTION LOGIC ---
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<DetectedTransaction> currentList) {
    final allIds = currentList.map((t) => '${t.source}:${t.id}').toSet();
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  void _rejectSelected() {
    final nbox = context.read<NewNboxProvider>();
    for (var uid in _selectedIds) {
      final parts = uid.split(':');
      nbox.rejectTransaction(parts[1], parts[0], silent: true);
    }
    showTopNotification(
      context,
      "${_selectedIds.length} items moved to Trash",
      isError: true,
    );
    _exitSelectionMode();
  }

  void _toggleExpand(String id) {
    if (_isSelectionMode) {
      _toggleSelection(id);
      return;
    }
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<NewNboxProvider>(
        builder: (context, nbox, child) {
          final allPending = [...nbox.pendingSms, ...nbox.pendingEmails]
            ..sort((a, b) => b.date.compareTo(a.date));

          List<DetectedTransaction> displayList;
          switch (_currentFilter) {
            case NBoxFilter.sms:
              displayList = nbox.pendingSms;
              break;
            case NBoxFilter.email:
              displayList = nbox.pendingEmails;
              break;
            case NBoxFilter.trash:
              displayList = nbox.rejected;
              break;
            case NBoxFilter.all:
            default:
              displayList = allPending;
              break;
          }

          final totalPendingValue = allPending.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

          return CustomScrollView(
            slivers: [
              _isSelectionMode
                  ? _buildSelectionHeader(displayList)
                  : _buildMainHeader(),

              if (!_isSelectionMode && _currentFilter != NBoxFilter.trash)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildInboxSummaryCard(
                      allPending.length,
                      totalPendingValue,
                    ),
                  ),
                ),

              if (!_isSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildFilterPills(
                      nbox.pendingSms.length,
                      nbox.pendingEmails.length,
                    ),
                  ),
                ),

              if (displayList.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final t = displayList[index];
                      final showHeader =
                          index == 0 ||
                          !_isSameDay(t.date, displayList[index - 1].date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) _buildDateHeader(t.date),
                          _buildStreamItem(
                            t,
                            index == displayList.length - 1,
                            _currentFilter == NBoxFilter.trash,
                          ),
                        ],
                      );
                    }, childCount: displayList.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- HEADERS ---
  Widget _buildMainHeader() {
    return SliverAppBar(
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
          'Inbox',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(
              Icons.sync,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSelectionHeader(List<DetectedTransaction> list) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.cardSurface,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedIds.length} Selected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _toggleSelectAll(list),
          child: const Text(
            "Select All",
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: _rejectSelected,
        ),
      ],
    );
  }

  // --- REBUILT LIST ITEM (STACK-BASED) ---
  Widget _buildStreamItem(DetectedTransaction t, bool isLast, bool isTrashTab) {
    final uniqueId = '${t.source}:${t.id}';
    final isExpanded = _expandedIds.contains(uniqueId);
    final isSelected = _selectedIds.contains(uniqueId);
    final isIncome = t.type.toLowerCase() == 'income';
    final isSms = t.source == 'sms';

    final highlightColor = isSms
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);
    final borderColor = isSelected
        ? AppColors.primaryBlue
        : (isExpanded ? Colors.white.withOpacity(0.15) : Colors.transparent);
    final bgColor = isSelected
        ? AppColors.primaryBlue.withOpacity(0.1)
        : (isExpanded ? AppColors.cardSurface : Colors.transparent);

    // FIX: Replaced IntrinsicHeight with Stack
    return Stack(
      children: [
        // 1. TIMELINE LINE (Background Layer)
        Positioned(
          left: 30, // Centered under the dot
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: isLast ? Colors.transparent : AppColors.cardSurface,
          ),
        ),

        // 2. CONTENT ROW (Foreground Layer)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Timeline Dot (Clickable)
              GestureDetector(
                onTap: () => _toggleSelection(uniqueId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 60, // Fixed width column for alignment
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.backgroundBlack,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : highlightColor,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? []
                          : [
                              BoxShadow(
                                color: highlightColor.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
              ),

              // B. The Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => _toggleExpand(uniqueId),
                    onLongPress: () => _enterSelectionMode(uniqueId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      // FIX: Clip content to prevent overflow during shrink
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- HEADER (Always Visible) ---
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.merchant,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${isIncome ? '+' : ''}₹${t.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome
                                            ? AppColors.pastelGreen
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildTag(
                                      isSms ? "SMS" : "EMAIL",
                                      highlightColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('hh:mm a').format(t.date),
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // --- EXPANDED SECTION (Animated) ---
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: isExpanded && !_isSelectionMode
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.05),
                                      ),

                                      // 1. ANALYSIS
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          8,
                                        ),
                                        child: Text(
                                          "DETECTED DATA",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildAnalysisChip(
                                              Icons.store,
                                              t.merchant,
                                            ),
                                            _buildAnalysisChip(
                                              Icons.currency_rupee,
                                              t.amount.toString(),
                                            ),
                                            _buildAnalysisChip(
                                              Icons.calendar_today,
                                              DateFormat(
                                                'dd MMM',
                                              ).format(t.date),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // 2. RAW SOURCE
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          8,
                                        ),
                                        child: Text(
                                          "SOURCE MESSAGE",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          t.body ?? "No content",
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // 3. ACTION BAR
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface
                                              .withOpacity(0.5),
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: isTrashTab
                                              ? [
                                                  Expanded(
                                                    child: _buildActionButton(
                                                      "Restore to Inbox",
                                                      Icons.restore,
                                                      Colors.white,
                                                      AppColors.cardElevated,
                                                      () {
                                                        context
                                                            .read<
                                                              NewNboxProvider
                                                            >()
                                                            .restoreTransaction(
                                                              t.id,
                                                              t.source,
                                                            );
                                                        showTopNotification(
                                                          context,
                                                          "Restored",
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ]
                                              : [
                                                  Expanded(
                                                    child: _buildActionButton(
                                                      "Reject",
                                                      Icons.close,
                                                      AppColors.error,
                                                      AppColors.error
                                                          .withOpacity(0.1),
                                                      () =>
                                                          _rejectTransaction(t),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: _buildActionButton(
                                                      "Approve",
                                                      Icons.check,
                                                      Colors.white,
                                                      AppColors.primaryBlue,
                                                      () =>
                                                          _navigateToApproveScreen(
                                                            t,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildAnalysisChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color fg,
    Color bg,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInboxSummaryCard(int count, double totalValue) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTION REQUIRED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Items',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(totalValue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(int smsCount, int emailCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill("All", NBoxFilter.all),
          _buildPill("SMS ($smsCount)", NBoxFilter.sms),
          _buildPill("Email ($emailCount)", NBoxFilter.email),
          _buildPill("Trash", NBoxFilter.trash),
        ],
      ),
    );
  }

  Widget _buildPill(String label, NBoxFilter value) {
    final isSelected = _currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white10,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String label = DateFormat('MMM dd').format(date);
    final now = DateTime.now();
    if (_isSameDay(date, now))
      label = "Today";
    else if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      label = "Yesterday";
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox,
          size: 64,
          color: AppColors.textTertiary.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text("All Caught Up", style: TextStyle(color: AppColors.textTertiary)),
      ],
    ),
  );

  void _rejectTransaction(DetectedTransaction t) {
    context.read<NewNboxProvider>().rejectTransaction(t.id, t.source);
    showTopNotification(context, "Moved to Trash", isError: true);
  }

  void _navigateToApproveScreen(DetectedTransaction t) async {
    final nbox = context.read<NewNboxProvider>();
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModernAddTransactionScreen(detectedTransaction: t),
      ),
    );
    if (success == true) {
      nbox.markAsApproved(t.id, t.source);
      if (mounted) showTopNotification(context, "Verified & Added");
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
