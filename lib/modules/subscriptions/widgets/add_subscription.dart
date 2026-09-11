import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/subscription.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscriptionToEdit;

  const ModernAddSubscriptionScreen({super.key, this.subscriptionToEdit});

  static Future<void> show(
    BuildContext context, {
    Subscription? subscriptionToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) =>
          ModernAddSubscriptionScreen(subscriptionToEdit: subscriptionToEdit),
    );
  }

  @override
  State<ModernAddSubscriptionScreen> createState() =>
      _ModernAddSubscriptionScreenState();
}

class _ModernAddSubscriptionScreenState
    extends State<ModernAddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedFrequency = 'monthly';
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  Color _brandColor = AppColors.pastelOrange;
  bool _isLoading = false;

  bool get _isEditMode => widget.subscriptionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.subscriptionToEdit!;
      _nameController.text = s.name;
      _amountController.text = s.amount.toStringAsFixed(0);
      _selectedFrequency = s.frequency;
      _nextDueDate = s.nextDueDate;
      try {
        _brandColor = Color(int.parse(s.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final colorString =
          '#${_brandColor.toARGB32().toRadixString(16).substring(2)}';

      final sub = Subscription(
        id: widget.subscriptionToEdit?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        frequency: _selectedFrequency,
        nextDueDate: _nextDueDate,
        categoryId: 'general',
        accountId: 'default',
        color: colorString,
        isActive: true,
        createdAt: DateTime.now(),
      );

      if (widget.subscriptionToEdit != null) {
        await context.read<SubscriptionProvider>().updateSubscription(sub);
      } else {
        await context.read<SubscriptionProvider>().addSubscription(sub);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Subscription saved');
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
    final isEditing = widget.subscriptionToEdit != null;

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
                      isEditing ? 'Edit Subscription' : 'New Subscription',
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

                _buildLabel('SUBSCRIPTION COST'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.currencyMedium.copyWith(
                    color: _brandColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: _brandColor,
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
                      borderSide: BorderSide(color: _brandColor, width: 1.5),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Amount is required"
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('SERVICE NAME'),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g. Netflix, Spotify, Claude Pro",
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.sm,
                      ),
                      child: Icon(
                        Icons.subscriptions_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
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
                      borderSide: BorderSide(color: _brandColor, width: 1.5),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('BILLING CYCLE'),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: AppSpacing.borderRadiusSm,
                              border: Border.all(
                                color: AppColors.borderSubtleDark,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFrequency,
                                isExpanded: true,
                                dropdownColor: AppColors.darkSurfaceElevated,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('Monthly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'yearly',
                                    child: Text('Yearly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'weekly',
                                    child: Text('Weekly'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedFrequency = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('NEXT DUE DATE'),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _nextDueDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 5),
                                ),
                              );
                              if (picked != null)
                                setState(() => _nextDueDate = picked);
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceElevated,
                                borderRadius: AppSpacing.borderRadiusSm,
                                border: Border.all(
                                  color: AppColors.borderSubtleDark,
                                ),
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
                                      DateFormat(
                                        'dd MMM yy',
                                      ).format(_nextDueDate),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                        onPressed: _isLoading ? null : _submit,
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
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Add Subscription',
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
}

Future<void> showAddSubscription(
  BuildContext context, {
  Subscription? subscriptionToEdit,
}) {
  return ModernAddSubscriptionScreen.show(
    context,
    subscriptionToEdit: subscriptionToEdit,
  );
}

Future<void> showAddSubscriptionModal(
  BuildContext context, {
  Subscription? subscriptionToEdit,
}) => showAddSubscription(context, subscriptionToEdit: subscriptionToEdit);
