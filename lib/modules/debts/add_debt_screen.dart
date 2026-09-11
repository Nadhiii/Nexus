import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;

  const ModernAddDebtScreen({super.key, this.debtToEdit});

  static Future<void> show(BuildContext context, {Debt? debtToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ModernAddDebtScreen(debtToEdit: debtToEdit),
    );
  }

  @override
  State<ModernAddDebtScreen> createState() => _ModernAddDebtScreenState();
}

class _ModernAddDebtScreenState extends State<ModernAddDebtScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _lenderController = TextEditingController();
  final _emiController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  DebtType _selectedType = DebtType.creditCard;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      final d = widget.debtToEdit!;
      _nameController.text = d.name;
      _balanceController.text = d.currentBalance.toStringAsFixed(0);
      _lenderController.text = d.lenderName ?? '';
      _emiController.text = d.monthlyEMI?.toStringAsFixed(0) ?? '';
      _rateController.text = d.interestRate?.toString() ?? '';
      _notesController.text = d.notes ?? '';
      _selectedType = d.type;
      _startDate = d.startDate;
      _dueDate = d.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _lenderController.dispose();
    _emiController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final balance = double.parse(_balanceController.text.trim());
      final emi = double.tryParse(_emiController.text.trim());
      final rate = double.tryParse(_rateController.text.trim());

      final debt = Debt(
        id:
            widget.debtToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        name: _nameController.text.trim(),
        type: _selectedType,
        originalAmount: widget.debtToEdit?.originalAmount ?? balance,
        currentBalance: balance,
        monthlyEMI: emi,
        interestRate: rate,
        lenderName: _lenderController.text.trim().isNotEmpty
            ? _lenderController.text.trim()
            : null,
        startDate: _startDate,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<DebtProvider>();
      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
      } else {
        await provider.addDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          context,
          widget.debtToEdit != null ? 'Liability updated' : 'Liability saved',
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
    final isEditing = widget.debtToEdit != null;

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
                      isEditing ? 'Edit Liability' : 'New Liability',
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
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('OUTSTANDING BALANCE'),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.currencyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.error,
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
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return "Balance is required";
                    if (double.tryParse(val.trim()) == null)
                      return "Enter a valid amount";
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('LIABILITY TYPE'),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTypeChip("Credit Card", DebtType.creditCard),
                      _buildTypeChip("Personal Loan", DebtType.personalLoan),
                      _buildTypeChip("Home Loan", DebtType.homeLoan),
                      _buildTypeChip("Car Loan", DebtType.carLoan),
                      _buildTypeChip("Education", DebtType.educationLoan),
                      _buildTypeChip("Other", DebtType.other),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('LIABILITY DETAILS'),
                _buildField(
                  controller: _nameController,
                  hint: "Liability Title (e.g. HDFC Regalia, Home Mortgage)",
                  icon: Icons.description_outlined,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Title is required"
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildField(
                  controller: _lenderController,
                  hint: "Lender / Institution (e.g. HDFC Bank, SBI)",
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('TERMS (OPTIONAL)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _emiController,
                        hint: "Monthly EMI",
                        icon: Icons.calendar_view_month_outlined,
                        isNumber: true,
                        prefix: "₹",
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildField(
                        controller: _rateController,
                        hint: "Interest %",
                        icon: Icons.percent_outlined,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('TIMELINE (OPTIONAL)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        "Start Date",
                        _startDate,
                        (d) => setState(() => _startDate = d),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDatePicker(
                        "End Date",
                        _dueDate,
                        (d) => setState(() => _dueDate = d),
                      ),
                    ),
                  ],
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
                        onPressed: _isLoading ? null : _saveDebt,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.error,
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
                                isEditing ? 'Save Changes' : 'Add Liability',
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

  Widget _buildTypeChip(String label, DebtType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
      },
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.borderSubtleDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? AppColors.error : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix != null ? "$prefix " : null,
        prefixStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
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
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker(
    String hint,
    DateTime? date,
    Function(DateTime) onSelect,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.error,
                  surface: AppColors.darkSurfaceElevated,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(color: AppColors.borderSubtleDark),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date) : hint,
                style: AppTypography.bodySmall.copyWith(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation Helpers & Backward Compatibility
Future<void> navToAddDebtScreen(BuildContext context, {Debt? debtToEdit}) {
  return ModernAddDebtScreen.show(context, debtToEdit: debtToEdit);
}

Future<void> showAddDebtModal(BuildContext context, {Debt? debtToEdit}) {
  return ModernAddDebtScreen.show(context, debtToEdit: debtToEdit);
}

typedef AddDebtModal = ModernAddDebtScreen;
