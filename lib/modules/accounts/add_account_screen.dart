import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../../core/models/account.dart';
import '../../core/providers/account_provider.dart';
import '../../core/widgets/top_snackbar.dart';

class ModernAddAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const ModernAddAccountScreen({super.key, this.accountToEdit});

  /// Opens this form as a native, bottom-up modal sheet
  static Future<void> show(BuildContext context, {Account? accountToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ModernAddAccountScreen(accountToEdit: accountToEdit),
    );
  }

  @override
  State<ModernAddAccountScreen> createState() => _ModernAddAccountScreenState();
}

class _ModernAddAccountScreenState extends State<ModernAddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _last4Controller = TextEditingController();

  AccountType _selectedType = AccountType.savings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      final a = widget.accountToEdit!;
      _nameController.text = a.name;
      _balanceController.text = a.balance.toStringAsFixed(0);
      _bankNameController.text = a.bankName ?? '';
      _last4Controller.text = a.accountNumber ?? '';
      _selectedType = a.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankNameController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  IconData _iconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings_outlined;
      case AccountType.salary:
        return Icons.account_balance_wallet_outlined;
      case AccountType.checking:
        return Icons.account_balance_outlined;
      case AccountType.investment:
        return Icons.trending_up_outlined;
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.other:
        return Icons.category_outlined;
    }
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final now = DateTime.now();

      final account = Account(
        id: widget.accountToEdit?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: balance,
        bankName: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        accountNumber: _last4Controller.text.trim().isNotEmpty
            ? _last4Controller.text.trim()
            : null,
        color: AppColors.primaryBlue,
        iconCodePoint: _iconForAccountType(_selectedType).codePoint,
        iconFontFamily: 'MaterialIcons',
        createdAt: widget.accountToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<AccountProvider>();
      if (widget.accountToEdit != null) {
        await provider.updateAccount(account);
      } else {
        await provider.addAccount(account);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          context,
          widget.accountToEdit != null
              ? "Account Updated"
              : "Account Created Successfully",
        );
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, "Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.accountToEdit != null;

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
                // Pull handle
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Account' : 'New Account',
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

                // Balance
                _buildFieldLabel('INITIAL BALANCE'),
                _buildBalanceInputField(),
                const SizedBox(height: AppSpacing.lg),

                // Account Type Grid
                _buildFieldLabel('ACCOUNT TYPE'),
                _buildAccountTypeGrid(),
                const SizedBox(height: AppSpacing.lg),

                // Account Name
                _buildFieldLabel('ACCOUNT NAME'),
                _buildStandardField(
                  controller: _nameController,
                  hint: "e.g. HDFC Salary, Emergency Fund",
                  icon: Icons.label_outline,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Name is required"
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Institution & Last 4 Digits
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('INSTITUTION (OPTIONAL)'),
                          _buildStandardField(
                            controller: _bankNameController,
                            hint: "e.g. SBI, Zerodha",
                            icon: Icons.account_balance_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('LAST 4 DIGITS'),
                          _buildStandardField(
                            controller: _last4Controller,
                            hint: "####",
                            icon: Icons.pin_outlined,
                            isNumber: true,
                            maxLength: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl2),

                // Actions
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
                        onPressed: _isLoading ? null : _saveAccount,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.primaryBlue,
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
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Create Account',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.white,
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

  Widget _buildFieldLabel(String text) {
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

  Widget _buildBalanceInputField() {
    return TextFormField(
      controller: _balanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTypography.currencyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: "0.00",
        hintStyle: AppTypography.currencyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        prefixText: "₹ ",
        prefixStyle: AppTypography.currencyMedium.copyWith(
          color: AppColors.primaryBlue,
        ),
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
      validator: (val) {
        if (val == null || val.trim().isEmpty)
          return "Initial balance required";
        if (double.tryParse(val.trim()) == null) return "Enter a valid number";
        return null;
      },
    );
  }

  Widget _buildStandardField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: "",
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

  Widget _buildAccountTypeGrid() {
    final types = AccountType.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selectedType == type;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedType = type);
          },
          child: AnimatedContainer(
            duration: AppAnimations.standard,
            curve: AppAnimations.standardCurve,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.15)
                  : AppColors.darkSurfaceElevated,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.borderSubtleDark,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconForAccountType(type),
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  type.name[0].toUpperCase() + type.name.substring(1),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Global Navigation Helper
Future<void> navToAddAccountScreen(
  BuildContext context, {
  Account? accountToEdit,
}) {
  return ModernAddAccountScreen.show(context, accountToEdit: accountToEdit);
}
