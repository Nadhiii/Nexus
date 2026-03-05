import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;

  const ModernAddDebtScreen({super.key, this.debtToEdit});

  @override
  State<ModernAddDebtScreen> createState() => _ModernAddDebtScreenState();
}

class _ModernAddDebtScreenState extends State<ModernAddDebtScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _lenderController = TextEditingController();
  final _emiController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  // State
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
      _balanceController.text = d.currentBalance.toString();
      _lenderController.text = d.lenderName ?? '';
      _emiController.text = d.monthlyEMI?.toString() ?? '';
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

  @override
  Widget build(BuildContext context) {
    final title = widget.debtToEdit != null
        ? "Edit Liability"
        : "New Liability";

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(title, style: AppTypography.headlineMedium),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRIMARY AMOUNT
                    Text(
                      'Current Balance',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _balanceController,
                      autofocus: widget.debtToEdit == null,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.displayMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardDarkElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Balance is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // LIABILITY TYPE
                    Text(
                      'Liability Type',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTypeChip("Credit Card", DebtType.creditCard),
                          _buildTypeChip(
                            "Personal Loan",
                            DebtType.personalLoan,
                          ),
                          _buildTypeChip("Home Loan", DebtType.homeLoan),
                          _buildTypeChip("Car Loan", DebtType.carLoan),
                          _buildTypeChip("Education", DebtType.educationLoan),
                          _buildTypeChip("Other", DebtType.other),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // DETAILS
                    Text(
                      'Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardField(
                      controller: _nameController,
                      hint: "Debt Name (e.g. HDFC Card)",
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStandardField(
                      controller: _lenderController,
                      hint: "Lender / Bank Name",
                      icon: Icons.account_balance_outlined,
                      isRequired: false,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // TERMS
                    Text(
                      'Terms (Optional)',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStandardField(
                            controller: _emiController,
                            hint: "Monthly EMI",
                            icon: Icons.calendar_view_month,
                            isNumber: true,
                            isRequired: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStandardField(
                            controller: _rateController,
                            hint: "Interest %",
                            icon: Icons.percent,
                            isNumber: true,
                            isRequired: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // TIMELINE
                    Text(
                      'Timeline (Optional)',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDebt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                widget.debtToEdit != null
                                    ? "Save Changes"
                                    : "Save Liability",
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, DebtType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.error : AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.error : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.cardDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.sm,
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 20),
              )
            : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) { return "Required"; }
        return null;
      },
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
        );
        if (picked != null) { onSelect(picked); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM yyyy').format(date) : hint,
                style: AppTypography.bodyLarge.copyWith(
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

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) { return; }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { return; }

      final balance = double.parse(_balanceController.text);
      final emi = double.tryParse(_emiController.text);
      final rate = double.tryParse(_rateController.text);

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
        lenderName: _lenderController.text.isNotEmpty
            ? _lenderController.text
            : null,
        startDate: _startDate,
        dueDate: _dueDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<DebtProvider>(context, listen: false);
      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
      } else {
        await provider.addDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Liability saved successfully');
      }
    } catch (e) {
      if (mounted) { showTopSnackBar(context, 'Error: $e', isError: true); }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }
}

Future<void> navToAddDebtScreen(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ModernAddDebtScreen(debtToEdit: debtToEdit),
    ),
  );
}
