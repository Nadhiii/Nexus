import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/bike.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_draft.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/widgets/nexus_switch.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddEntryDialog extends StatefulWidget {
  final Bike bike;
  final double? initialRate;

  const AddEntryDialog({super.key, required this.bike, this.initialRate});

  static Future<void> show(
    BuildContext context, {
    required Bike bike,
    double? initialRate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AddEntryDialog(bike: bike, initialRate: initialRate),
    );
  }

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isFuelMode = true;
  bool _isFullTank = true;
  bool _linkToExpense = true;
  Account? _selectedAccount;

  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _volumeController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  final DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'maintenance';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _odometerController.text = widget.bike.currentOdometer.toStringAsFixed(0);
    if (widget.initialRate != null && widget.initialRate! > 0) {
      _rateController.text = widget.initialRate!.toStringAsFixed(2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        setState(() => _selectedAccount = accounts.first);
      }
    });
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _volumeController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFuelMathChanged() {
    final vol = double.tryParse(_volumeController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    if (vol > 0 && rate > 0) {
      _costController.text = (vol * rate).toStringAsFixed(0);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final provider = context.read<BikeProvider>();
      final costParsed = double.parse(_costController.text.trim());
      final odoParsed = double.parse(_odometerController.text.trim());
      final currentFuelQty =
          double.tryParse(_volumeController.text.trim()) ?? 0.0;
      final category = _isFuelMode ? 'fuel' : _selectedCategory;

      final entry = BikeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: provider.auth.currentUser?.uid ?? '',
        bikeName: widget.bike.name,
        date: _selectedDate,
        odometerReading: odoParsed,
        fuelQuantity: _isFuelMode ? currentFuelQty : 0,
        fuelAmount: costParsed,
        category: category,
        notes: _notesController.text.trim(),
        isFullTank: _isFullTank,
      );

      await provider.addBikeEntry(entry);

      if (odoParsed > widget.bike.currentOdometer) {
        await provider.updateBike(
          widget.bike.copyWith(currentOdometer: odoParsed),
        );
      }

      if (_linkToExpense && _selectedAccount != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final transaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: user.uid,
            type: TransactionType.expense,
            amount: costParsed,
            description: _isFuelMode
                ? '${widget.bike.name} - Fuel (${currentFuelQty.toStringAsFixed(1)}L)'
                : '${widget.bike.name} - $category',
            categoryId: 'transportation',
            accountId: _selectedAccount!.id,
            date: _selectedDate,
            metadata: {
              'source': 'garage',
              'bikeName': widget.bike.name,
              'odometer': odoParsed,
            },
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await context.read<TransactionProvider>().commitDraft(
            TransactionDraft.fromTransaction(transaction),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Entry added successfully');
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
    final activeColor = _isFuelMode ? AppColors.primaryBlue : AppColors.warning;

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
                      _isFuelMode ? 'Add Fuel' : 'Add Vehicle Expense',
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

                // Mode Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        "Fuel Log",
                        Icons.local_gas_station_outlined,
                        true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildModeButton(
                        "Expense / Service",
                        Icons.build_outlined,
                        false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('TOTAL COST'),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Cost is required";
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return "Enter a valid cost";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('ODOMETER READING (KM)'),
                _buildField(
                  controller: _odometerController,
                  hint: "e.g. 12450",
                  icon: Icons.speed_outlined,
                  isNumber: true,
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_isFuelMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('VOLUME (LITERS)'),
                            _buildField(
                              controller: _volumeController,
                              hint: "0.00",
                              icon: Icons.water_drop_outlined,
                              isNumber: true,
                              onChanged: (_) => _onFuelMathChanged(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('RATE / L'),
                            _buildField(
                              controller: _rateController,
                              hint: "₹ / L",
                              icon: Icons.price_change_outlined,
                              isNumber: true,
                              onChanged: (_) => _onFuelMathChanged(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Full Tank Fill-up",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      NexusSwitch(
                        value: _isFullTank,
                        activeThumbColor: activeColor,
                        onChanged: (v) => setState(() => _isFullTank = v),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildLabel('SERVICE CATEGORY'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.borderSubtleDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.darkSurfaceElevated,
                        items:
                            [
                                  'maintenance',
                                  'repair',
                                  'insurance',
                                  'fine',
                                  'accessories',
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c[0].toUpperCase() + c.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(
                          () => _selectedCategory = val ?? 'maintenance',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Link to Expenses
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: AppColors.borderSubtleDark),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.link,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                "Record as Expense",
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          NexusSwitch(
                            value: _linkToExpense,
                            activeThumbColor: AppColors.success,
                            onChanged: (val) =>
                                setState(() => _linkToExpense = val),
                          ),
                        ],
                      ),
                      if (_linkToExpense) ...[
                        const SizedBox(height: AppSpacing.md),
                        Consumer<AccountProvider>(
                          builder: (context, accProvider, _) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                value: _selectedAccount,
                                isExpanded: true,
                                dropdownColor: AppColors.darkSurfaceElevated,
                                hint: const Text("Select Account to Debit"),
                                items: accProvider.accounts
                                    .map(
                                      (acc) => DropdownMenuItem(
                                        value: acc,
                                        child: Text(acc.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (acc) =>
                                    setState(() => _selectedAccount = acc),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
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
                        onPressed: _isLoading ? null : _save,
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
                                'Log Entry',
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

  Widget _buildModeButton(String label, IconData icon, bool isFuel) {
    final isSelected = _isFuelMode == isFuel;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isFuelMode = isFuel);
      },
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? (isFuel
                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15))
              : AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected
                ? (isFuel ? AppColors.primaryBlue : AppColors.warning)
                : AppColors.borderSubtleDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isFuel ? AppColors.primaryBlue : AppColors.warning)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? (isFuel ? AppColors.primaryBlue : AppColors.warning)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
