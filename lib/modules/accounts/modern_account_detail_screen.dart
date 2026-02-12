import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For clipboard
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/services/secure_card_service.dart';
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
  bool _showFullCardDetails = false;
  String? _secureCvv;
  final SecureCardService _secureCardService = SecureCardService();

  @override
  void initState() {
    super.initState();
    _loadSecureCvv();
  }

  Future<void> _loadSecureCvv() async {
    final cvv = await _secureCardService.getCvv(widget.account.id);
    if (mounted) {
      setState(() => _secureCvv = cvv);
    }
  }

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
              child: Column(
                children: [
                  _buildHeroCard(),
                  if (widget.account.cardNumber != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFullCardDetails = !_showFullCardDetails;
                        });
                      },
                      icon: Icon(
                        _showFullCardDetails
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                      label: Text(
                        _showFullCardDetails
                            ? "Hide Details"
                            : "Show Card Details",
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. ACTION BUTTONS
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
    // If user toggles "Show Card Details", we switch the content
    if (_showFullCardDetails && widget.account.cardNumber != null) {
      return _buildFullCardView();
    }

    // Default View (Balance)
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

  Widget _buildFullCardView() {
    return GestureDetector(
      onLongPress: () {
        if (widget.account.cardNumber != null) {
          Clipboard.setData(ClipboardData(text: widget.account.cardNumber!));
          showTopSnackBar(context, "Card Number Copied");
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: widget.account.color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.nfc, color: Colors.white54, size: 32),
                Icon(Icons.credit_card, color: widget.account.color, size: 28),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.account.cardNumber ?? "---- ---- ---- ----",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: "Monospace",
                    fontSize: 22,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CARD HOLDER",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      (widget.account.cardHolderName ?? "YOUR NAME")
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EXPIRES",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          widget.account.cardExpiry ?? "MM/YY",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CVV",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          _secureCvv ?? "***",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
