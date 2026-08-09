import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/debt.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/utils/logo_utils.dart';
import '../utils/debt_logo_utils.dart';

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

  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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

    // Default amount to EMI if available, else current balance
    double defaultAmount = widget.debt.monthlyEMI ?? 0;
    if (defaultAmount == 0 || defaultAmount > widget.debt.currentBalance) {
      defaultAmount = widget.debt.currentBalance;
    }
    _amountController.text = defaultAmount.toStringAsFixed(0);
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
          // Blur Backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildContent(),
                    const SizedBox(height: 32),
                    _buildActions(),
                  ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Record Payment",
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "for ${widget.debt.name}",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: debtLogo != null
              ? LogoUtils.buildLogo(debtLogo, size: 20 * debtLogoScale)
              : const Icon(Icons.payments_outlined, color: AppColors.error),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Amount Input
        Text("AMOUNT", style: _labelStyle()),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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
                "Outstanding: ₹${widget.debt.currentBalance.toStringAsFixed(0)}",
            suffixStyle: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 2. Source Account Selector
        Text("PAY FROM", style: _labelStyle()),
        const SizedBox(height: AppSpacing.sm),
        Consumer<AccountProvider>(
          builder: (context, provider, _) {
            // Auto-select first account if none selected
            if (_selectedAccount == null && provider.accounts.isNotEmpty) {
              _selectedAccount = provider.accounts.first;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
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

        const SizedBox(height: 20),

        // 3. Date Picker Pill
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) { setState(() => _selectedDate = picked); }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
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
            ),
          ],
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
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: AppColors.error.withValues(alpha: 0.4),
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
                      "Confirm Payment",
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
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
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

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { throw Exception("User not logged in"); }

      // 1. Create Transaction (This handles the Account Debit automatically!)
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        userId: user.uid,
        type: TransactionType
            .expense, // Expense because money leaves your net worth
        amount: amount,
        description: "Payment for ${widget.debt.name}",
        categoryId: "debt_repayment", // Or fetch ID for 'Debt'
        accountId: _selectedAccount!.id,
        date: _selectedDate,
        metadata: {
          'intent': 'debt_repayment',
          'debtId': widget.debt.id,
          'debtName': widget.debt.name,
          'paidMonthIndex': (widget.debt.paidMonths ?? 0) + 1,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txnProvider = context.read<TransactionProvider>();
      final debtProvider = context.read<DebtProvider>();

      // Execute Bridge Actions
      await txnProvider.addTransaction(transaction); // Updates Account Balance
      await debtProvider.payDebt(
        widget.debt.id,
        amount,
      ); // Updates Debt Balance

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, "Payment recorded successfully!");
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Transaction failed: $e", isError: true);
      }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }
}

// Wrapper for easy call
Future<void> showPayDebtModal(BuildContext context, Debt debt) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => PayDebtModal(debt: debt),
    ),
  );
}