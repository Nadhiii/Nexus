import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../utils/debt_logo_utils.dart';

/// Floating Modal for Add/Edit Credit Card - Following Subscription Design Pattern
class AddCreditCardModal extends StatefulWidget {
  final Debt? debtToEdit;

  const AddCreditCardModal({super.key, this.debtToEdit});

  @override
  State<AddCreditCardModal> createState() => _AddCreditCardModalState();
}

class _AddCreditCardModalState extends State<AddCreditCardModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  final _minDueController = TextEditingController();
  final _bankController = TextEditingController();

  // State
  int _dueDay = 15;
  bool _isLoading = false;

  bool get _isEditMode => widget.debtToEdit != null;

  // Popular Card Quick Add
  final List<Map<String, dynamic>> _popularCards = [
    {'name': 'HDFC', 'color': const Color(0xFF004C8F)},
    {'name': 'ICICI', 'color': const Color(0xFFB02A30)},
    {'name': 'SBI', 'color': const Color(0xFF22409A)},
    {'name': 'Axis', 'color': const Color(0xFF800020)},
    {'name': 'Kotak', 'color': const Color(0xFFED1C24)},
    {'name': 'Amex', 'color': const Color(0xFF006FCF)},
  ];

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _populateFromDebt(widget.debtToEdit!);
    }

    // Live Preview Listeners
    _nameController.addListener(() => setState(() {}));
    _balanceController.addListener(() => setState(() {}));
    _limitController.addListener(() => setState(() {}));
    _bankController.addListener(() => setState(() {}));
  }

  void _populateFromDebt(Debt debt) {
    _nameController.text = debt.name;
    _balanceController.text = debt.currentBalance.toStringAsFixed(0);
    _limitController.text = debt.originalAmount.toStringAsFixed(0);
    _minDueController.text = debt.monthlyEMI?.toStringAsFixed(0) ?? '';
    _bankController.text = debt.lenderName ?? '';
    _dueDay = debt.paymentDay ?? 15;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _minDueController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _onQuickAdd(Map<String, dynamic> card) {
    HapticFeedback.selectionClick();
    setState(() {
      _bankController.text = card['name'];
      if (_nameController.text.isEmpty) {
        _nameController.text = "${card['name']} Card";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text(
                _isEditMode ? 'Edit Credit Card' : 'Add Credit Card',
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
                                // 1. LIVE PREVIEW
                                _buildLivePreview(),
                                const SizedBox(height: 32),

                                // 2. QUICK ADD
                                _buildLabel('Quick Add'),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _popularCards.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final card = _popularCards[index];
                                      final isSelected =
                                          _bankController.text == card['name'];
                                      return GestureDetector(
                                        onTap: () => _onQuickAdd(card),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: (card['color'] as Color)
                                                .withValues(
                                                  alpha: isSelected ? 0.4 : 0.2,
                                                ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? card['color']
                                                  : (card['color'] as Color)
                                                        .withValues(alpha: 0.5),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              card['name'][0],
                                              style: TextStyle(
                                                color: card['color'],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 3. CARD DETAILS
                                _buildLabel('Card Details'),
                                _buildGlassTextField(
                                  controller: _nameController,
                                  hint: "e.g. HDFC Regalia",
                                  icon: Icons.credit_card,
                                ),
                                const SizedBox(height: 12),
                                _buildGlassTextField(
                                  controller: _bankController,
                                  hint: "Bank Name",
                                  icon: Icons.account_balance,
                                ),
                                const SizedBox(height: 24),

                                // 4. AMOUNTS
                                _buildLabel('Amounts'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _limitController,
                                        hint: "Credit Limit",
                                        icon: Icons.trending_up,
                                        isNumber: true,
                                        prefix: "₹",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGlassTextField(
                                        controller: _balanceController,
                                        hint: "Outstanding",
                                        icon: Icons.account_balance_wallet,
                                        isNumber: true,
                                        prefix: "₹",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildGlassTextField(
                                  controller: _minDueController,
                                  hint: "Minimum Due (optional)",
                                  icon: Icons.receipt_outlined,
                                  isNumber: true,
                                  prefix: "₹",
                                ),
                                const SizedBox(height: 24),

                                // 5. UTILIZATION PREVIEW
                                _buildUtilizationCard(),
                                const SizedBox(height: 24),

                                // 6. DUE DATE
                                _buildLabel('Bill Due Date'),
                                GestureDetector(
                                  onTap: _showDueDayPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          color: AppColors.warning,
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
                                          "$_dueDay${_getDaySuffix(_dueDay)}",
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
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.white,
                                            ),
                                          )
                                        : Text(
                                            _isEditMode
                                                ? "Save Changes"
                                                : "Add Card",
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 16,
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

  Widget _buildLivePreview() {
    final name = _nameController.text.isEmpty
        ? "Card Name"
        : _nameController.text;
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final limit = double.tryParse(_limitController.text) ?? 0;
    final utilization = limit > 0 ? (balance / limit * 100) : 0.0;
    final bankLogo = DebtLogoUtils.bankLogoForParts(
      lenderName: _bankController.text,
      name: _nameController.text,
    );
    final bankLogoScale = DebtLogoUtils.bankLogoScaleForParts(
      lenderName: _bankController.text,
      name: _nameController.text,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            AppColors.cardSurface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: bankLogo != null
                      ? LogoUtils.buildLogo(bankLogo, size: 24 * bankLogoScale)
                      : Icon(
                          Icons.credit_card,
                          color: AppColors.warning,
                          size: 24,
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
                    if (_bankController.text.isNotEmpty)
                      Text(
                        _bankController.text,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
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
                    "outstanding",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (limit > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (utilization / 100).clamp(0, 1),
                backgroundColor: AppColors.cardDark,
                valueColor: AlwaysStoppedAnimation(
                  utilization <= 30
                      ? AppColors.success
                      : utilization <= 50
                      ? AppColors.warning
                      : AppColors.error,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${utilization.toStringAsFixed(0)}% used",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  "Limit: ₹${NumberFormat('#,##,###').format(limit)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
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
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        prefixText: prefix,
        prefixStyle: TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUtilizationCard() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final limit = double.tryParse(_limitController.text) ?? 0;
    final utilization = limit > 0 ? (balance / limit * 100) : 0.0;

    Color getUtilizationColor() {
      if (utilization <= 30) {
        return AppColors.success;
      }
      if (utilization <= 50) {
        return AppColors.warning;
      }
      return AppColors.error;
    }

    String getUtilizationMessage() {
      if (utilization <= 30) {
        return "✓ Great! Keep utilization under 30% for best credit score";
      } else if (utilization <= 50) {
        return "⚠ Consider paying down to under 30%";
      } else {
        return "⚠ High utilization may impact credit score";
      }
    }

    if (limit <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getUtilizationColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getUtilizationColor().withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: getUtilizationColor(),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Credit Utilization",
                style: TextStyle(
                  color: getUtilizationColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                "${utilization.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: getUtilizationColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            getUtilizationMessage(),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showDueDayPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Due Date',
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
                    final isSelected = day == _dueDay;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _dueDay = day);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.warning
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
    if (day >= 11 && day <= 13) {
      return 'th';
    }
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

  DateTime _getNextDueDate() {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, _dueDay);

    if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
      nextDate = DateTime(now.year, now.month + 1, _dueDay);
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

      final balance = double.parse(_balanceController.text);
      final limit = double.tryParse(_limitController.text) ?? balance;
      final minDue = double.tryParse(_minDueController.text);

      final debt = Debt(
        id: widget.debtToEdit?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        type: DebtType.creditCard,
        originalAmount: limit,
        currentBalance: balance,
        monthlyEMI: minDue,
        paymentDay: _dueDay,
        nextPaymentDate: _getNextDueDate(),
        lenderName: _bankController.text.trim().isNotEmpty
            ? _bankController.text.trim()
            : null,
        startDate: widget.debtToEdit?.startDate ?? now,
        createdAt: widget.debtToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.debtToEdit != null) {
        await provider.updateDebt(debt);
        if (mounted) {
          showTopSnackBar(context, 'Credit card updated');
        }
      } else {
        await provider.addDebt(debt);
        if (mounted) {
          showTopSnackBar(context, 'Credit card added');
        }
      }

      if (mounted) {
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

/// Show the floating credit card modal
Future<void> showAddCreditCardModal(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AddCreditCardModal(debtToEdit: debtToEdit)),
  );
}

// Keep backward compatibility alias
typedef AddCreditCardSheet = AddCreditCardModal;
