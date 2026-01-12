import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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

  // Controllers
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _lenderController = TextEditingController();
  final _emiController = TextEditingController();
  final _rateController = TextEditingController();

  // State
  DebtType _selectedType = DebtType.creditCard;
  DateTime? _startDate;
  DateTime? _endDate;
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
      _selectedType = d.type;
      _startDate = d.startDate;
      _endDate = d.dueDate; // Mapping dueDate to End Date visually
    }
  }

  // --- LOGIC ---
  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final balance = double.parse(_balanceController.text);
      final emi = double.tryParse(_emiController.text);
      final rate = double.tryParse(_rateController.text);

      final newDebt = Debt(
        id: widget.debtToEdit?.id ?? '',
        userId: user.uid,
        name: _nameController.text,
        type: _selectedType,
        originalAmount:
            widget.debtToEdit?.originalAmount ??
            balance, // Assume current is max if new
        currentBalance: balance,
        monthlyEMI: emi,
        interestRate: rate,
        lenderName: _lenderController.text.isNotEmpty
            ? _lenderController.text
            : null,
        startDate: _startDate,
        dueDate: _endDate,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<DebtProvider>(context, listen: false);
      if (widget.debtToEdit != null) {
        await provider.updateDebt(newDebt);
      } else {
        await provider.addDebt(newDebt);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: Text(
          widget.debtToEdit != null ? 'Edit Liability' : 'New Liability',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TYPE SELECTOR
              _buildLabel("TYPE"),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTypeChip(
                      "Credit Card",
                      DebtType.creditCard,
                      Icons.credit_card,
                    ),
                    _buildTypeChip(
                      "Personal Loan",
                      DebtType.personalLoan,
                      Icons.person,
                    ),
                    _buildTypeChip("Home Loan", DebtType.homeLoan, Icons.home),
                    _buildTypeChip(
                      "Car Loan",
                      DebtType.carLoan,
                      Icons.directions_car,
                    ),
                    _buildTypeChip("Other", DebtType.other, Icons.more_horiz),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. CORE DETAILS
              _buildLabel("DETAILS"),
              _buildGlassTextField(
                controller: _nameController,
                label: "Debt Name",
                hint: "e.g. HDFC Credit Card",
                icon: Icons.label_outline,
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: _balanceController,
                label: "Outstanding Amount (₹)",
                icon: Icons.currency_rupee,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: _lenderController,
                label: "Lender / Bank (Optional)",
                hint: "e.g. SBI",
                icon: Icons.account_balance,
              ),

              const SizedBox(height: 32),

              // 3. FINANCIALS
              _buildLabel("FINANCIALS (OPTIONAL)"),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassTextField(
                      controller: _emiController,
                      label: "Monthly EMI",
                      icon: Icons.calendar_month,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassTextField(
                      controller: _rateController,
                      label: "Interest Rate %",
                      icon: Icons.percent,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. DATES
              _buildLabel("TIMELINE"),
              Row(
                children: [
                  _buildDatePicker(
                    "Start Date",
                    _startDate,
                    (d) => setState(() => _startDate = d),
                  ),
                  const SizedBox(width: 12),
                  _buildDatePicker(
                    "End Date",
                    _endDate,
                    (d) => setState(() => _endDate = d),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.error.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Save Liability",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, DebtType type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.error : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.error
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30), // Pill Shape
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          labelStyle: TextStyle(color: AppColors.textTertiary),
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) && label.contains("Name") ||
                label.contains("Amount")
            ? "Required"
            : null,
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime) onSelect,
  ) {
    return Expanded(
      child: GestureDetector(
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
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date != null ? DateFormat('MMM yyyy').format(date) : label,
                  style: TextStyle(
                    color: date != null ? Colors.white : AppColors.textTertiary,
                    fontWeight: date != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
