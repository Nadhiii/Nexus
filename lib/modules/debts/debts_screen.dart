import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_animations.dart';
import 'package:intl/intl.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/widgets/collapsible_fab.dart';
import 'utils/debt_logo_utils.dart';
import 'widgets/add_debt_modal.dart';
import 'widgets/pay_debt_modal.dart';
import '../../core/widgets/swipe_to_delete.dart';

enum DebtFilter { active, settled }

class ModernDebtsScreen extends StatefulWidget {
  const ModernDebtsScreen({super.key});

  @override
  State<ModernDebtsScreen> createState() => _ModernDebtsScreenState();
}

class _ModernDebtsScreenState extends State<ModernDebtsScreen> {
  DebtFilter _filter = DebtFilter.active;

  // --- LOGIC FIX: Tolerance Threshold ---
  // Any debt with less than 1.0 balance is considered "Paid Off"
  // This handles floating point errors (e.g., 0.000001)
  bool _isDebtSettled(Debt debt) => debt.currentBalance < 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          if (debtProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDebts = debtProvider.debts;

          // Apply Tolerance Logic
          final activeDebts = allDebts
              .where((d) => !_isDebtSettled(d))
              .toList();
          final settledDebts = allDebts
              .where((d) => _isDebtSettled(d))
              .toList();

          // Sort Logic: Biggest Debts first for Active, Recent first for Settled
          activeDebts.sort(
            (a, b) => b.currentBalance.compareTo(a.currentBalance),
          );
          settledDebts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

          final displayDebts = _filter == DebtFilter.active
              ? activeDebts
              : settledDebts;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),

              // Hero Summary (Only for Active View)
              if (_filter == DebtFilter.active && activeDebts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildSummaryCard(context, activeDebts),
                  ),
                ),

              // Filter Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildFilterPills(
                    activeDebts.length,
                    settledDebts.length,
                  ),
                ),
              ),

              // List
              if (displayDebts.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final debt = displayDebts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDebtCard(context, debt),
                      );
                    }, childCount: displayDebts.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: CollapsibleFab(
        onPressed: () => showAddDebtModal(context),
        backgroundColor: AppColors.cardSurface,
        icon: const Icon(Icons.add, color: AppColors.error),
        label: 'Add Liability',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          'Liabilities',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills(int activeCount, int settledCount) {
    return Row(
      children: [
        _buildPill("Active ($activeCount)", DebtFilter.active),
        const SizedBox(width: 12),
        _buildPill("Settled History", DebtFilter.settled),
      ],
    );
  }

  Widget _buildPill(String label, DebtFilter value) {
    final isSelected = _filter == value;
    final color = isSelected ? AppColors.error : AppColors.cardSurface;
    final textColor = isSelected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Debt> activeDebts) {
    final totalDebt = activeDebts.fold(0.0, (sum, d) => sum + d.currentBalance);
    final totalOriginal = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.originalAmount,
    );
    final totalEMI = activeDebts.fold(
      0.0,
      (sum, item) => sum + (item.monthlyEMI ?? 0),
    );
    final overallProgress = totalOriginal > 0
        ? ((totalOriginal - totalDebt) / totalOriginal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.lossGradient,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL OUTSTANDING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
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
                  '${activeDebts.length} Active',
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
            '₹${NumberFormat('#,##,###').format(totalDebt)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.black26,
              color: AppColors.success,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(overallProgress * 100).toStringAsFixed(0)}% Paid Off',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'EMI: ₹${NumberFormat.compact().format(totalEMI)}/mo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    // Calculate progress
    final progress = debt.originalAmount > 0
        ? ((debt.originalAmount - debt.currentBalance) / debt.originalAmount)
              .clamp(0.0, 1.0)
        : 0.0;

    final percentage = (progress * 100).toStringAsFixed(0);

    // --- LOGIC FIX: Check Settlement ---
    final isPaidOff = _isDebtSettled(debt);

    // Visual Style changes if Settled
    final accentColor = isPaidOff ? AppColors.success : AppColors.error;
    final typeColor = _getColorForType(debt.type);
    final bankLogo = DebtLogoUtils.bankLogoForDebt(debt);
    final logoScale = DebtLogoUtils.bankLogoScaleForDebt(debt);

    return SwipeToDelete(
      itemKey: ValueKey(debt.id),
      itemId: debt.id,
      itemName: debt.name,
      onDelete: () => context.read<DebtProvider>().deleteDebt(debt.id),
      child: GestureDetector(
        onTap: () => showAddDebtModal(context, debtToEdit: debt),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isPaidOff
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withValues(alpha: 0.12),
                      AppColors.cardSurface,
                    ],
                  ),
            color: isPaidOff
                ? AppColors.cardSurface.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPaidOff
                  ? AppColors.success.withValues(alpha: 0.3)
                  : typeColor.withValues(alpha: 0.2),
            ),
            boxShadow: isPaidOff
                ? null
                : [
                    BoxShadow(
                      color: typeColor.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isPaidOff ? AppColors.success : typeColor)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isPaidOff ? AppColors.success : typeColor)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: bankLogo != null
                        ? LogoUtils.buildLogo(bankLogo, size: 22 * logoScale)
                        : Icon(
                            isPaidOff
                                ? Icons.check_circle
                                : _getIconForType(debt.type),
                            color: isPaidOff ? AppColors.success : typeColor,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: isPaidOff
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((debt.lenderName ?? '').isNotEmpty)
                          Text(
                            debt.lenderName ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isPaidOff)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "CLEARED",
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          '₹${NumberFormat('#,##,###').format(debt.currentBalance)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (debt.monthlyEMI != null)
                          Text(
                            '₹${NumberFormat.compact().format(debt.monthlyEMI)}/mo',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Premium Progress Bar with glow
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPaidOff
                              ? [AppColors.success, AppColors.success]
                              : [typeColor.withValues(alpha: 0.8), accentColor],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: (isPaidOff ? AppColors.success : accentColor)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentage% Paid',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isPaidOff)
                    TextButton.icon(
                      onPressed: () => showPayDebtModal(context, debt),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text("Pay"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
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

  Widget _buildEmptyState(BuildContext context) {
    final isHistory = _filter == DebtFilter.settled;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory ? Icons.history : Icons.check_circle_outline,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isHistory ? "No History" : "Debt Free!",
            style: TextStyle(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            isHistory
                ? "Cleared debts will appear here."
                : "You have no active liabilities.",
            style: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getColorForType(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Colors.purple;
      case DebtType.homeLoan:
        return Colors.blue;
      case DebtType.carLoan:
        return Colors.orange;
      case DebtType.educationLoan:
        return Colors.teal;
      default:
        return AppColors.error;
    }
  }
}
