import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../transactions/modern_add_transaction_screen.dart';
import 'modern_add_account_screen.dart';

class ModernAccountDetailScreen extends StatefulWidget {
  final Account account;

  const ModernAccountDetailScreen({super.key, required this.account});

  @override
  State<ModernAccountDetailScreen> createState() =>
      _ModernAccountDetailScreenState();
}

class _ModernAccountDetailScreenState extends State<ModernAccountDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ModernAddAccountScreen(accountToEdit: widget.account),
                  ),
                ),
              ),
            ],
          ),

          // 2. HERO CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildHeroCard(),
            ),
          ),

          // 3. ACTION BUTTONS (Updated Labels & Colors)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.arrow_downward_rounded,
                      "Deposit",
                      AppColors.pastelGreen,
                      () => _addTransaction(TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      Icons.arrow_upward_rounded,
                      "Pay",
                      AppColors.error,
                      () => _addTransaction(TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      Icons.swap_horiz_rounded,
                      "Transfer",
                      AppColors.primaryBlue,
                      () => _addTransaction(TransactionType.transfer),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. TIMELINE HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
              child: Text(
                "HISTORY",
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // 5. TRANSACTION STREAM
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              final txs =
                  provider.transactions
                      .where(
                        (t) =>
                            t.accountId == widget.account.id ||
                            t.toAccountId == widget.account.id,
                      )
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

              if (txs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "No transactions yet",
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final t = txs[index];
                  final isLast = index == txs.length - 1;
                  return _buildTimelineItem(t, isLast);
                }, childCount: txs.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeroCard() {
    final displayNum = (widget.account.accountNumber ?? '0000')
        .padRight(4, '*')
        .substring(0, 4);

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.account.color,
            widget.account.color.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.account.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.account.bankName ?? widget.account.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                widget.account.icon,
                color: Colors.white.withOpacity(0.8),
                size: 28,
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BALANCE",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              Text(
                "₹${widget.account.balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "**** $displayNum",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: "Monospace",
                  fontSize: 16,
                ),
              ),
              Text(
                widget.account.typeDisplayName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Transaction t, bool isLast) {
    final isIncoming =
        t.type == TransactionType.income || t.toAccountId == widget.account.id;
    final color = isIncoming ? AppColors.pastelGreen : AppColors.textPrimary;
    final sign = isIncoming ? '+' : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIMELINE LEFT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.cardSurface,
                  ),
                ),
              ],
            ),
          ),

          // CONTENT RIGHT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 20),
              child: SwipeToDelete(
                itemKey: ValueKey(t.id),
                itemId: t.id,
                itemName: "Transaction",
                onDelete: () =>
                    context.read<TransactionProvider>().deleteTransaction(t.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.description ??
                                  (t.type == TransactionType.transfer
                                      ? "Transfer"
                                      : "Transaction"),
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, hh:mm a').format(t.date),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$sign₹${t.amount.toStringAsFixed(0)}",
                        style: AppTypography.titleMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTransaction(TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernAddTransactionScreen(
          accountId: widget.account.id,
          initialType: type,
        ),
      ),
    );
  }
}
