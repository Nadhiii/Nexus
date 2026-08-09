import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/models/payday_checklist.dart';
import '../../core/models/detected_transaction.dart';
import '../../core/models/transaction.dart';
import '../../core/services/payday_checklist_service.dart';
import '../../core/services/smart_category_resolver.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/goal_provider.dart';
import '../../core/providers/budget_provider.dart';
import '../../core/providers/family_debt_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/widgets/top_snackbar.dart';

/// Full-screen payday checklist shown when salary income is detected
/// or opened manually from Settings/Finance.
///
/// Usage (from NBox after salary detection):
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => PaydayScreen(
///     incomeAmount: detected.amount,
///     incomeSource: detected.merchant,
///     incomeDate: detected.date,
///   ),
/// ));
/// ```
class PaydayScreen extends StatefulWidget {
  final double incomeAmount;
  final String? incomeSource;
  final DateTime? incomeDate;

  /// Pass the still-unsaved DetectedTransaction when opening this screen
  /// from NBox approval (salary intent). PaydayScreen will save it via
  /// TransactionProvider.addTransaction when the user taps Done.
  ///
  /// Leave null when the income transaction has ALREADY been saved
  /// elsewhere (e.g. manual entry via AddTransactionScreen that then shows
  /// this checklist as a follow-up) -- in that case Done just dismisses.
  final DetectedTransaction? detectedTransaction;

  const PaydayScreen({
    super.key,
    required this.incomeAmount,
    this.incomeSource,
    this.incomeDate,
    this.detectedTransaction,
  });

  @override
  State<PaydayScreen> createState() => _PaydayScreenState();
}

class _PaydayScreenState extends State<PaydayScreen>
    with SingleTickerProviderStateMixin {
  PaydayChecklist? _checklist;
  final Set<String> _checked = {};
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: AppAnimations.slow);
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: AppAnimations.smoothCurve);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _buildChecklist());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _buildChecklist() {
    final service = PaydayChecklistService(
      debtProvider: context.read<DebtProvider>(),
      subscriptionProvider: context.read<SubscriptionProvider>(),
      goalProvider: context.read<GoalProvider>(),
      budgetProvider: context.read<BudgetProvider>(),
      familyDebtProvider: context.read<FamilyDebtProvider>(),
    );

    final checklist = service.generateChecklist(
      incomeAmount: widget.incomeAmount,
      incomeSource: widget.incomeSource,
      incomeDate: widget.incomeDate,
    );

    setState(() => _checklist = checklist);
  }

  double get _checkedAmount => _checklist == null
      ? 0
      : _checklist!.items
          .where((i) => _checked.contains(i.id))
          .fold(0.0, (sum, i) => sum + i.amount);

  double get _remainingBalance =>
      widget.incomeAmount - _checkedAmount;

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _buildIncomeHero(),
              ),
            ),
            if (_checklist == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildAllocationBar(),
                ),
              ),
              _buildItemList(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildSavingsSuggestion(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: _buildDoneButton(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.backgroundBlack,
      surfaceTintColor: AppColors.backgroundBlack,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context, false),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 16),
        ),
      ),
      title: Column(
        children: [
          Text(
            '💰 Payday!',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            widget.incomeSource ?? 'Income received',
            style: TextStyle(
                color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildIncomeHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A1A), Color(0xFF0F1F0F)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: AppColors.pastelGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.pastelGreen.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INCOME RECEIVED',
            style: TextStyle(
              color: AppColors.pastelGreen.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+₹${NumberFormat('#,##,###').format(widget.incomeAmount)}',
            style: TextStyle(
              color: AppColors.pastelGreen,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (widget.incomeDate != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(widget.incomeDate!),
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  'Allocated',
                  _checkedAmount,
                  AppColors.pastelOrange,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _buildHeroStat(
                  'Remaining',
                  _remainingBalance,
                  _remainingBalance >= 0
                      ? AppColors.pastelGreen
                      : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppColors.textTertiary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            '₹${NumberFormat.compact().format(value.abs())}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationBar() {
    if (_checklist == null || widget.incomeAmount <= 0) {
      return const SizedBox.shrink();
    }

    final allocatedRatio =
        (_checkedAmount / widget.incomeAmount).clamp(0.0, 1.0);
    final obligationsRatio =
        (_checklist!.totalObligations / widget.incomeAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Income Allocation',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(
                '${(allocatedRatio * 100).toStringAsFixed(0)}% allocated',
                style: TextStyle(
                    color: AppColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked bar: allocated vs obligations vs free
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Background
                Container(
                  height: 10,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                // Obligations (full width marker)
                FractionallySizedBox(
                  widthFactor: obligationsRatio,
                  child: Container(
                    height: 10,
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                // Checked/allocated
                FractionallySizedBox(
                  widthFactor: allocatedRatio,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: allocatedRatio > obligationsRatio
                            ? [AppColors.pastelOrange, AppColors.error]
                            : [
                                AppColors.pastelGreen,
                                AppColors.pastelOrange
                              ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildLegendDot(AppColors.pastelGreen, 'Checked off'),
              const SizedBox(width: 12),
              _buildLegendDot(
                  AppColors.error.withValues(alpha: 0.5), 'Total obligations'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }

  Widget _buildItemList() {
    if (_checklist == null) return const SliverPadding(padding: EdgeInsets.zero);

    // Group by type
    final grouped = <ChecklistItemType, List<PaydayChecklistItem>>{};
    for (final item in _checklist!.items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    final typeOrder = [
      ChecklistItemType.debtEMI,
      ChecklistItemType.familyDebt,
      ChecklistItemType.subscription,
      ChecklistItemType.goalContribution,
      ChecklistItemType.budgetAllocation,
      ChecklistItemType.savingsTransfer,
    ];

    final sections = <Widget>[];
    for (final type in typeOrder) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;

      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(type, items),
              const SizedBox(height: 10),
              ...items.map((item) => _buildItemCard(item)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => sections[i],
        childCount: sections.length,
      ),
    );
  }

  Widget _buildSectionHeader(
      ChecklistItemType type, List<PaydayChecklistItem> items) {
    final total = items.fold(0.0, (sum, i) => sum + i.amount);
    return Row(
      children: [
        Text(
          _typeLabel(type).toUpperCase(),
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          '₹${NumberFormat.compact().format(total)}',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(PaydayChecklistItem item) {
    final isChecked = _checked.contains(item.id);
    final priorityColor = _priorityColor(item.priority);

    return AnimatedContainer(
      duration: AppAnimations.standard,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.pastelGreen.withValues(alpha: 0.06)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? AppColors.pastelGreen.withValues(alpha: 0.2)
              : (item.priority == ChecklistItemPriority.urgent
                  ? AppColors.error.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05)),
          width: item.priority == ChecklistItemPriority.urgent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          if (isChecked) {
            _checked.remove(item.id);
          } else {
            _checked.add(item.id);
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: AppAnimations.standard,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.pastelGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.pastelGreen
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: isChecked
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.priority == ChecklistItemPriority.urgent)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          item.subtitle,
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11),
                        ),
                        if (item.dueDate != null) ...[
                          Text(
                            ' · ',
                            style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11),
                          ),
                          Text(
                            _dueDateLabel(item.dueDate!),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${NumberFormat('#,##,###').format(item.amount)}',
                    style: TextStyle(
                      color:
                          isChecked ? AppColors.textTertiary : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(item.type),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsSuggestion() {
    if (_checklist == null || _checklist!.suggestedSavings <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.12),
            AppColors.cardSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings_rounded,
                color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Savings',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aim to park at least this much away',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '₹${NumberFormat.compact().format(_checklist!.suggestedSavings)}',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Actually persists the salary income as a real Transaction, the same
  /// way the "simple" quick-approve path in NBox does. Returns false (and
  /// shows an error) if there's no account to save against, so we never
  /// silently drop the transaction.
  Future<bool> _saveIncomeTransaction() async {
    final t = widget.detectedTransaction;
    if (t == null) {
      // Already saved elsewhere (e.g. manual entry flow) -- nothing to do.
      return true;
    }

    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isEmpty) {
      if (mounted) {
        showTopSnackBar(
          context,
          'No account to save into — add an account first',
        );
      }
      return false;
    }
    final accountId = accounts.first.id;

    final categories = context.read<CategoryProvider>().categories;
    String? resolvedCategoryId = t.detectedCategory ??
        SmartCategoryResolver.resolve(
          merchant: t.merchant,
          body: t.body,
          amount: t.amount,
          transactionType: t.type,
        );
    final hasId = categories.any((c) => c.id == resolvedCategoryId);
    if (!hasId) {
      final byName =
          categories.where((c) => c.name == resolvedCategoryId).toList();
      if (byName.isNotEmpty) resolvedCategoryId = byName.first.id;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    final transaction = Transaction(
      id: '',
      userId: userId,
      type: TransactionType.income,
      amount: t.amount,
      description: t.merchant,
      categoryId: resolvedCategoryId,
      accountId: accountId,
      toAccountId: null,
      date: t.date,
      createdAt: now,
      updatedAt: now,
    );

    final ok = await context.read<TransactionProvider>().addTransaction(transaction);
    if (!ok && mounted) {
      showTopSnackBar(context, 'Could not save — try again');
    }
    return ok;
  }

  Widget _buildDoneButton() {
    final totalChecked = _checked.length;
    final totalItems = _checklist?.items.length ?? 0;
    final allDone = totalChecked == totalItems && totalItems > 0;

    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
              setState(() => _isSaving = true);
              final saved = await _saveIncomeTransaction();
              if (!mounted) return;
              setState(() => _isSaving = false);

              if (!saved) {
                // Error already shown inside _saveIncomeTransaction. Stay
                // on screen so nothing gets silently lost.
                return;
              }

              showTopSnackBar(
                context,
                allDone
                    ? 'All done! Payday sorted 🎉'
                    : 'Saved — $totalChecked/$totalItems items checked',
              );
              Navigator.pop(context, true);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allDone
                ? [AppColors.pastelGreen, const Color(0xFF2ECC71)]
                : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (allDone ? AppColors.pastelGreen : AppColors.primaryBlue)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(
                allDone ? Icons.celebration_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              _isSaving
                  ? 'Saving...'
                  : allDone
                      ? 'All Done — Payday Sorted!'
                      : 'Done ($totalChecked/$totalItems checked)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _typeLabel(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.debtEMI:
        return 'EMI';
      case ChecklistItemType.familyDebt:
        return 'Personal';
      case ChecklistItemType.subscription:
        return 'Sub';
      case ChecklistItemType.goalContribution:
        return 'Goal';
      case ChecklistItemType.budgetAllocation:
        return 'Budget';
      case ChecklistItemType.savingsTransfer:
        return 'Savings';
    }
  }

  Color _priorityColor(ChecklistItemPriority priority) {
    switch (priority) {
      case ChecklistItemPriority.urgent:
        return AppColors.error;
      case ChecklistItemPriority.high:
        return AppColors.pastelOrange;
      case ChecklistItemPriority.medium:
        return AppColors.primaryBlue;
      case ChecklistItemPriority.low:
        return AppColors.textTertiary;
    }
  }

  String _dueDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) return '${diff.abs()}d overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${DateFormat('dd MMM').format(date)}';
  }
}