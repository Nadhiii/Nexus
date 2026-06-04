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
import '../../../core/widgets/top_snackbar.dart';

/// Quick Pay EMI Sheet
/// One-tap EMI payment recording
class QuickPayEmiSheet extends StatefulWidget {
  final Debt debt;

  const QuickPayEmiSheet({super.key, required this.debt});

  @override
  State<QuickPayEmiSheet> createState() => _QuickPayEmiSheetState();
}

class _QuickPayEmiSheetState extends State<QuickPayEmiSheet> {
  final _amountController = TextEditingController();
  final _paidMonthsController = TextEditingController();
  bool _isLoading = false;
  bool _useCustomAmount = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with EMI amount
    final monthlyEmi = widget.debt.monthlyEMI;
    if (monthlyEmi != null) {
      _amountController.text = monthlyEmi.round().toString();
    }
    _paidMonthsController.text = (widget.debt.paidMonths ?? 0).toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    final emi = debt.monthlyEMI ?? 0;
    final balance = debt.currentBalance;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Payment',
                            style: AppTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            debt.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Current Balance Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outstanding Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${NumberFormat('#,##,###').format(balance.round())}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (emi > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Monthly EMI',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${NumberFormat('#,##,###').format(emi.round())}',
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Amount Buttons
                if (emi > 0) ...[
                  Text(
                    'PAYMENT AMOUNT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountOption(
                          label: 'EMI',
                          amount: emi,
                          isSelected: !_useCustomAmount,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _useCustomAmount = false;
                              _amountController.text = emi.round().toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAmountOption(
                          label: 'Full',
                          amount: balance,
                          isSelected: false,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _useCustomAmount = true;
                              _amountController.text = balance
                                  .round()
                                  .toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAmountOption(
                          label: 'Custom',
                          isSelected: _useCustomAmount,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _useCustomAmount = true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount Input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: _useCustomAmount || emi <= 0,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
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
                  ),
                ),
                const SizedBox(height: 8),

                // New Balance Preview
                if (_amountController.text.isNotEmpty) ...[
                  Center(
                    child: Text(
                      _getNewBalanceText(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (debt.totalMonths != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'COMPLETED EMIS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _paidMonthsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paid months',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      suffixText: '/ ${debt.totalMonths}',
                      suffixStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
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
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _recordPayment,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isLoading ? 'Recording...' : 'Record Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountOption({
    required String label,
    double? amount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.success : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(height: 4),
              Text(
                '₹${_formatCompact(amount)}',
                style: TextStyle(
                  color: isSelected ? AppColors.success : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.round().toString();
  }

  String _getNewBalanceText() {
    final payment = double.tryParse(_amountController.text) ?? 0;
    final newBalance = (widget.debt.currentBalance - payment).clamp(
      0.0,
      double.infinity,
    );

    if (newBalance <= 0) {
      return '🎉 This will clear your debt!';
    }

    return 'New balance: ₹${NumberFormat('#,##,###').format(newBalance.round())}';
  }

  Future<void> _recordPayment() async {
    final paymentAmount = double.tryParse(_amountController.text);

    if (paymentAmount == null || paymentAmount <= 0) {
      showTopSnackBar(context, 'Enter a valid amount', isError: true);
      return;
    }

    if (paymentAmount > widget.debt.currentBalance) {
      showTopSnackBar(
        context,
        'Amount exceeds outstanding balance',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DebtProvider>();
      final debt = widget.debt;

      // Calculate new balance
      final newBalance = (debt.currentBalance - paymentAmount).clamp(
        0.0,
        double.infinity,
      );

      // Calculate new paid months (if EMI exists)
      int? newPaidMonths = debt.paidMonths;
      final monthlyEmi = debt.monthlyEMI ?? 0;
      if (monthlyEmi > 0) {
        final emiPayments = (paymentAmount / monthlyEmi).floor();
        newPaidMonths = (debt.paidMonths ?? 0) + emiPayments;
      }
      final manualPaidMonths = int.tryParse(_paidMonthsController.text);
      if (manualPaidMonths != null && manualPaidMonths >= 0) {
        if (debt.totalMonths != null) {
          newPaidMonths = manualPaidMonths.clamp(0, debt.totalMonths!);
        } else {
          newPaidMonths = manualPaidMonths;
        }
      }

      // Calculate next payment date
      DateTime? nextPaymentDate;
      if (newBalance > 0 && debt.paymentDay != null) {
        final now = DateTime.now();
        nextPaymentDate = DateTime(now.year, now.month + 1, debt.paymentDay!);
      }

      // Update debt
      final updatedDebt = debt.copyWith(
        currentBalance: newBalance,
        paidMonths: newPaidMonths,
        nextPaymentDate: nextPaymentDate,
        updatedAt: DateTime.now(),
      );

      await provider.updateDebt(updatedDebt);

      if (mounted) {
        HapticFeedback.heavyImpact();

        if (newBalance <= 0) {
          showTopSnackBar(
            context,
            '🎉 Congratulations! ${debt.name} is fully paid off!',
          );
        } else {
          showTopSnackBar(
            context,
            'Payment of ₹${NumberFormat('#,##,###').format(paymentAmount.round())} recorded',
          );
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
