import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/account.dart';
import '../../core/models/detected_transaction.dart';
import '../../core/models/transaction.dart' as txn;
import '../../core/providers/transaction_provider.dart';
import '../../core/widgets/top_snackbar.dart';

/// One row in the bulk review list. Wraps a [DetectedTransaction] with the
/// mutable state the user can edit before saving (selection, type, merchant,
/// date) plus whether it's a likely duplicate of something already in this
/// account.
class _ReviewItem {
  final DetectedTransaction detected;
  bool selected;
  bool isIncome;
  String merchant;
  DateTime date;
  final bool isDuplicate;

  _ReviewItem({
    required this.detected,
    required this.selected,
    required this.isIncome,
    required this.merchant,
    required this.date,
    required this.isDuplicate,
  });
}

/// Bulk "review & confirm" screen shown after a PDF statement has been
/// parsed for a specific [Account].
class StatementImportReviewScreen extends StatefulWidget {
  final Account account;
  final List<DetectedTransaction> detected;
  
  // Added optional parameters for opening and closing balances
  final double? openingBalance;
  final double? closingBalance;

  const StatementImportReviewScreen({
    super.key,
    required this.account,
    required this.detected,
    this.openingBalance,
    this.closingBalance,
  });

  @override
  State<StatementImportReviewScreen> createState() =>
      _StatementImportReviewScreenState();
}

class _StatementImportReviewScreenState
    extends State<StatementImportReviewScreen> {
  late List<_ReviewItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Build the existing-fingerprint set for THIS account only
    final existingFingerprints = context
        .read<TransactionProvider>()
        .transactions
        .where((t) => t.accountId == widget.account.id)
        .map((t) => t.metadata?['fingerprint'] as String?)
        .whereType<String>()
        .toSet();

    _items = widget.detected.map((d) {
      final isDup = existingFingerprints.contains(d.fingerprint);
      return _ReviewItem(
        detected: d,
        selected: !isDup, // duplicates start unchecked
        isIncome: d.type.toLowerCase() == 'income',
        merchant: d.merchant,
        date: d.date,
        isDuplicate: isDup,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _selectedCount => _items.where((i) => i.selected).length;

  double get _selectedTotal {
    double total = 0;
    for (final i in _items) {
      if (!i.selected) continue;
      total += i.isIncome ? i.detected.amount : -i.detected.amount;
    }
    return total;
  }

  String? get _bankName =>
      widget.detected.isNotEmpty ? widget.detected.first.bankName : null;

  Future<void> _confirmImport() async {
    if (_selectedCount == 0) {
      showTopSnackBar(context, 'Select at least one transaction', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      showTopSnackBar(context, 'You need to be signed in', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    final provider = context.read<TransactionProvider>();
    int savedCount = 0;
    int failedCount = 0;

    for (final item in _items.where((i) => i.selected)) {
      final now = DateTime.now();
      final id = FirebaseFirestore.instance.collection('transactions').doc().id;

      final transaction = txn.Transaction(
        id: id,
        userId: userId,
        type: item.isIncome ? txn.TransactionType.income : txn.TransactionType.expense,
        amount: item.detected.amount,
        description: item.merchant,
        categoryId: null, // left for the user to set later, as usual
        accountId: widget.account.id,
        date: item.date,
        metadata: {
          'fingerprint': item.detected.fingerprint,
          'source': 'pdf_statement',
          'bankName': item.detected.bankName,
          if (item.detected.detectedCategory != null)
            'suggestedCategory': item.detected.detectedCategory,
        },
        createdAt: now,
        updatedAt: now,
      );

      final ok = await provider.addTransaction(transaction);
      if (ok) {
        savedCount++;
      } else {
        failedCount++;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (failedCount == 0) {
      showTopSnackBar(context, 'Imported $savedCount transaction(s)');
      Navigator.of(context).pop(true);
    } else {
      showTopSnackBar(
        context,
        'Imported $savedCount, $failedCount failed — check and retry',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: Text(
          'Review Statement',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _items.every((i) => i.selected)
                ? () => setState(() {
                      for (final i in _items) {
                        i.selected = false;
                      }
                    })
                : () => setState(() {
                      for (final i in _items) {
                        i.selected = true;
                      }
                    }),
            child: Text(
              _items.every((i) => i.selected) ? 'Deselect all' : 'Select all',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found in this statement',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildRow(_items[index]),
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final bank = _bankName;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank != null ? '$bank statement' : 'Statement',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Importing into ${widget.account.name}',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                // Added logic to display opening and closing balances
                if (widget.openingBalance != null || widget.closingBalance != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.openingBalance != null)
                        Expanded(
                          child: Text(
                            'Opening: ₹${widget.openingBalance!.toStringAsFixed(2)}',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ),
                      if (widget.closingBalance != null)
                        Expanded(
                          child: Text(
                            'Closing: ₹${widget.closingBalance!.toStringAsFixed(2)}',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${_selectedTotal >= 0 ? '+' : '−'}₹${_selectedTotal.abs().toStringAsFixed(2)}',
            style: AppTypography.titleMedium.copyWith(
              color: _selectedTotal >= 0 ? AppColors.pastelGreen : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_ReviewItem item) {
    final color = item.isIncome ? AppColors.pastelGreen : AppColors.error;
    return Opacity(
      opacity: item.isDuplicate && !item.selected ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.selected
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.selected,
              activeColor: AppColors.primaryBlue,
              onChanged: (v) => setState(() => item.selected = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.merchant,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => item.isIncome = !item.isIncome),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: color,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.isIncome ? '+' : '−'}₹${item.detected.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(item.date),
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      if (item.isDuplicate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Already imported',
                            style: TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _confirmImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Import $_selectedCount transaction${_selectedCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
      ),
    );
  }
}