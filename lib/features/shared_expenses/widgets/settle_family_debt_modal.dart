import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/models/family_debt.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_draft.dart';
import '../../../core/providers/family_debt_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/widgets/top_snackbar.dart';

class SettleFamilyDebtModal extends StatefulWidget {
  final FamilyDebt debt;

  const SettleFamilyDebtModal({super.key, required this.debt});

  static Future<void> show(BuildContext context, FamilyDebt debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettleFamilyDebtModal(debt: debt),
    );
  }

  @override
  State<SettleFamilyDebtModal> createState() => _SettleFamilyDebtModalState();
}

class _SettleFamilyDebtModalState extends State<SettleFamilyDebtModal> {
  final _amountController = TextEditingController();
  Account? _selectedAccount;
  bool _recordInBank = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.debt.currentAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showTopSnackBar(
        context,
        'Enter a valid settlement amount',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final currentUserId = user?.uid;
      final isLentByMe = widget.debt.creditorId == currentUserId;

      // 1. If bank recording is requested, create an Expense or Income transaction
      if (_recordInBank && _selectedAccount != null && user != null) {
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          type: isLentByMe ? TransactionType.income : TransactionType.expense,
          amount: amount,
          description: isLentByMe
              ? 'Settlement received from ${widget.debt.debtorName}'
              : 'Settlement paid to ${widget.debt.creditorName}',
          categoryId: 'transfer',
          accountId: _selectedAccount!.id,
          date: DateTime.now(),
          metadata: {'intent': 'peer_settlement', 'debtId': widget.debt.id},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await context.read<TransactionProvider>().commitDraft(
          TransactionDraft.fromTransaction(transaction),
        );
      }

      // 2. Record payment in the debt provider
      final debtProvider = context.read<FamilyDebtProvider>();
      if (amount >= widget.debt.currentAmount) {
        await debtProvider.settleDebt(widget.debt.id);
      } else {
        await debtProvider.recordPayment(
          widget.debt.id,
          amount,
          notes: 'Partial settlement',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Settlement recorded successfully!');
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isLentByMe =
        widget.debt.creditorId == FirebaseAuth.instance.currentUser?.uid;
    final otherParty = isLentByMe
        ? widget.debt.debtorName
        : widget.debt.creditorName;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtleDark,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Settle Balance',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                isLentByMe
                    ? 'Receiving payment from $otherParty'
                    : 'Making payment to $otherParty',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('SETTLEMENT AMOUNT', style: _labelStyle()),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.borderSubtleDark,
                    ),
                  ),
                  suffixText:
                      'Outstanding: ₹${AppCurrency.format(widget.debt.currentAmount)}',
                  suffixStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Bank Reflection Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtleDark),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Record in Bank Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isLentByMe
                        ? 'Deposits amount into your account'
                        : 'Debits amount from your account',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  value: _recordInBank,
                  activeThumbColor: AppColors.primaryBlue,
                  onChanged: (val) => setState(() => _recordInBank = val),
                ),
              ),

              if (_recordInBank) ...[
                const SizedBox(height: 16),
                Text('CHOOSE ACCOUNT', style: _labelStyle()),
                const SizedBox(height: 6),
                Consumer<AccountProvider>(
                  builder: (context, provider, _) {
                    if (_selectedAccount == null &&
                        provider.accounts.isNotEmpty) {
                      _selectedAccount = provider.accounts.first;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtleDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Account>(
                          value: _selectedAccount,
                          isExpanded: true,
                          dropdownColor: AppColors.cardElevated,
                          items: provider.accounts.map((acc) {
                            return DropdownMenuItem(
                              value: acc,
                              child: Row(
                                children: [
                                  Text(
                                    acc.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${acc.balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (acc) =>
                              setState(() => _selectedAccount = acc),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Settlement',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    color: AppColors.textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
}
