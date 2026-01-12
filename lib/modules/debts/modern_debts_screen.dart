import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          onPressed: () => showAddDebtModal(context),
          backgroundColor: AppColors.cardSurface,
          elevation: 0,
          icon: const Icon(Icons.add, color: AppColors.error),
          label: const Text(
            'Add Liability',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppColors.error.withOpacity(0.3)),
          ),
        ),
      ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
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
    final totalEMI = activeDebts.fold(
      0.0,
      (sum, item) => sum + (item.monthlyEMI ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error.withOpacity(0.15),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL OUTSTANDING',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(totalDebt)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Commitments: ₹${NumberFormat('#,##,###').format(totalEMI)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
    final cardOpacity = isPaidOff ? 0.6 : 1.0;
    final accentColor = isPaidOff ? AppColors.success : AppColors.error;

    return Opacity(
      opacity: cardOpacity,
      child: SwipeToDelete(
        itemKey: ValueKey(debt.id),
        itemId: debt.id,
        itemName: debt.name,
        onDelete: () => context.read<DebtProvider>().deleteDebt(debt.id),
        child: GestureDetector(
          onTap: () => showAddDebtModal(context, debtToEdit: debt),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaidOff
                            ? Icons.check_circle
                            : _getIconForType(debt.type),
                        color: accentColor,
                        size: 20,
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
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (debt.lenderName != null)
                            Text(
                              debt.lenderName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isPaidOff)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "CLEARED",
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      Text(
                        '₹${NumberFormat('#,##,###').format(debt.currentBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Neon Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Action Buttons (Only show if NOT settled)
                if (!isPaidOff) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showPayDebtModal(context, debt),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Record Payment"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percentage% Paid Off',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (debt.monthlyEMI != null && !isPaidOff)
                      Text(
                        'EMI: ₹${NumberFormat('#,##,###').format(debt.monthlyEMI)}',
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
            color: AppColors.textTertiary.withOpacity(0.3),
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
              color: AppColors.textTertiary.withOpacity(0.5),
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
}
