import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_snackbar.dart';

/// Floating Modal for Add/Edit Loan - Following Subscription Design Pattern
class AddLoanModal extends StatefulWidget {
  final Debt? debtToEdit;

  const AddLoanModal({super.key, this.debtToEdit});

  @override
  State<AddLoanModal> createState() => _AddLoanModalState();
}

class _AddLoanModalState extends State<AddLoanModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _balanceController = TextEditingController();
  final _emiController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _lenderController = TextEditingController();

  // State
  DebtType _selectedType = DebtType.personalLoan;
  int _paymentDay = 5;
  bool _isLoading = false;
  bool _showEmiCalculator = false;

  // EMI Calculator results
  double? _calculatedEMI;
  double? _totalInterest;
  double? _totalPayment;

  bool get _isEditMode => widget.debtToEdit != null;

  // Quick Add Loan Types
  final List<Map<String, dynamic>> _loanQuickAdd = [
    {'type': DebtType.personalLoan, 'name': 'Personal', 'icon': '💳'},
    {'type': DebtType.homeLoan, 'name': 'Home', 'icon': '🏠'},
    {'type': DebtType.carLoan, 'name': 'Car', 'icon': '🚗'},
    {'type': DebtType.twoWheelerLoan, 'name': '2-Wheeler', 'icon': '🏍️'},
    {'type': DebtType.educationLoan, 'name': 'Education', 'icon': '🎓'},
    {'type': DebtType.goldLoan, 'name': 'Gold', 'icon': '💰'},
  ];

  @override
  void initState() {
    super.initState();

    // Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    if (_isEditMode) {
      _populateFromDebt(widget.debtToEdit!);
    }

    // Live Preview Listeners
    _nameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _balanceController.addListener(() => setState(() {}));
    _emiController.addListener(() => setState(() {}));
  }

  void _populateFromDebt(Debt debt) {
    _nameController.text = debt.name;
    _amountController.text = debt.originalAmount.toStringAsFixed(0);
    _balanceController.text = debt.currentBalance.toStringAsFixed(0);
    _emiController.text = debt.monthlyEMI?.toStringAsFixed(0) ?? '';
    _rateController.text = debt.interestRate?.toString() ?? '';
    _tenureController.text = debt.totalMonths?.toString() ?? '';
    _lenderController.text = debt.lenderName ?? '';
    _selectedType = debt.type;
    _paymentDay = debt.paymentDay ?? 5;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _balanceController.dispose();
    _emiController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _lenderController.dispose();
    super.dispose();
  }

  void _onQuickAdd(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedType = item['type'] as DebtType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Floating Card
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 750,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        _isEditMode ? "Edit Loan" : "New Loan",
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scrollable Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. LIVE PREVIEW
                                _buildLivePreview(),
                                const SizedBox(height: 32),

                                // 2. QUICK ADD
                                _buildLabel("LOAN TYPE"),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _loanQuickAdd.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final item = _loanQuickAdd[index];
                                      final isSelected =
                                          _selectedType == item['type'];
                                      return GestureDetector(
                                        onTap: () => _onQuickAdd(item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.info.withOpacity(
                                                    0.2,
                                                  )
                                                : AppColors.cardSurface,
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.info
                                                  : Colors.white.withOpacity(
                                                      0.05,
                                                    ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                item['icon'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item['name'],
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? AppColors.info
                                                      : AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 3. LOAN DETAILS
                                _buildLabel("LOAN DETAILS"),
                                _buildGlassTextField(
                                  controller: _nameController,
                                  hint: "e.g. HDFC Home Loan",
                                  icon: Icons.article_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildGlassTextField(
                                  controller: _lenderController,
                                  hint: "Bank / Lender Name",
                                  icon: Icons.account_balance,
                                ),
                                const SizedBox(height: 24),

                                // 4. AMOUNT SECTION
                                _buildLabel("AMOUNTS"),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _amountController,
                                        hint: "Principal",
                                        icon: Icons.currency_rupee,
                                        isNumber: true,
                                        prefix: "₹",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _balanceController,
                                        hint: "Balance",
                                        icon: Icons.account_balance_wallet,
                                        isNumber: true,
                                        prefix: "₹",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildGlassTextField(
                                  controller: _emiController,
                                  hint: "Monthly EMI",
                                  icon: Icons.calendar_today,
                                  isNumber: true,
                                  prefix: "₹",
                                ),
                                const SizedBox(height: 24),

                                // 5. INTEREST & TENURE
                                _buildLabel("TERMS"),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _rateController,
                                        hint: "Interest %",
                                        icon: Icons.percent,
                                        isNumber: true,
                                        suffix: "%",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _tenureController,
                                        hint: "Tenure",
                                        icon: Icons.timer_outlined,
                                        isNumber: true,
                                        suffix: "mo",
                                      ),
                                    ),
                                  ],
                                ),

                                // EMI Calculator Toggle
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(
                                      () => _showEmiCalculator =
                                          !_showEmiCalculator,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showEmiCalculator
                                          ? AppColors.info.withOpacity(0.15)
                                          : AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _showEmiCalculator
                                            ? AppColors.info.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calculate_outlined,
                                          size: 18,
                                          color: _showEmiCalculator
                                              ? AppColors.info
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _showEmiCalculator
                                              ? "Hide Calculator"
                                              : "Calculate EMI",
                                          style: TextStyle(
                                            color: _showEmiCalculator
                                                ? AppColors.info
                                                : AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // EMI Calculator Results
                                if (_showEmiCalculator) ...[
                                  const SizedBox(height: 16),
                                  _buildEmiCalculator(),
                                ],

                                const SizedBox(height: 24),

                                // 6. PAYMENT DAY
                                _buildLabel("EMI DUE DATE"),
                                GestureDetector(
                                  onTap: _showPaymentDayPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          color: AppColors.info,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Every month on",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${_paymentDay}${_getDaySuffix(_paymentDay)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // 7. SAVE BUTTON
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cardSurface,
                                      foregroundColor: AppColors.info,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: BorderSide(
                                          color: AppColors.info.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.info,
                                            ),
                                          )
                                        : Text(
                                            _isEditMode
                                                ? "Save Changes"
                                                : "Add Loan",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final name = _nameController.text.isEmpty
        ? "Loan Name"
        : _nameController.text;
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final emi = double.tryParse(_emiController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _selectedType.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (emi > 0)
                  Text(
                    "₹${NumberFormat('#,##,###').format(emi)}/month",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat('#,##,###').format(balance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "remaining",
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
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
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? prefix,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          prefixText: prefix,
          prefixStyle: TextStyle(
            color: AppColors.info,
            fontWeight: FontWeight.bold,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmiCalculator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculateEMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Calculate EMI",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_calculatedEMI != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildCalcRow(
                    'Monthly EMI',
                    '₹${NumberFormat('#,##,###').format(_calculatedEMI)}',
                  ),
                  const SizedBox(height: 8),
                  _buildCalcRow(
                    'Total Interest',
                    '₹${NumberFormat('#,##,###').format(_totalInterest)}',
                  ),
                  const SizedBox(height: 8),
                  _buildCalcRow(
                    'Total Payment',
                    '₹${NumberFormat('#,##,###').format(_totalPayment)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _emiController.text = _calculatedEMI!.round().toString();
                HapticFeedback.mediumImpact();
              },
              child: Text(
                "Use This EMI →",
                style: TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPaymentDayPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select EMI Due Date',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 28,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = day == _paymentDay;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _paymentDay = day);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.info
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _calculateEMI() {
    final principal = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;

    if (principal <= 0 || rate <= 0 || tenure <= 0) {
      showTopSnackBar(
        context,
        'Enter Principal, Rate & Tenure first',
        isError: true,
      );
      return;
    }

    // EMI Formula: [P x R x (1+R)^N] / [(1+R)^N – 1]
    final monthlyRate = rate / 12 / 100;
    final emi =
        (principal * monthlyRate * math.pow(1 + monthlyRate, tenure)) /
        (math.pow(1 + monthlyRate, tenure) - 1);

    setState(() {
      _calculatedEMI = emi;
      _totalPayment = emi * tenure;
      _totalInterest = _totalPayment! - principal;
    });

    HapticFeedback.mediumImpact();
  }

  DateTime _getNextPaymentDate() {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, _paymentDay);

    if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = DateTime(now.year, now.month + 1, _paymentDay);
    }

    return nextDate;
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _balanceController.text.isEmpty) {
      showTopSnackBar(context, 'Please fill required fields', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showTopSnackBar(context, 'Please sign in first', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<DebtProvider>();
      final now = DateTime.now();

      final originalAmount = double.tryParse(_amountController.text) ?? 0;
      final currentBalance = double.parse(_balanceController.text);
      final emi = double.tryParse(_emiController.text);
      final rate = double.tryParse(_rateController.text);
      final tenure = int.tryParse(_tenureController.text);

      int? paidMonths;
      if (emi != null && emi > 0) {
        final paid = originalAmount - currentBalance;
        paidMonths = (paid / emi).floor();
      }

      final debt = Debt(
        id: widget.debtToEdit?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        type: _selectedType,
        originalAmount: originalAmount > 0 ? originalAmount : currentBalance,
        currentBalance: currentBalance,
        monthlyEMI: emi,
        interestRate: rate,
        totalMonths: tenure,
        paidMonths: paidMonths,
        paymentDay: _paymentDay,
        nextPaymentDate: _getNextPaymentDate(),
        lenderName: _lenderController.text.trim().isNotEmpty
            ? _lenderController.text.trim()
            : null,
        startDate: widget.debtToEdit?.startDate ?? now,
        createdAt: widget.debtToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
        if (mounted) {
          showTopSnackBar(context, 'Loan updated successfully');
        }
      } else {
        await provider.addDebt(debt);
        if (mounted) {
          showTopSnackBar(context, 'Loan added successfully');
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Show the floating loan modal
Future<void> showAddLoanModal(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => AddLoanModal(debtToEdit: debtToEdit),
    ),
  );
}

// Keep backward compatibility alias
typedef AddLoanSheet = AddLoanModal;
