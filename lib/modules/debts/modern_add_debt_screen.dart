import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';
import '../../core/widgets/top_snackbar.dart';

class ModernAddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;

  const ModernAddDebtScreen({super.key, this.debtToEdit});

  @override
  State<ModernAddDebtScreen> createState() => _ModernAddDebtScreenState();
}

class _ModernAddDebtScreenState extends State<ModernAddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _interestRateController;
  late TextEditingController _emiController;
  late TextEditingController _lenderController;
  late TextEditingController _notesController;

  DebtType _selectedType = DebtType.creditCard;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.debtToEdit?.name ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.debtToEdit?.currentBalance.toString() ?? '',
    );
    _interestRateController = TextEditingController(
      text: widget.debtToEdit?.interestRate?.toString() ?? '',
    );
    _emiController = TextEditingController(
      text: widget.debtToEdit?.monthlyEMI?.toString() ?? '',
    );
    _lenderController = TextEditingController(
      text: widget.debtToEdit?.lenderName ?? '',
    );
    _notesController = TextEditingController(
      text: widget.debtToEdit?.notes ?? '',
    );

    if (widget.debtToEdit != null) {
      _selectedType = widget.debtToEdit!.type;
      _dueDate = widget.debtToEdit!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _interestRateController.dispose();
    _emiController.dispose();
    _lenderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final name = _nameController.text.trim();
      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
      final interestRate = double.tryParse(_interestRateController.text.trim());
      final emi = double.tryParse(_emiController.text.trim());
      final lender = _lenderController.text.trim();
      final notes = _notesController.text.trim();

      final debt = Debt(
        id: widget.debtToEdit?.id ?? '',
        userId: user.uid,
        name: name,
        type: _selectedType,
        originalAmount:
            widget.debtToEdit?.originalAmount ??
            balance, // Assuming original is same as current for new
        currentBalance: balance,
        interestRate: interestRate,
        monthlyEMI: emi,
        lenderName: lender.isNotEmpty ? lender : null,
        notes: notes.isNotEmpty ? notes : null,
        dueDate: _dueDate,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<DebtProvider>(context, listen: false);

      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
        if (mounted) showTopSnackBar(context, 'Debt updated successfully');
      } else {
        await provider.addDebt(debt);
        if (mounted) showTopSnackBar(context, 'Debt added successfully');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error saving debt: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.debtToEdit != null ? 'Edit Debt' : 'Add New Debt',
                style: AppTypography.headlineMedium,
              ),
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
                    _buildTypeSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInputField(
                      controller: _nameController,
                      label: 'Debt Name',
                      hint: 'e.g., Chase Sapphire, Home Loan',
                      icon: Icons.description_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _balanceController,
                      label: 'Current Balance',
                      hint: '0.00',
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _interestRateController,
                            label: 'Interest Rate (%)',
                            hint: '0.0',
                            icon: Icons.percent,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildInputField(
                            controller: _emiController,
                            label: 'Monthly Payment',
                            hint: '0.00',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _lenderController,
                      label: 'Lender / Bank',
                      hint: 'e.g., Chase, Wells Fargo',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDatePicker(),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _notesController,
                      label: 'Notes',
                      hint: 'Any additional details...',
                      icon: Icons.note_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDebt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.debtToEdit != null
                                    ? 'Update Debt'
                                    : 'Add Debt',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debt Type',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardDarkElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral700),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DebtType>(
              value: _selectedType,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              dropdownColor: AppColors.cardDarkElevated,
              items: DebtType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getDebtTypeIcon(type),
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getDebtTypeName(type),
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.cardDarkElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) setState(() => _dueDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDarkElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral700),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                      : 'Select Date',
                  style: AppTypography.bodyLarge.copyWith(
                    color: _dueDate != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDebtTypeName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.owedByMe:
        return 'Owed by Me';
      case DebtType.owedToMe:
        return 'Owed to Me';
      case DebtType.other:
        return 'Other';
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      case DebtType.businessLoan:
        return Icons.business;
      case DebtType.goldLoan:
        return Icons.monetization_on;
      case DebtType.owedByMe:
        return Icons.arrow_outward;
      case DebtType.owedToMe:
        return Icons.arrow_downward;
      case DebtType.other:
        return Icons.more_horiz;
    }
  }
}
