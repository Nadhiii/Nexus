import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/nbox_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/knowledge_provider.dart';
import '../../core/services/transaction_intent_classifier.dart';
import '../../core/services/transaction_automation_service.dart';
import '../../core/services/transaction_router.dart';
import '../../core/widgets/top_notification.dart';
import '../../core/models/detected_transaction.dart';
import '../../core/models/transaction.dart';
import '../transactions/add_transaction_screen.dart';
import '../payday/payday_screen.dart';
import 'smart_approval_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/nexus_inline_loading.dart';
import '../../core/widgets/nexus_empty_state.dart';
import '../../core/widgets/nexus_button.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/pdf_statement_import_service.dart';

enum NBoxFilter { all, sms, email, pdf, trash }

enum NBoxViewMode { list, focus }

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
  bool _isSmsLoading = false;
  bool _isGmailLoading = false;

  bool _isApprovalScreenOpen = false;

  late final NewNboxProvider _nboxProvider;

  NBoxViewMode _viewMode = NBoxViewMode.list;

  Set<String>? _focusQueueIds;

  bool _isBulkApproving = false;

  Future<void> _refreshSms() async {
    if (!mounted) return;
    setState(() => _isSmsLoading = true);
    await context.read<NewNboxProvider>().scanSmsInbox();
    if (mounted) setState(() => _isSmsLoading = false);
  }

  Future<void> _refreshGmail() async {
    if (!mounted) return;
    setState(() => _isGmailLoading = true);
    final nbox = context.read<NewNboxProvider>();
    if (nbox.isGmailLinked) {
      await nbox.scanEmails();
    }
    if (mounted) setState(() => _isGmailLoading = false);
  }

  bool _isPdfLoading = false;

  Future<void> _importPdf() async {
    if (!mounted) return;
    setState(() => _isPdfLoading = true);
    try {
      final parseData = await PdfStatementImportService.pickAndParse(
        onPromptPassword: () => _showPasswordDialog(context),
      );

      if (parseData == null) return;

      if (parseData.transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions found in this statement.'),
            ),
          );
        }
        return;
      }

      await context.read<NewNboxProvider>().importFromPdf(
        parseData.transactions,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) {
    String enteredPassword = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'PDF Password Required',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            obscureText: true,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter PDF password',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.cardElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
            ),
            onChanged: (val) => enteredPassword = val,
            onSubmitted: (val) => Navigator.pop(dialogContext, val),
          ),
          actions: [
            NexusButton(
              variant: NexusButtonVariant.secondary,
              width: double.infinity,
              onPressed: () => Navigator.pop(dialogContext, null),
              label: 'Cancel',
            ),
            NexusButton(
              width: double.infinity,
              onPressed: () => Navigator.pop(dialogContext, enteredPassword),
              label: 'Submit',
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _nboxProvider = context.read<NewNboxProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _nboxProvider.addListener(_onNboxChanged);
    });
  }

  @override
  void dispose() {
    _nboxProvider.removeListener(_onNboxChanged);
    super.dispose();
  }

  void _onNboxChanged() {
    if (!mounted) return;
    final nbox = context.read<NewNboxProvider>();
    if (nbox.hasPendingApprovalRequest) {
      _attemptQueuedApproval(nbox);
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isSmsLoading = false;
      _isGmailLoading = false;
    });
  }

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

  void _enterSelectionModeEmpty() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
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
          final allPending = [
            ...nbox.pendingSms,
            ...nbox.pendingEmails,
            ...nbox.pendingPdf,
          ]..sort((a, b) => b.date.compareTo(a.date));

          List<DetectedTransaction> displayList;
          switch (_currentFilter) {
            case NBoxFilter.sms:
              displayList = nbox.pendingSms;
              break;
            case NBoxFilter.email:
              displayList = nbox.pendingEmails;
              break;
            case NBoxFilter.pdf:
              displayList = nbox.pendingPdf;
              break;
            case NBoxFilter.trash:
              displayList = nbox.rejected;
              break;
            case NBoxFilter.all:
              displayList = allPending;
              break;
          }

          final totalPendingValue = allPending.fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

          final bool inFocusMode =
              _viewMode == NBoxViewMode.focus &&
              _currentFilter != NBoxFilter.trash &&
              !_isSelectionMode &&
              displayList.isNotEmpty;

          final focusList = _focusQueueIds == null
              ? displayList
              : displayList
                    .where(
                      (t) => _focusQueueIds!.contains('${t.source}:${t.id}'),
                    )
                    .toList();

          if (inFocusMode) {
            if (focusList.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _viewMode = NBoxViewMode.list;
                    _focusQueueIds = null;
                  });
                }
              });
            }
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildStandardHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildInboxSummaryCard(
                      allPending.length,
                      totalPendingValue,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildFilterPills(
                      nbox.pendingSms.length,
                      nbox.pendingEmails.length,
                      nbox.pendingPdf.length,
                    ),
                  ),
                  Expanded(
                    child: focusList.isEmpty
                        ? _buildEmptyState()
                        : _buildFocusView(focusList, nbox),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              if (context.watch<NewNboxProvider>().autoRecorded.isNotEmpty)
                SliverToBoxAdapter(child: _buildAutoRecordedSection()),
              _isSelectionMode
                  ? _buildSelectionHeader(displayList)
                  : _buildMainHeader(),

              if (_currentFilter != NBoxFilter.trash)
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildFilterPills(
                    nbox.pendingSms.length,
                    nbox.pendingEmails.length,
                    nbox.pendingPdf.length,
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

  Widget _buildViewModeToggle() {
    return IconButton(
      tooltip: _viewMode == NBoxViewMode.list ? 'Focus review' : 'List view',
      onPressed: () {
        setState(() {
          _viewMode = _viewMode == NBoxViewMode.list
              ? NBoxViewMode.focus
              : NBoxViewMode.list;
          _focusQueueIds = null;
        });
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _viewMode == NBoxViewMode.focus
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : AppColors.cardSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _viewMode == NBoxViewMode.list
              ? Icons.view_agenda_outlined
              : Icons.view_list_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSelectEntryButton() {
    return IconButton(
      tooltip: 'Select multiple',
      onPressed: _enterSelectionModeEmpty,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.checklist_rounded,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStandardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NBox',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              _buildSelectEntryButton(),
              _buildViewModeToggle(),
              _isSmsLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: NexusInlineLoading(),
                    )
                  : IconButton(
                      tooltip: 'Refresh SMS',
                      onPressed: _refreshSms,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sms,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
              _isGmailLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: NexusInlineLoading(),
                    )
                  : IconButton(
                      tooltip: 'Refresh Gmail',
                      onPressed: _refreshGmail,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.email,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
              _isPdfLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: NexusInlineLoading(),
                    )
                  : IconButton(
                      tooltip: 'Import PDF Statement',
                      onPressed: _importPdf,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

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
          'NBox',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        _buildSelectEntryButton(),
        _buildViewModeToggle(),
        _isSmsLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Refresh SMS',
                onPressed: _refreshSms,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.cardSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
        _isGmailLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Refresh Gmail',
                onPressed: _refreshGmail,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.cardSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
        _isPdfLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: NexusInlineLoading(),
                ),
              )
            : IconButton(
                tooltip: 'Import PDF Statement',
                onPressed: _importPdf,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.cardSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
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
        if (_isBulkApproving)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2.5,
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Approve selected',
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primaryBlue,
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _approveSelected(list),
          ),
        IconButton(
          tooltip: 'Reject selected',
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: _selectedIds.isEmpty ? null : _rejectSelected,
        ),
      ],
    );
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'sms':
        return const Color(0xFFF59E0B);
      case 'pdf':
        return const Color(0xFF10B981);
      case 'email':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'sms':
        return 'SMS';
      case 'pdf':
        return 'PDF';
      case 'email':
      default:
        return 'EMAIL';
    }
  }

  Widget _buildStreamItem(DetectedTransaction t, bool isLast, bool isTrashTab) {
    final uniqueId = '${t.source}:${t.id}';
    final isExpanded = _expandedIds.contains(uniqueId);
    final isSelected = _selectedIds.contains(uniqueId);
    final isIncome = t.type.toLowerCase() == 'income';

    final highlightColor = _sourceColor(t.source);

    return Stack(
      children: [
        Positioned(
          left: 30,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : highlightColor.withValues(alpha: 0.15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleSelection(uniqueId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 60,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 18),
                  child: AnimatedContainer(
                    duration: AppAnimations.standard,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.backgroundBlack,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : highlightColor,
                        width: 2.0,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => _toggleExpand(uniqueId),
                    onLongPress: () => _enterSelectionMode(uniqueId),
                    child: AnimatedContainer(
                      duration: AppAnimations.standard,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppColors.cardElevated
                            : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isExpanded
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  t.merchant,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (t.source == 'email') ...[
                                                const SizedBox(width: 8),
                                                _buildConfidenceBadge(t),
                                              ],
                                            ],
                                          ),
                                          if (t.detectedCategory != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Category: ${t.detectedCategory}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.accentTeal,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${isIncome ? '+' : ''}₹${AppCurrency.format(t.amount)}',
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
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildTag(
                                          _sourceLabel(t.source),
                                          highlightColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('hh:mm a').format(t.date),
                                          style: const TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (t.warnings.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: AppColors.pastelOrange,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (!isTrashTab &&
                                        !isExpanded &&
                                        !_isSelectionMode)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildQuickActionIcon(
                                            icon: Icons.close_rounded,
                                            color: AppColors.error,
                                            onTap: () => _rejectTransaction(t),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildQuickActionIcon(
                                            icon: Icons.check_rounded,
                                            color: AppColors.pastelGreen,
                                            onTap: () =>
                                                _navigateToApproveScreen(t),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AnimatedSize(
                            duration: AppAnimations.slow,
                            curve: AppAnimations.smoothCurve,
                            alignment: Alignment.topCenter,
                            child: isExpanded && !_isSelectionMode
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                        height: 1,
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          18,
                                          14,
                                          18,
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
                                          horizontal: 18,
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
                                      _buildUnderstandingSection(t),
                                      const SizedBox(height: 16),
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          18,
                                          0,
                                          18,
                                          8,
                                        ),
                                        child: Text(
                                          "SOURCE SUMMARY",
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
                                          horizontal: 18,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _sourceSummary(t),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                            if ((t.body ?? '')
                                                .trim()
                                                .isNotEmpty)
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      _showFullSource(t),
                                                  child: const Text(
                                                    'View full message',
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.05,
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
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
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

  Widget _buildUnderstandingSection(DetectedTransaction t) {
    final understanding = context.read<NewNboxProvider>().understandingFor(
      t.source,
      t.fingerprint,
    );
    if (understanding == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          'Nexus is still working this out.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      );
    }

    final chips = <Widget>[];
    if (understanding.entity?.isNotEmpty == true) {
      chips.add(
        _buildAnalysisChip(
          Icons.person_search_rounded,
          'Entity: ${understanding.entity}',
        ),
      );
    }
    if (understanding.counterpartyRole != 'unknown') {
      chips.add(
        _buildAnalysisChip(
          Icons.swap_horiz_rounded,
          'Role: ${understanding.counterpartyRole}',
        ),
      );
    }
    if (understanding.purpose != 'unknown') {
      final purpose = understanding.purpose == 'category'
          ? (t.detectedCategory ?? 'Category')
          : understanding.purpose;
      chips.add(
        _buildAnalysisChip(
          Icons.label_outline_rounded,
          'Purpose: ${_titleCase(purpose)}',
        ),
      );
    }
    if (understanding.accountId != null) {
      chips.add(
        _buildAnalysisChip(Icons.account_balance_rounded, 'Account identified'),
      );
    }
    if (understanding.destinationAccountId != null) {
      chips.add(
        _buildAnalysisChip(Icons.call_made_rounded, 'Destination identified'),
      );
    }
    if (understanding.isRecurring) {
      chips.add(_buildAnalysisChip(Icons.repeat_rounded, 'Recurring'));
    }
    if (understanding.isRefund) {
      chips.add(_buildAnalysisChip(Icons.undo_rounded, 'Refund'));
    }
    if (understanding.usualAmount != null && understanding.usualAmount! > 0) {
      chips.add(
        _buildAnalysisChip(
          Icons.insights_rounded,
          'Usual: ₹${understanding.usualAmount!.round()}',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXUS UNDERSTANDING',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          if (chips.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (understanding.observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...understanding.observations
                .take(2)
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• $text',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
          if (understanding.reasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                understanding.reasons.first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoRecordedSection() {
    final nbox = context.watch<NewNboxProvider>();
    final transactions = context.watch<TransactionProvider>().transactions;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENTLY AUTO-RECORDED',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...nbox.autoRecorded.map((entry) {
            final t = entry.detected;
            final tx = transactions
                .where(
                  (item) =>
                      item.metadata?['sourceFingerprint'] == t.fingerprint,
                )
                .firstOrNull;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${t.merchant} · ₹${AppCurrency.format(t.amount)}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '${t.source} · ${(t.confidence.overall * 100).round()}% confidence\n${entry.understanding.reasons.take(2).join(' ')}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: tx == null
                    ? null
                    : () => ModernAddTransactionScreen.show(
                        context,
                        transaction: tx,
                      ),
                child: const Text('Fix'),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _sourceSummary(DetectedTransaction t) {
    final body = (t.body ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (body.isEmpty) return 'No source message available.';

    final sentences = body
        .split(RegExp(r'[.!?]+\s+'))
        .where(
          (s) => RegExp(
            r'\b(debited|credited|received|sent|paid|spent|transaction|purchase|upi|ref)\b',
            caseSensitive: false,
          ).hasMatch(s),
        )
        .take(3)
        .toList();
    final summary = sentences.isEmpty ? body : sentences.join(' ');
    return summary.length > 360 ? '${summary.substring(0, 357)}...' : summary;
  }

  Future<void> _showFullSource(DetectedTransaction t) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Source message'),
        content: SingleChildScrollView(
          child: SelectableText(
            t.body ?? 'No content',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
    final isPrimary = bg == AppColors.primaryBlue;
    return NexusButton(
      onPressed: onTap,
      icon: Icon(icon, size: AppSpacing.iconSm),
      label: label,
      variant: isPrimary
          ? NexusButtonVariant.primary
          : NexusButtonVariant.secondary,
      emphasizedPrimary: isPrimary,
    );
  }

  // --- SOLID LUXURY SUMMARY CARD (NO GRADIENT) ---

  Widget _buildInboxSummaryCard(int count, double totalValue) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "PENDING REVIEW",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_rounded,
                      color: AppColors.textSecondary,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$count items',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${NumberFormat('#,##,###').format(totalValue)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.currencyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Detected from SMS, Email & Statements',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SEAMLESS PILLS (NO WHITE MATERIAL 3 BORDER) ---

  Widget _buildFilterPills(int smsCount, int emailCount, int pdfCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildPill("All", NBoxFilter.all),
          _buildPill("SMS ($smsCount)", NBoxFilter.sms),
          _buildPill("Email ($emailCount)", NBoxFilter.email),
          _buildPill("PDF ($pdfCount)", NBoxFilter.pdf),
          _buildPill("Trash", NBoxFilter.trash),
        ],
      ),
    );
  }

  Widget _buildPill(String label, NBoxFilter value) {
    final isSelected = _currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOCUS VIEW
  // ---------------------------------------------------------------------------

  Widget _buildFocusView(List<DetectedTransaction> list, NewNboxProvider nbox) {
    final current = list[0];
    final next = list.length > 1 ? list[1] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 10.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.center_focus_strong_outlined,
                  color: AppColors.textTertiary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'FOCUS REVIEW · ${list.length} LEFT',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 36.0,
                vertical: 18.0,
              ),
              child: _SwipeCardStack(
                key: ValueKey('${current.source}:${current.id}'),
                current: current,
                next: next,
                cardBuilder: _buildSwipeCard,
                labelBuilder: _buildSwipeLabel,
                actionButtonBuilder: _buildActionButton,
                onCommitted: (t, approved) {
                  if (approved) {
                    _navigateToApproveScreen(t);
                  } else {
                    nbox.rejectTransaction(t.id, t.source, silent: true);
                    showTopNotification(
                      context,
                      'Moved to Trash',
                      isError: true,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCard(DetectedTransaction t, {required bool isBack}) {
    final isIncome = t.type.toLowerCase() == 'income';
    final highlightColor = _sourceColor(t.source);

    return Container(
      decoration: BoxDecoration(
        color: isBack
            ? AppColors.cardSurface.withValues(alpha: 0.5)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isBack
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      padding: const EdgeInsets.all(24),
      child: isBack
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTag(_sourceLabel(t.source), highlightColor),
                    const SizedBox(width: 8),
                    if (t.source == 'email') _buildConfidenceBadge(t),
                    const Spacer(),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          DateFormat('dd MMM, hh:mm a').format(t.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${isIncome ? '+' : '−'}₹${NumberFormat('#,##,###').format(t.amount)}',
                        style: TextStyle(
                          fontFamily: AppTypography.headerFont,
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: isIncome
                              ? AppColors.pastelGreen
                              : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.merchant,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (t.detectedCategory != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.detectedCategory!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.accentTeal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (t.balanceAfter != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${t.bankName ?? 'Bank'} bal. ₹${NumberFormat('#,##,###.##').format(t.balanceAfter)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (t.body != null) ...[
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SOURCE SUMMARY',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sourceSummary(t),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showFullSource(t),
                              child: const Text('View full message'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (t.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.pastelOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.warnings.first,
                          style: const TextStyle(
                            color: AppColors.pastelOrange,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSwipeLabel(String text, Color color) {
    return Transform.rotate(
      angle: text == 'APPROVE' ? -0.2 : 0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(DetectedTransaction t) {
    Color bgColor;
    Color textColor;
    String label;

    if (t.isHighConfidence) {
      bgColor = AppColors.accentTeal.withValues(alpha: 0.15);
      textColor = AppColors.accentTeal;
      label = '✓ High';
    } else if (t.isLowConfidence) {
      bgColor = AppColors.pastelOrange.withValues(alpha: 0.15);
      textColor = AppColors.pastelOrange;
      label = '⚠ Low';
    } else {
      bgColor = Colors.white.withValues(alpha: 0.1);
      textColor = AppColors.textSecondary;
      label = 'Medium';
    }

    return Tooltip(
      message:
          'Confidence: ${(t.confidence.overall * 100).toStringAsFixed(0)}%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String label = DateFormat('MMM dd').format(date);
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      label = "Today";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const NexusEmptyState(
    icon: Icons.inbox_rounded,
    title: 'All Caught Up',
    message: 'No pending transactions to review',
  );

  void _rejectTransaction(DetectedTransaction t) {
    context.read<NewNboxProvider>().rejectTransaction(t.id, t.source);
    showTopNotification(context, "Moved to Trash", isError: true);
  }

  void _attemptQueuedApproval(NewNboxProvider nbox) {
    if (!nbox.hasPendingApprovalRequest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pending = nbox.takePendingApprovalRequest();
      if (pending == null) return;
      await _navigateToApproveScreen(pending);
    });
  }

  Future<void> _navigateToApproveScreen(DetectedTransaction t) async {
    if (_isApprovalScreenOpen) return;
    _isApprovalScreenOpen = true;

    try {
      final nbox = context.read<NewNboxProvider>();

      final understanding = TransactionAutomationService().analyze(
        detected: t,
        history: context.read<TransactionProvider>().transactions,
        knowledge: context.read<KnowledgeProvider>().entries,
        accounts: context.read<AccountProvider>(),
      );

      bool success = false;
      if (understanding.intent == TransactionIntent.salary) {
        success =
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaydayScreen(
                  incomeAmount: t.amount,
                  incomeSource: t.merchant,
                  incomeDate: t.date,
                  detectedTransaction: t,
                ),
              ),
            ) ==
            true;
      } else if (understanding.intent.hasSideEffects) {
        success = await showSmartApprovalSheet(context, t);
      } else {
        success =
            await ModernAddTransactionScreen.show<bool>(
              context,
              detectedTransaction: t,
              accountId: understanding.accountId,
              categoryId: understanding.categoryId,
              initialType: understanding.isTransfer
                  ? TransactionType.transfer
                  : t.type.toLowerCase() == 'income'
                  ? TransactionType.income
                  : TransactionType.expense,
            ) ??
            false;
      }

      if (success == true) {
        nbox.markAsApproved(t.id, t.source);
        if (mounted) showTopNotification(context, "Verified & Added");
      }
    } finally {
      _isApprovalScreenOpen = false;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _approveSelected(List<DetectedTransaction> currentList) async {
    if (_isBulkApproving) return;

    final nbox = context.read<NewNboxProvider>();

    final selected = currentList
        .where((t) => _selectedIds.contains('${t.source}:${t.id}'))
        .toList();

    if (selected.isEmpty) return;

    setState(() => _isBulkApproving = true);

    final needsReview = <DetectedTransaction>[];
    var quickApproved = 0;
    var failed = 0;

    for (final t in selected) {
      final understanding = TransactionAutomationService().analyze(
        detected: t,
        history: context.read<TransactionProvider>().transactions,
        knowledge: context.read<KnowledgeProvider>().entries,
        accounts: context.read<AccountProvider>(),
      );

      final needsForm =
          understanding.intent.hasSideEffects ||
          understanding.intent == TransactionIntent.salary;

      if (needsForm) {
        needsReview.add(t);
        continue;
      }

      final ok = await _quickApprove(t);
      if (ok) {
        quickApproved++;
        nbox.markAsApproved(t.id, t.source);
      } else {
        needsReview.add(t);
        failed++;
      }
    }

    if (!mounted) return;

    setState(() => _isBulkApproving = false);
    _exitSelectionMode();

    final parts = <String>[];
    if (quickApproved > 0) parts.add('Approved $quickApproved');
    if (needsReview.length - failed > 0) {
      parts.add('${needsReview.length - failed} need review');
    }
    if (failed > 0) parts.add('$failed failed');
    showTopNotification(
      context,
      parts.isEmpty ? 'Nothing to approve' : parts.join(' · '),
      isError: quickApproved == 0,
    );

    if (needsReview.isNotEmpty) {
      setState(() {
        _focusQueueIds = needsReview.map((t) => '${t.source}:${t.id}').toSet();
        _viewMode = NBoxViewMode.focus;
      });
    }
  }

  Future<bool> _quickApprove(DetectedTransaction t) async {
    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isEmpty) return false;
    final accountId = accounts.first.id;

    final categories = context.read<CategoryProvider>().categories;
    var resolvedCategoryId = t.detectedCategory ?? 'other';
    final hasId = categories.any((c) => c.id == resolvedCategoryId);
    if (!hasId) {
      final byName = categories
          .where((c) => c.name == resolvedCategoryId)
          .toList();
      if (byName.isNotEmpty) resolvedCategoryId = byName.first.id;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final result = await TransactionRouter().execute(
        plan: TransactionRouter.buildSimplePlan(
          detected: t,
          accountId: accountId,
          categoryId: resolvedCategoryId,
        ),
        userId: userId,
        transactionProvider: context.read<TransactionProvider>(),
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class _SwipeCardStack extends StatefulWidget {
  final DetectedTransaction current;
  final DetectedTransaction? next;
  final Widget Function(DetectedTransaction t, {required bool isBack})
  cardBuilder;
  final Widget Function(String label, Color color) labelBuilder;
  final Widget Function(
    String label,
    IconData icon,
    Color fg,
    Color bg,
    VoidCallback onTap,
  )
  actionButtonBuilder;
  final void Function(DetectedTransaction t, bool approved) onCommitted;

  const _SwipeCardStack({
    super.key,
    required this.current,
    required this.next,
    required this.cardBuilder,
    required this.labelBuilder,
    required this.actionButtonBuilder,
    required this.onCommitted,
  });

  @override
  State<_SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<_SwipeCardStack> {
  double _dx = 0;
  double _rotation = 0;
  bool _animating = false;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dx += d.delta.dx;
      _rotation = (_dx / 300).clamp(-0.15, 0.15);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    const threshold = 120.0;
    if (_dx > threshold) {
      _commit(true);
    } else if (_dx < -threshold) {
      _commit(false);
    } else {
      setState(() {
        _dx = 0;
        _rotation = 0;
      });
    }
  }

  void _commit(bool approved) {
    if (_animating) return;
    setState(() {
      _animating = true;
      _dx = approved ? 500.0 : -500.0;
      _rotation = approved ? 0.3 : -0.3;
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      widget.onCommitted(widget.current, approved);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.next != null)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Transform.translate(
                      offset: const Offset(0, 16),
                      child: Transform.scale(
                        scale: 0.94,
                        child: widget.cardBuilder(widget.next!, isBack: true),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: GestureDetector(
                    onHorizontalDragUpdate: _animating ? null : _onDragUpdate,
                    onHorizontalDragEnd: _animating ? null : _onDragEnd,
                    child: Transform.translate(
                      offset: Offset(_dx, 0),
                      child: Transform.rotate(
                        angle: _rotation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            widget.cardBuilder(widget.current, isBack: false),
                            if (_dx > 30)
                              Positioned(
                                top: 24,
                                left: 24,
                                child: widget.labelBuilder(
                                  'APPROVE',
                                  Colors.green,
                                ),
                              ),
                            if (_dx < -30)
                              Positioned(
                                top: 24,
                                right: 24,
                                child: widget.labelBuilder(
                                  'REJECT',
                                  AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: widget.actionButtonBuilder(
                "Reject",
                Icons.close,
                AppColors.error,
                AppColors.error.withValues(alpha: 0.1),
                _animating ? () {} : () => _commit(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: widget.actionButtonBuilder(
                "Approve",
                Icons.check,
                Colors.white,
                AppColors.primaryBlue,
                _animating ? () {} : () => _commit(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
