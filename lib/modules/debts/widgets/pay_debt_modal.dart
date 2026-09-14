import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/debt.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_draft.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/services/transaction_link_service.dart';
import '../utils/debt_logo_utils.dart';

enum PaymentKind { emi, extraPrincipal, fullBalance }

class PayDebtModal extends StatefulWidget {
  final Debt debt;

  const PayDebtModal({super.key, required this.debt});

  @override
  State<PayDebtModal> createState() => _PayDebtModalState();
}

class _PayDebtModalState extends State<PayDebtModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  PaymentKind _paymentKind = PaymentKind.emi;
  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final TransactionLinkService _linkService = const TransactionLinkService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.fadeOutCurve),
    );
    _controller.forward();

    _syncDefaultAmount(PaymentKind.emi);
  }

  void _syncDefaultAmount(PaymentKind kind) {
    _paymentKind = kind;
    double amount = 0;
    switch (kind) {
      case PaymentKind.emi:
        amount = widget.debt.monthlyEMI ?? widget.debt.currentBalance;
        if (amount > widget.debt.currentBalance) {
          amount = widget.debt.currentBalance;
        }
        break;
      case PaymentKind.fullBalance:
        amount = widget.debt.currentBalance;
        break;
      case PaymentKind.extraPrincipal:
        amount = 10000;
        break;
    }
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildPaymentKindSelector(),
                      const SizedBox(height: 20),
                      _buildContent(),
                      const SizedBox(height: 28),
                      _buildActions(),
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

  Widget _buildHeader() {
    final debtLogo = DebtLogoUtils.bankLogoForDebt(widget.debt);
    final debtLogoScale = DebtLogoUtils.bankLogoScaleForDebt(widget.debt);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Make Loan Payment",
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.debt.name,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: debtLogo != null
              ? LogoUtils.buildLogo(debtLogo, size: 20 * debtLogoScale)
              : const Icon(Icons.account_balance, color: AppColors.primaryBlue),
        ),
      ],
    );
  }

  Widget _buildPaymentKindSelector() {
    return Row(
      children: [
        if (widget.debt.monthlyEMI != null && widget.debt.monthlyEMI! > 0)
          Expanded(child: _buildKindTab("Scheduled EMI", PaymentKind.emi)),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKindTab("Extra / Part", PaymentKind.extraPrincipal),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildKindTab("Full Payoff", PaymentKind.fullBalance)),
      ],
    );
  }

  Widget _buildKindTab(String label, PaymentKind kind) {
    final isSelected = _paymentKind == kind;
    return GestureDetector(
      onTap: () => _syncDefaultAmount(kind),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textTertiary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PAYMENT AMOUNT", style: _labelStyle()),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.currency_rupee,
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.cardElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            suffixText:
                "Balance: ₹${widget.debt.currentBalance.toStringAsFixed(0)}",
            suffixStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ),

        const SizedBox(height: 18),

        Text("PAY FROM ACCOUNT", style: _labelStyle()),
        const SizedBox(height: AppSpacing.sm),
        Consumer<AccountProvider>(
          builder: (context, provider, _) {
            if (_selectedAccount == null && provider.accounts.isNotEmpty) {
              _selectedAccount = provider.accounts.first;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Account>(
                  value: _selectedAccount,
                  isExpanded: true,
                  dropdownColor: AppColors.cardElevated,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: provider.accounts.map((account) {
                    final bankLogo = LogoUtils.bankLogoFor(
                      account.bankName ?? account.name,
                    );
                    return DropdownMenuItem(
                      value: account,
                      child: Row(
                        children: [
                          bankLogo != null
                              ? LogoUtils.buildLogo(bankLogo, size: 18)
                              : Icon(
                                  IconData(
                                    account.iconCodePoint,
                                    fontFamily: account.iconFontFamily,
                                  ),
                                  color: account.color,
                                  size: 18,
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "₹${account.balance.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccount = val),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 18),

        Text("PAYMENT DATE", style: _labelStyle()),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 4,
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
                      "Record Payment",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle() => TextStyle(
    color: AppColors.textTertiary,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
  );

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showTopSnackBar(context, "Please enter a valid amount", isError: true);
      return;
    }
    if (_selectedAccount == null) {
      showTopSnackBar(context, "Please select a source account", isError: true);
      return;
    }

    final candidates = _linkService.findCandidatesForPayment(
      amount: amount,
      date: _selectedDate,
      isIncome: false,
      merchant: widget.debt.name,
      history: context.read<TransactionProvider>().transactions,
      debtId: widget.debt.id,
      dateWindowDays: 7,
    );
    final worthShowing = candidates.where((c) => c.confidence >= 0.35).toList();
    if (worthShowing.isNotEmpty) {
      final choice = await _confirmLinkBeforeSave(
        worthShowing.first.transaction,
      );
      if (choice == null) return;
      if (choice) {
        await _linkToExistingAndPay(worthShowing.first.transaction);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final isEmi = _paymentKind == PaymentKind.emi;
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        type: TransactionType.expense,
        amount: amount,
        description: isEmi
            ? "EMI Payment for ${widget.debt.name}"
            : "Loan Payment for ${widget.debt.name}",
        categoryId: "other",
        accountId: _selectedAccount!.id,
        date: _selectedDate,
        metadata: {
          'intent': 'debt_repayment',
          'debtId': widget.debt.id,
          'debtName': widget.debt.name,
          'paymentKind': _paymentKind.name,
          'paidMonthIndex': isEmi
              ? (widget.debt.paidMonths ?? 0) + 1
              : (widget.debt.paidMonths ?? 0),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txnProvider = context.read<TransactionProvider>();
      final debtProvider = context.read<DebtProvider>();

      await txnProvider.commitDraft(
        TransactionDraft.fromTransaction(transaction),
      );
      await debtProvider.payDebt(widget.debt.id, amount);

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, "Payment recorded successfully!");
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Transaction failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirmLinkBeforeSave(Transaction existing) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Already logged this payment?'),
        content: Text(
          'Found "${existing.description ?? widget.debt.name}" · '
          '₹${existing.amount.toStringAsFixed(0)} on '
          '${DateFormat('d MMM').format(existing.date)}.\n\n'
          'Link this payment to it, or record a separate transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Record new anyway'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Link instead'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkToExistingAndPay(Transaction existing) async {
    setState(() => _isLoading = true);
    try {
      final mergedMetadata = <String, dynamic>{
        ...?existing.metadata,
        'intent': existing.metadata?['intent'] ?? 'debt_repayment',
        'debtId': widget.debt.id,
        'debtName': widget.debt.name,
        'linkedAt': DateTime.now().toIso8601String(),
      };
      final updated = existing.copyWith(
        metadata: mergedMetadata,
        updatedAt: DateTime.now(),
      );

      final txnProvider = context.read<TransactionProvider>();
      final ok = await txnProvider.updateTransaction(updated, existing);
      if (!ok)
        throw Exception(txnProvider.error ?? 'Could not update transaction');

      final alreadyAppliedToDebt = existing.metadata?['debtId'] != null;
      if (!alreadyAppliedToDebt) {
        await context.read<DebtProvider>().payDebt(
          widget.debt.id,
          existing.amount,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, "Linked to existing entry");
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Could not link: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

Future<void> showPayDebtModal(BuildContext context, Debt debt) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => PayDebtModal(debt: debt),
    ),
  );
}
