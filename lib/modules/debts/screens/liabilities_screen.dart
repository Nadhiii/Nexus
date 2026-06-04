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
import '../add_debt_screen.dart';
import '../widgets/pay_debt_modal.dart';

/// Bento tile types for dynamic sizing
enum _BentoTileType { featured, large, wide, compact }

/// Filter types for liabilities
enum _LiabilityFilter { loans, creditCards, settled }

class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  _LiabilityFilter _filter = _LiabilityFilter.loans;

  bool _isValidDebt(Debt debt) => !debt.type.isLegacyIOU;
  bool _isSettled(Debt debt) => debt.currentBalance < 1.0;

  // Safe fallback for info color
  Color get _infoColor {
    try {
      return AppColors.info;
    } catch (_) {
      return Colors.blue;
    }
  }

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

            loans.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
            creditCards.sort(
              (a, b) => b.currentBalance.compareTo(a.currentBalance),
            );
            settled.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
                      style: (AppTypography.headlineMedium).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

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
                          : () => navToAddDebtScreen(context),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
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
          } catch (e) {
            debugPrint('Liabilities screen render failed: $e');
            return _buildRenderErrorState(e);
          }
        },
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    final color = isSelected ? _infoColor : AppColors.cardSurface;

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
            color: isSelected ? _infoColor : Colors.white.withOpacity(0.1),
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
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
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
    if (settled.isEmpty) return const SizedBox.shrink();

    final totalPaid = settled.fold(0.0, (sum, d) => sum + d.originalAmount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
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
                        color: Colors.white.withOpacity(0.5),
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
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${settled.length} ${settled.length == 1 ? 'debt' : 'debts'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
      onTap: () => navToAddDebtScreen(context, debtToEdit: debt),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
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
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
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
            Text(
              '₹${_formatCompact(debt.originalAmount)}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$percentage% of total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
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

    int totalEmiCount = 0;
    int paidEmiCount = 0;
    for (final debt in activeDebts) {
      if (debt.totalMonths != null) {
        totalEmiCount += debt.totalMonths!;
        paidEmiCount += debt.paidMonths ?? 0;
      }
    }

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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
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
                    AppColors.success.withOpacity(0.12),
                    AppColors.success.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 8,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.success.withOpacity(0.08),
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: Colors.white.withOpacity(0.5),
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
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹${_formatCompact(totalPaid)} paid',
                                      style: const TextStyle(
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
                    if (totalEmiCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
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
                                color: Colors.white.withOpacity(0.5),
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
            ? AppColors.warning.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppColors.warning.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.5),
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

  Widget _buildDynamicBentoGrid(List<Debt> debts, double totalDebt) {
    if (debts.isEmpty) return const SizedBox.shrink();

    final List<Widget> rows = [];
    int index = 0;

    while (index < debts.length) {
      final remaining = debts.length - index;

      if (remaining == 1) {
        rows.add(
          _buildBentoTile(
            debts[index],
            totalDebt,
            tileType: _BentoTileType.featured,
          ),
        );
        index++;
      } else if (remaining == 2) {
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
      } else {
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
      }
      if (index < debts.length) rows.add(const SizedBox(height: 12));
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
    final isLarge = tileType == _BentoTileType.large;

    return GestureDetector(
      onTap: () => navToAddDebtScreen(context, debtToEdit: debt),
      child: SwipeToDelete(
        itemKey: ValueKey(debt.id),
        itemId: debt.id,
        itemName: debt.name,
        onDelete: () => _confirmAndDelete(debt),
        child: Container(
          constraints: BoxConstraints(minHeight: isLarge ? 178 : 148),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.5)
                  : isDueSoon
                  ? AppColors.warning.withOpacity(0.5)
                  : Colors.white.withOpacity(0.05),
              width: (isOverdue || isDueSoon) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: typeColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _buildFullTileContent(
            debt,
            typeColor,
            progress,
            percentage,
            isLarge,
            isDueSoon,
            isOverdue,
          ),
        ),
      ),
    );
  }

  Widget _buildFullTileContent(
    Debt debt,
    Color typeColor,
    double progress,
    String percentage,
    bool isLarge,
    bool isDueSoon,
    bool isOverdue,
  ) {
    final canPay = debt.currentBalance >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
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
                        color: Colors.white.withOpacity(0.4),
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
        const SizedBox(height: 8),
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
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                  onTap: () => showPayDebtModal(context, debt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 11,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
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
        if (!isLarge && canPay) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => showPayDebtModal(context, debt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 11,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: Colors.white30),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Now'),
                style: TextButton.styleFrom(foregroundColor: _infoColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Purely fail-proof rendering so we don't accidentally get a blank screen
  Widget _buildRenderErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'UI Error encountered',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      // Lowers the FAB slightly. Increase this value if you want it even lower.
      padding: const EdgeInsets.only(bottom: 4.0),
      child: FloatingActionButton.extended(
        onPressed: () => _showActionOptions(context),
        backgroundColor: AppColors.cardSurface,
        icon: const Icon(Icons.add, color: AppColors.error),
        label: const Text(
          'Add Liability',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // New method to show the bottom sheet menu
  void _showActionOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      // 1. Swapped the background to perfectly match your app's base canvas
      backgroundColor: AppColors.backgroundBlack,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        // 2. Added a very subtle top border outline to define the pop-up edge
        decoration: BoxDecoration(
          color: AppColors.backgroundBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle pill
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Loan Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _infoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance, color: _infoColor),
                ),
                title: const Text(
                  'Add Loan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Personal, Home, Car, etc.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  navToAddDebtScreen(context);
                },
              ),
              const SizedBox(height: 8),
              // Card Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: AppColors.warning,
                  ),
                ),
                title: const Text(
                  'Add Credit Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Manage card dues and EMIs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  navToAddDebtScreen(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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
        return _infoColor;
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
    if (amount >= 10000000)
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)} L';
    return NumberFormat('#,##,###').format(amount.round());
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
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
          'This will permanently delete "${debt.name}".',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DebtProvider>().deleteDebt(debt.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
