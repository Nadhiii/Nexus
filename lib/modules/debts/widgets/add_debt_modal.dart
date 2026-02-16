import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddDebtModal extends StatefulWidget {
  final Debt? debtToEdit;

  const AddDebtModal({super.key, this.debtToEdit});

  @override
  State<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<AddDebtModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.fadeOutCurve),
    );
    _controller.forward();

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
    _controller.dispose();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 800,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  // SHADOW REMOVED HERE
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.debtToEdit != null
                          ? "EDIT LIABILITY"
                          : "NEW LIABILITY",
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Debt Type List
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
                    const SizedBox(height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("DETAILS"),
                              _buildGlassField(
                                controller: _nameController,
                                hint: "Debt Name (e.g. HDFC Card)",
                                icon: Icons.description_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _lenderController,
                                hint: "Lender / Bank Name",
                                icon: Icons.account_balance_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassField(
                                controller: _balanceController,
                                hint: "Current Balance",
                                icon: Icons.currency_rupee,
                                isNumber: true,
                              ),

                              const SizedBox(height: 24),
                              _buildLabel("TERMS (OPTIONAL)"),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _emiController,
                                      hint: "Monthly EMI",
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _rateController,
                                      hint: "Interest %",
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              _buildLabel("TIMELINE"),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDatePicker(
                                      "Start Date",
                                      _startDate,
                                      (d) => setState(() => _startDate = d),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDatePicker(
                                      "End Date",
                                      _dueDate,
                                      (d) => setState(() => _dueDate = d),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveDebt,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
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
                                          "SAVE LIABILITY",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "CANCEL",
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
        duration: AppAnimations.standard,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.error : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.error : Colors.white.withOpacity(0.1),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textSecondary, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) && hint.contains("Name")
            ? "Required"
            : null,
      ),
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
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM yyyy').format(date) : hint,
                style: TextStyle(
                  color: date != null
                      ? Colors.white
                      : AppColors.textTertiary.withOpacity(0.5),
                  fontWeight: date != null
                      ? FontWeight.bold
                      : FontWeight.normal,
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

Future<void> showAddDebtModal(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => AddDebtModal(debtToEdit: debtToEdit),
    ),
  );
}
