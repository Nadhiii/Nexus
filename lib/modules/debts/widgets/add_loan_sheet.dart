import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddLoanModal extends StatefulWidget {
  final Debt? debtToEdit;

  const AddLoanModal({super.key, this.debtToEdit});

  static Future<void> show(BuildContext context, {Debt? debtToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AddLoanModal(debtToEdit: debtToEdit),
    );
  }

  @override
  State<AddLoanModal> createState() => _AddLoanModalState();
}

class _AddLoanModalState extends State<AddLoanModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _balanceController = TextEditingController();
  final _emiController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _lenderController = TextEditingController();

  DebtType _selectedType = DebtType.personalLoan;
  int _paymentDay = 5;
  DateTime _loanStartDate = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  bool _isOngoingLoan = false;

  bool get _isEditMode => widget.debtToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final d = widget.debtToEdit!;
      _nameController.text = d.name;
      _originalAmountController.text = d.originalAmount.toStringAsFixed(0);
      _balanceController.text = d.currentBalance.toStringAsFixed(0);
      _emiController.text = d.monthlyEMI?.toStringAsFixed(0) ?? '';
      _rateController.text = d.interestRate?.toString() ?? '';
      _tenureController.text = d.totalMonths?.toString() ?? '';
      _lenderController.text = d.lenderName ?? '';
      _selectedType = d.type;
      _paymentDay = d.paymentDay ?? 5;
      final start = d.startDate ?? DateTime.now();
      _loanStartDate = DateTime(start.year, start.month);
      _isOngoingLoan = (d.originalAmount != d.currentBalance);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originalAmountController.dispose();
    _balanceController.dispose();
    _emiController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _lenderController.dispose();
    super.dispose();
  }

  void _calculateEMI() {
    final principal =
        double.tryParse(_originalAmountController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;

    if (principal > 0 && rate > 0 && tenure > 0) {
      final monthlyRate = rate / 12 / 100;
      final emi =
          (principal * monthlyRate * math.pow(1 + monthlyRate, tenure)) /
          (math.pow(1 + monthlyRate, tenure) - 1);
      _emiController.text = emi.round().toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showTopSnackBar(context, 'Please sign in first', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DebtProvider>();
      final now = DateTime.now();

      final originalAmount = double.parse(
        _originalAmountController.text.trim(),
      );
      final currentBalance = _isOngoingLoan
          ? (double.tryParse(_balanceController.text.trim()) ?? originalAmount)
          : originalAmount;

      final emi = double.tryParse(_emiController.text.trim());
      final rate = double.tryParse(_rateController.text.trim());
      final tenure = int.tryParse(_tenureController.text.trim());

      final debt = Debt(
        id:
            widget.debtToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        name: _nameController.text.trim(),
        type: _selectedType,
        originalAmount: originalAmount,
        currentBalance: currentBalance,
        monthlyEMI: emi,
        interestRate: rate,
        totalMonths: tenure,
        paymentDay: _paymentDay,
        lenderName: _lenderController.text.trim().isNotEmpty
            ? _lenderController.text.trim()
            : null,
        startDate: _loanStartDate,
        createdAt: widget.debtToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
      } else {
        await provider.addDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          context,
          widget.debtToEdit != null ? 'Loan updated' : 'Loan recorded',
        );
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
    const activeColor = AppColors.primaryBlue;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode ? 'Edit Formal Loan' : 'Record Formal Loan',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: AppSpacing.iconSm,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Loan State Mode Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: AppColors.borderSubtleDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildModeTab("New Loan", false)),
                      Expanded(
                        child: _buildModeTab("Already Paying Off", true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('ORIGINAL LOAN AMOUNT BORROWED'),
                TextFormField(
                  controller: _originalAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) {
                    if (!_isOngoingLoan) {
                      _balanceController.text = val;
                    }
                    _calculateEMI();
                  },
                  style: AppTypography.currencyMedium.copyWith(
                    color: activeColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: activeColor,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: activeColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_isOngoingLoan) ...[
                  _buildLabel('OUTSTANDING BALANCE REMAINING TODAY'),
                  _buildField(
                    controller: _balanceController,
                    hint: "Current unpaid balance",
                    icon: Icons.account_balance_wallet_outlined,
                    isNumber: true,
                    validator: (val) {
                      if (!_isOngoingLoan) return null;
                      if (val == null || val.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _buildLabel('LOAN TYPE'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('Personal', DebtType.personalLoan),
                    _buildTypeChip('Home Loan', DebtType.homeLoan),
                    _buildTypeChip('Car Loan', DebtType.carLoan),
                    _buildTypeChip('Education', DebtType.educationLoan),
                    _buildTypeChip('Two-Wheeler', DebtType.twoWheelerLoan),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('LOAN TITLE / PURPOSE'),
                _buildField(
                  controller: _nameController,
                  hint: "e.g. HDFC Home Loan, Axis Auto Loan",
                  icon: Icons.title_outlined,
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildLabel('LENDER / BANK NAME'),
                _buildField(
                  controller: _lenderController,
                  hint: "e.g. State Bank of India, HDFC Bank",
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('INTEREST % P.A.'),
                          _buildField(
                            controller: _rateController,
                            hint: "e.g. 8.5",
                            icon: Icons.percent_outlined,
                            isNumber: true,
                            onChanged: (_) => _calculateEMI(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('TENURE (MONTHS)'),
                          _buildField(
                            controller: _tenureController,
                            hint: "e.g. 60",
                            icon: Icons.timer_outlined,
                            isNumber: true,
                            onChanged: (_) => _calculateEMI(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('SCHEDULED MONTHLY EMI'),
                _buildField(
                  controller: _emiController,
                  hint: "Calculated or custom EMI",
                  icon: Icons.calendar_month_outlined,
                  isNumber: true,
                ),
                const SizedBox(height: AppSpacing.xl2),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                            side: const BorderSide(
                              color: AppColors.borderSubtleDark,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: activeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode ? 'Save Changes' : 'Record Loan',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildModeTab(String label, bool isOngoing) {
    final isSelected = _isOngoingLoan == isOngoing;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isOngoingLoan = isOngoing;
          if (!isOngoing) {
            _balanceController.text = _originalAmountController.text;
          }
        });
      },
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, DebtType type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      backgroundColor: AppColors.darkSurfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtleDark,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

Future<void> showAddLoanModal(BuildContext context, {Debt? debtToEdit}) {
  return AddLoanModal.show(context, debtToEdit: debtToEdit);
}

typedef AddLoanSheet = AddLoanModal;
