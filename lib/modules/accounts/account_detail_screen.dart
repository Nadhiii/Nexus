import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// For clipboard
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/services/pdf_statement_import_service.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_screen.dart';
import 'add_account_screen.dart';
import '../../core/services/statement_import_review_screen.dart';

class ModernAccountDetailScreen extends StatefulWidget {
  final Account account;

  const ModernAccountDetailScreen({super.key, required this.account});

  @override
  State<ModernAccountDetailScreen> createState() =>
      _ModernAccountDetailScreenState();
}

class _ModernAccountDetailScreenState extends State<ModernAccountDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _isImporting = false;
  late AnimationController _flipAnimationController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    super.dispose();
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
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.white),
                tooltip: 'Import statement',
                onPressed: _isImporting ? null : _importStatement,
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ModernAddAccountScreen(accountToEdit: widget.account),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Delete account',
                onPressed: _confirmAndDeleteAccount,
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

          // 3. ACTION BENTO GRID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Top row: Deposit gets a wider tile since it's the most
                  // common action; Pay stays compact beside it.
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildActionButton(
                            Icons.arrow_downward_rounded,
                            "Deposit",
                            AppColors.pastelGreen,
                            () => _addTransaction(TransactionType.income),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildActionButton(
                            Icons.arrow_upward_rounded,
                            "Pay",
                            AppColors.error,
                            () => _addTransaction(TransactionType.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom row: Transfer and Import share the space evenly.
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            Icons.swap_horiz_rounded,
                            "Transfer",
                            AppColors.primaryBlue,
                            () => _addTransaction(TransactionType.transfer),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            Icons.upload_file_rounded,
                            "Import",
                            AppColors.pastelPurple,
                            _isImporting ? () {} : _importStatement,
                          ),
                        ),
                      ],
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
    // Show flip card: balance on front, card details on back
    return _buildFlipCard();
  }

  Widget _buildFlipCard() {
    final bankLogo = LogoUtils.bankLogoFor(
      widget.account.bankName ?? widget.account.name,
    );
    final logoScale = LogoUtils.bankLogoScale(
      widget.account.bankName ?? widget.account.name,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _isFlipped = !_isFlipped;
          if (_isFlipped) {
            _flipAnimationController.forward();
          } else {
            _flipAnimationController.reverse();
          }
        });
      },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * 3.14159265359;
          final isBack = angle > 1.57079632679;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159265359),
                    child: _buildCardDetailsBack(bankLogo, logoScale),
                  )
                : _buildBalanceCard(bankLogo, logoScale),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(String? bankLogo, double logoScale) {
    final hasLogo = bankLogo != null;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hasLogo ? const Color(0xFF1A1A1A) : widget.account.color,
            hasLogo
                ? const Color(0xFF111111)
                : widget.account.color.withValues(alpha: 0.6),
            AppColors.black.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: hasLogo
                ? AppColors.black.withValues(alpha: 0.5)
                : widget.account.color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          if (hasLogo)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Opacity(
                  opacity: 0.2,
                  child: Center(
                    child: LogoUtils.buildLogo(bankLogo, size: 240 * logoScale),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
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
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    bankLogo != null
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: LogoUtils.buildLogo(bankLogo, size: 28),
                          )
                        : Icon(
                            widget.account.icon,
                            color: AppColors.white.withValues(alpha: 0.8),
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
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "₹${widget.account.balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ACCOUNT #",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            widget.account.accountNumber ?? "—",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontFamily: "Monospace",
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "IFSC",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            widget.account.ifscCode ?? "—",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 14,
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
          Positioned(
            bottom: 12,
            right: 12,
            child: Tooltip(
              message: "Tap to flip",
              child: Icon(
                Icons.flip,
                color: AppColors.white.withValues(alpha: 0.4),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsBack(String? bankLogo, double logoScale) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF111111),
            AppColors.black.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          // Logo background watermark
          if (bankLogo != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Opacity(
                  opacity: 0.15,
                  child: Center(
                    child: LogoUtils.buildLogo(bankLogo, size: 240 * logoScale),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.account.cardNumber != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CARD",
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.credit_card,
                        color: AppColors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CARD NUMBER",
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        widget.account.cardNumber ?? "—",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontFamily: "Monospace",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.account.cardHolderName != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "HOLDER",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            widget.account.cardHolderName!.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (widget.account.cardExpiry != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "EXPIRY",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            widget.account.cardExpiry!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FLIP TO VIEW ACCOUNT",
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Icon(
                      Icons.flip,
                      color: AppColors.white.withValues(alpha: 0.4),
                      size: 16,
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
          border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
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
                    color: isLast ? AppColors.transparent : AppColors.cardSurface,
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
                onUndoDelete: () =>
                    context.read<TransactionProvider>().restoreTransaction(t),
                showConfirmation: true,
                confirmMessage:
                    'Are you sure you want to delete this transaction?',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _editTransaction(t),
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.05),
                    ),
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
                        "$sign₹${AppCurrency.format(t.amount)}",
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
          ),
        ],
      ),
    );
  }

  void _editTransaction(Transaction t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModernAddTransactionScreen(transaction: t),
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete ${widget.account.name}?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will also delete every transaction linked to this account. '
          'You can undo this right after.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final account = widget.account;

    // Snapshot this account's transactions BEFORE deleting so undo has
    // something to restore.
    final relatedTransactions = transactionProvider.transactions
        .where(
          (t) => t.accountId == account.id || t.toAccountId == account.id,
        )
        .toList();
    accountProvider.stageForUndo(account, relatedTransactions);

    await accountProvider.deleteAccount(account.id);
    if (!mounted) return;

    Navigator.pop(context); // Leave the detail screen; account is gone.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${account.name} deleted'),
        backgroundColor: AppColors.cardElevated,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primaryBlue,
          onPressed: () => accountProvider.restoreDeletedAccount(),
        ),
      ),
    );
  }

  Future<void> _importStatement() async {
    setState(() => _isImporting = true);
    try {
      final parseData = await PdfStatementImportService.pickAndParse(
        onPromptPassword: () => _promptForPassword(),
      );

      if (!mounted) return;

      if (parseData == null) {
        // User cancelled the file picker or the password prompt.
        return;
      }

      if (parseData.transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions found in that statement')),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatementImportReviewScreen(
            account: widget.account,
            detected: parseData.transactions,
            openingBalance: parseData.openingBalance,
            closingBalance: parseData.closingBalance,
          ),
        ),
      );
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not read this statement')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// Simple password prompt used by [PdfStatementImportService] when a
  /// statement is encrypted and no saved password unlocks it.
  Future<String?> _promptForPassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Statement is password protected',
          style: TextStyle(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Enter PDF password'),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Unlock'),
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
