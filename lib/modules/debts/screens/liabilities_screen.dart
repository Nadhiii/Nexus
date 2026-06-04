import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/widgets/swipe_to_delete.dart';
import '../../../core/widgets/collapsible_fab.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../utils/debt_logo_utils.dart';
import '../widgets/add_loan_sheet.dart';
import '../widgets/add_credit_card_sheet.dart';
import '../widgets/quick_pay_emi_sheet.dart';
import '../widgets/emi_dot_calendar.dart';

/// Bento tile types for dynamic sizing
enum _BentoTileType { featured, large, wide, compact }

/// Filter types for liabilities
enum _LiabilityFilter { loans, creditCards, settled }

/// Redesigned Liabilities Screen
/// Clean, focused on Loans and Credit Cards (IOUs moved to Family)
class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  _LiabilityFilter _filter = _LiabilityFilter.loans;

  // Filter out legacy IOUs (they should use Family module)
  bool _isValidDebt(Debt debt) => !debt.type.isLegacyIOU;
  bool _isSettled(Debt debt) => debt.currentBalance < 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          try {
            // Filter and categorize debts
            final validDebts = provider.debts
                .where((d) => _isValidDebt(d))
                .toList();
            final activeDebts = validDebts
                .where((d) => !_isSettled(d))
                .toList();
            final loans = activeDebts.where((d) => d.type.isLoan).toList();
            final creditCards = activeDebts
                .where((d) => d.type.isCreditCard)
                .toList();
            final settled = validDebts.where((d) => _isSettled(d)).toList();

            // Sort by balance (highest first)
            loans.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
            creditCards.sort(
              (a, b) => b.currentBalance.compareTo(a.currentBalance),
            );
            settled.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            // Get current filtered list
            List<Debt> displayedDebts;
            switch (_filter) {
              case _LiabilityFilter.loans:
                displayedDebts = loans;
                break;
              case _LiabilityFilter.creditCards:
                displayedDebts = creditCards;
                break;
              case _LiabilityFilter.settled:
                displayedDebts = settled;
                break;
            }

            return CustomScrollView(
              slivers: [
                // 1. APP BAR with FlexibleSpaceBar animation
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
                      'Liabilities',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // 2. SUMMARY CARD
                if (activeDebts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: _buildSummaryCard(activeDebts),
                    ),
                  ),

                // 3. FILTER PILLS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildFilterPills(
                      loans.length,
                      creditCards.length,
                      settled.length,
                    ),
                  ),
                ),

                // 4. BENTO GRID OR EMPTY STATE
                if (displayedDebts.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(
                      _filter == _LiabilityFilter.loans
                          ? 'No active loans'
                          : _filter == _LiabilityFilter.creditCards
                          ? 'No credit card dues'
                          : 'No settled debts yet',
                      _filter == _LiabilityFilter.loans
                          ? Icons.account_balance_outlined
                          : _filter == _LiabilityFilter.creditCards
                          ? Icons.credit_card_outlined
                          : Icons.check_circle_outline,
                      _filter == _LiabilityFilter.settled
                          ? null
                          : () => _filter == _LiabilityFilter.loans
                                ? _showAddLoanSheet(context)
                                : _showAddCreditCardSheet(context),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: _filter == _LiabilityFilter.settled
                          ? _buildSettledBentoGridWidget(settled)
                          : _buildDynamicBentoGrid(
                              displayedDebts,
                              displayedDebts.fold(
                                0.0,
                                (sum, d) => sum + d.currentBalance,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          } catch (e, stackTrace) {
            debugPrint('Liabilities screen render failed: $e');
            debugPrint(stackTrace.toString());
            return _buildRenderErrorState();
          }
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildFAB(),
        ),
      ),
    );
  }

  Widget _buildFilterPills(int loansCount, int cardsCount, int settledCount) {
    return Row(
      children: [
        _buildPill('Loans', _LiabilityFilter.loans, loansCount),
        const SizedBox(width: 12),
        _buildPill('Cards', _LiabilityFilter.creditCards, cardsCount),
        const SizedBox(width: 12),
        _buildPill('Settled', _LiabilityFilter.settled, settledCount),
      ],
    );
  }

  Widget _buildPill(String label, _LiabilityFilter value, int count) {
    final isSelected = _filter == value;
    final color = isSelected ? AppColors.info : AppColors.cardSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.info
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettledBentoGridWidget(List<Debt> settled) {
    if (settled.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalPaid = settled.fold(0.0, (sum, d) => sum + d.originalAmount);

    return Column(
      children: [
        // Summary card for settled debts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.celebration_outlined,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cleared',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatAmount(totalPaid)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${settled.length} ${settled.length == 1 ? 'debt' : 'debts'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid of settled debts
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: settled.length,
          itemBuilder: (context, index) =>
              _buildSettledBentoTile(settled[index], totalPaid),
        ),
      ],
    );
  }

  Widget _buildSettledBentoTile(Debt debt, double totalPaid) {
    final Color typeColor = _getTypeColor(debt.type);
    final percentage = totalPaid > 0
        ? (debt.originalAmount / totalPaid * 100).toStringAsFixed(0)
        : '0';

    return GestureDetector(
      onTap: () => _showDebtDetails(debt),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row - Icon & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: _buildDebtAvatar(debt, typeColor, 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Cleared',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Name
            Text(
              debt.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Amount
            Text(
              '₹${_formatCompact(debt.originalAmount)}',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$percentage% of total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Debt> activeDebts) {
    final totalDebt = activeDebts.fold(0.0, (sum, d) => sum + d.currentBalance);
    final totalOriginal = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.originalAmount,
    );
    final totalEMI = activeDebts.fold(
      0.0,
      (sum, d) => sum + (d.monthlyEMI ?? 0),
    );
    final totalPaid = totalOriginal - totalDebt;
    final progress = totalOriginal > 0
        ? ((totalOriginal - totalDebt) / totalOriginal).clamp(0.0, 1.0)
        : 0.0;

    // Count total EMIs
    int totalEmiCount = 0;
    int paidEmiCount = 0;
    for (final debt in activeDebts) {
      if (debt.totalMonths != null) {
        totalEmiCount += debt.totalMonths!;
        paidEmiCount += debt.paidMonths ?? 0;
      }
    }

    // Find next due date
    DateTime? nextDue;
    for (final debt in activeDebts) {
      final paymentDate = debt.nextPaymentDate;
      if (paymentDate != null) {
        if (nextDue == null || paymentDate.isBefore(nextDue)) {
          nextDue = paymentDate;
        }
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          // Horizontal progress fill from left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * progress * 0.85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.success.withValues(alpha: 0.12),
                    AppColors.success.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
          // Subtle percentage watermark
          Positioned(
            right: 16,
            bottom: 8,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.success.withValues(alpha: 0.08),
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUTSTANDING',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_formatAmount(totalDebt)}',
                            style: AppTypography.currencyMedium,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹${_formatCompact(totalPaid)} paid',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // EMI Counter Badge
                    if (totalEmiCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$paidEmiCount/$totalEmiCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'EMIs',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Monthly EMI',
                      value: '₹${_formatCompact(totalEMI)}',
                    ),
                    const SizedBox(width: 12),
                    if (nextDue != null)
                      _buildStatChip(
                        icon: Icons.schedule,
                        label: 'Next Due',
                        value: DateFormat('d MMM').format(nextDue),
                        isWarning:
                            nextDue.difference(DateTime.now()).inDays <= 5,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.warning.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppColors.warning.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isWarning ? AppColors.warning : Colors.white60,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isWarning ? AppColors.warning : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BENTO GRID VIEW =================

  Widget _buildDynamicBentoGrid(List<Debt> debts, double totalDebt) {
    if (debts.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> rows = [];
    int index = 0;

    while (index < debts.length) {
      final remaining = debts.length - index;

      if (remaining == 1) {
        // Single item - full width featured
        rows.add(
          _buildBentoTile(
            debts[index],
            totalDebt,
            tileType: _BentoTileType.featured,
          ),
        );
        index++;
      } else if (remaining == 2) {
        // Two items - side by side large
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  debts[index],
                  totalDebt,
                  tileType: _BentoTileType.large,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTile(
                  debts[index + 1],
                  totalDebt,
                  tileType: _BentoTileType.large,
                ),
              ),
            ],
          ),
        );
        index += 2;
      } else if (remaining == 3) {
        // Three items - one wide + two stacked
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBentoTile(
                    debts[index],
                    totalDebt,
                    tileType: _BentoTileType.wide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          debts[index + 1],
                          totalDebt,
                          tileType: _BentoTileType.compact,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          debts[index + 2],
                          totalDebt,
                          tileType: _BentoTileType.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        index += 3;
      } else {
        // 4+ items - two large + wide with stacked
        // First: 2 large tiles
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  debts[index],
                  totalDebt,
                  tileType: _BentoTileType.large,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTile(
                  debts[index + 1],
                  totalDebt,
                  tileType: _BentoTileType.large,
                ),
              ),
            ],
          ),
        );
        index += 2;

        // Then: wide + 2 stacked (if we have at least 3 more)
        if (debts.length - index >= 3) {
          rows.add(const SizedBox(height: 12));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildBentoTile(
                      debts[index],
                      totalDebt,
                      tileType: _BentoTileType.wide,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildBentoTile(
                            debts[index + 1],
                            totalDebt,
                            tileType: _BentoTileType.compact,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildBentoTile(
                            debts[index + 2],
                            totalDebt,
                            tileType: _BentoTileType.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          index += 3;
        }
      }

      if (index < debts.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }

  Widget _buildBentoTile(
    Debt debt,
    double totalDebt, {
    required _BentoTileType tileType,
  }) {
    final Color typeColor = _getTypeColor(debt.type);
    final progress = debt.originalAmount > 0
        ? ((debt.originalAmount - debt.currentBalance) / debt.originalAmount)
              .clamp(0.0, 1.0)
        : 0.0;
    final percentage = totalDebt > 0
        ? (debt.currentBalance / totalDebt * 100).toStringAsFixed(0)
        : '0';

    final isDueSoon = debt.isPaymentDueSoon;
    final isOverdue = debt.isPaymentOverdue;

    final isCompact = tileType == _BentoTileType.compact;
    final isLarge = tileType == _BentoTileType.large;
    final isFeatured = tileType == _BentoTileType.featured;
    final isWide = tileType == _BentoTileType.wide;

    return GestureDetector(
      onTap: () => _showDebtDetails(debt),
      child: SwipeToDelete(
        itemKey: ValueKey(debt.id),
        itemId: debt.id,
        itemName: debt.name,
        onDelete: () => _confirmAndDelete(debt),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isLarge ? 178 : (isFeatured ? 148 : 0),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.5)
                  : isDueSoon
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
              width: (isOverdue || isDueSoon) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: typeColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isCompact
              ? _buildCompactTileContent(debt, typeColor)
              : _buildFullTileContent(
                  debt,
                  typeColor,
                  progress,
                  percentage,
                  isLarge,
                  isFeatured,
                  isWide,
                  isDueSoon,
                  isOverdue,
                ),
        ),
      ),
    );
  }

  Widget _buildCompactTileContent(Debt debt, Color typeColor) {
    final canPay = debt.currentBalance >= 1.0;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: _buildDebtAvatar(debt, typeColor, 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debt.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '₹${_formatCompact(debt.currentBalance)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (canPay) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showQuickPaySheet(debt),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 14,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullTileContent(
    Debt debt,
    Color typeColor,
    double progress,
    String percentage,
    bool isLarge,
    bool isFeatured,
    bool isWide,
    bool isDueSoon,
    bool isOverdue,
  ) {
    final canPay = debt.currentBalance >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Row - Icon, Name & Percentage
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: _buildDebtAvatar(debt, typeColor, 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((debt.lenderName ?? '').isNotEmpty)
                    Text(
                      debt.lenderName ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (isLarge || isFeatured) const SizedBox(height: 8),
        if (isWide) const SizedBox(height: 8),
        // Balance
        Text(
          '₹${_formatAmount(debt.currentBalance)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLarge ? 22 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((debt.monthlyEMI ?? 0) > 0) ...[
          const SizedBox(height: 2),
          Text(
            'EMI ₹${_formatCompact(debt.monthlyEMI ?? 0)} /mo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // EMI Dot Calendar (loans) or Progress Bar (credit cards)
        if (debt.totalMonths != null && debt.type.isLoan)
          EmiDotCalendar(
            totalMonths: debt.totalMonths!,
            paidMonths: debt.paidMonths ?? 0,
            startDate: debt.startDate,
            typeColor: typeColor,
            onMarkPaid: debt.currentBalance >= 1.0
                ? () => _markEmiPaid(debt)
                : null,
          )
        else
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        // Due + Pay action for large tiles
        if (isLarge) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (debt.nextPaymentDate != null)
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber : Icons.schedule,
                      size: 11,
                      color: isOverdue
                          ? AppColors.error
                          : isDueSoon
                          ? AppColors.warning
                          : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Overdue'
                          : 'Due ${DateFormat('d MMM').format(debt.nextPaymentDate ?? DateTime.now())}',
                      style: TextStyle(
                        color: isOverdue
                            ? AppColors.error
                            : isDueSoon
                            ? AppColors.warning
                            : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              if (canPay)
                GestureDetector(
                  onTap: () => _showQuickPaySheet(debt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 11,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pay',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        // Pay action for featured/wide tiles too
        if (!isLarge && canPay) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showQuickPaySheet(debt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 11,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pay',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, VoidCallback? onAdd) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: Colors.white30),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Now'),
                style: TextButton.styleFrom(foregroundColor: AppColors.info),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRenderErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.error.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load liabilities right now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Please reopen this screen. If it persists, one liability entry may have invalid data.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CollapsibleFab(
          heroTag: 'add_loan',
          onPressed: () => _showAddLoanSheet(context),
          backgroundColor: AppColors.cardSurface,
          icon: const Icon(
            Icons.account_balance,
            color: AppColors.info,
            size: 20,
          ),
          label: 'Loan',
        ),
        const SizedBox(width: 12),
        CollapsibleFab(
          heroTag: 'add_card',
          onPressed: () => _showAddCreditCardSheet(context),
          backgroundColor: AppColors.cardSurface,
          icon: const Icon(
            Icons.credit_card,
            color: AppColors.warning,
            size: 20,
          ),
          label: 'Card',
        ),
      ],
    );
  }

  // Helper Methods
  Color _getTypeColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return AppColors.warning;
      case DebtType.homeLoan:
        return Colors.blue;
      case DebtType.carLoan:
        return Colors.purple;
      case DebtType.educationLoan:
        return Colors.teal;
      case DebtType.personalLoan:
        return AppColors.info;
      case DebtType.businessLoan:
        return Colors.orange;
      case DebtType.goldLoan:
        return Colors.amber;
      case DebtType.twoWheelerLoan:
        return Colors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    }
    return NumberFormat('#,##,###').format(amount.round());
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildDebtAvatar(Debt debt, Color fallbackColor, double size) {
    final bankLogo = DebtLogoUtils.bankLogoForDebt(debt);

    if (bankLogo != null) {
      final logoScale = DebtLogoUtils.bankLogoScaleForDebt(debt);
      return LogoUtils.buildLogo(bankLogo, size: size * logoScale);
    }

    return Text(
      debt.type.icon,
      style: TextStyle(fontSize: size, color: fallbackColor),
    );
  }

  Future<void> _markEmiPaid(Debt debt) async {
    final emi = debt.monthlyEMI ?? 0;
    if (emi <= 0 || debt.currentBalance < 1.0) return;

    final newBalance = (debt.currentBalance - emi).clamp(0.0, double.infinity);
    final newPaidMonths = (debt.paidMonths ?? 0) + 1;

    DateTime? nextPaymentDate;
    if (newBalance > 0 && debt.paymentDay != null) {
      final now = DateTime.now();
      nextPaymentDate = DateTime(now.year, now.month + 1, debt.paymentDay!);
    }

    final updatedDebt = debt.copyWith(
      currentBalance: newBalance,
      paidMonths: newPaidMonths,
      nextPaymentDate: nextPaymentDate,
      updatedAt: DateTime.now(),
    );

    await context.read<DebtProvider>().updateDebt(updatedDebt);

    if (mounted) {
      HapticFeedback.heavyImpact();
      if (newBalance <= 0) {
        showTopSnackBar(
          context,
          '🎉 ${debt.name} is fully paid off!',
        );
      } else {
        showTopSnackBar(
          context,
          'EMI ₹${_formatCompact(emi)} marked as paid',
        );
      }
    }
  }

  void _confirmAndDelete(Debt debt) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete liability?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete "${debt.name}". This cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DebtProvider>().deleteDebt(debt.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${debt.name} deleted'),
                  backgroundColor: AppColors.cardElevated,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _showAddLoanSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showAddLoanModal(context);
  }

  void _showAddCreditCardSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showAddCreditCardModal(context);
  }

  void _showQuickPaySheet(Debt debt) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => QuickPayEmiSheet(debt: debt),
    );
  }

  void _showDebtDetails(Debt debt) {
    // For now, open edit - later can add details screen
    HapticFeedback.lightImpact();
    if (debt.type.isCreditCard) {
      showAddCreditCardModal(context, debtToEdit: debt);
    } else {
      showAddLoanModal(context, debtToEdit: debt);
    }
  }
}
