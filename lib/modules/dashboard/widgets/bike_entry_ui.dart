import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/bike.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddEntryScreen extends StatefulWidget {
  final Bike bike;
  final double? initialRate;

  const ModernAddEntryScreen({super.key, required this.bike, this.initialRate});

  @override
  State<ModernAddEntryScreen> createState() => _ModernAddEntryScreenState();
}

class _ModernAddEntryScreenState extends State<ModernAddEntryScreen> {
  bool _isFuelMode = true;
  bool _isInputtingTrip = true;
  bool _isFullTank = true;
  bool _linkToExpense = true;
  Account? _selectedAccount;

  final _mainInputController = TextEditingController();
  final _costController = TextEditingController();
  final _volumeController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final String _selectedCategory = 'maintenance';

  double _lastOdo = 0.0;
  double _calculatedOdo = 0.0;
  double _calculatedTrip = 0.0;

  @override
  void initState() {
    super.initState();
    _lastOdo = widget.bike.currentOdometer;
    _calculatedOdo = _lastOdo;
    if (widget.initialRate != null && widget.initialRate! > 0) {
      _rateController.text = widget.initialRate!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _mainInputController.dispose();
    _costController.dispose();
    _volumeController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _onMainInputChanged(String val) {
    double input = double.tryParse(val) ?? 0.0;
    setState(() {
      if (_isInputtingTrip) {
        _calculatedTrip = input;
        _calculatedOdo = _lastOdo + input;
      } else {
        _calculatedOdo = input;
        _calculatedTrip = (input - _lastOdo).clamp(0, double.infinity);
      }
    });
  }

  void _toggleInputMode() {
    setState(() {
      _isInputtingTrip = !_isInputtingTrip;
      _mainInputController.clear();
      _calculatedTrip = 0;
      _calculatedOdo = _lastOdo;
    });
  }

  void _onFuelMathChanged() {
    double vol = double.tryParse(_volumeController.text) ?? 0;
    double rate = double.tryParse(_rateController.text) ?? 0;
    if (vol > 0 && rate > 0) {
      _costController.text = (vol * rate).toStringAsFixed(0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  double? _calculateExactMileage(
    List<BikeEntry> history,
    double currentOdo,
    double currentFuel,
  ) {
    if (!_isFullTank) return null;
    final sortedHistory = List<BikeEntry>.from(history)
      ..sort((a, b) => b.odometerReading.compareTo(a.odometerReading));

    BikeEntry? lastFullTankEntry;
    double fuelConsumedBetween = 0.0;

    for (var entry in sortedHistory) {
      if ((entry.category ?? 'fuel') != 'fuel') continue;
      if (entry.isFullTank) {
        lastFullTankEntry = entry;
        break;
      } else {
        fuelConsumedBetween += entry.fuelQuantity;
      }
    }

    if (lastFullTankEntry == null) return null;

    double distance = currentOdo - lastFullTankEntry.odometerReading;
    double totalFuelUsed = currentFuel + fuelConsumedBetween;
    if (totalFuelUsed <= 0) return 0.0;
    return distance / totalFuelUsed;
  }

  void _save() async {
    final provider = context.read<BikeProvider>();

    if (_costController.text.isEmpty || _mainInputController.text.isEmpty) {
      showTopSnackBar(
        context,
        "Please fill cost and distance fields",
        isError: true,
      );
      return;
    }

    final costParsed = double.tryParse(_costController.text);
    if (costParsed == null || costParsed <= 0) {
      showTopSnackBar(
        context,
        "Please enter a valid cost amount",
        isError: true,
      );
      return;
    }

    final mainInputParsed = double.tryParse(_mainInputController.text);
    if (mainInputParsed == null || mainInputParsed < 0) {
      showTopSnackBar(context, "Please enter a valid distance", isError: true);
      return;
    }

    if (_linkToExpense && _selectedAccount == null) {
      showTopSnackBar(
        context,
        "Please select an account to debit",
        isError: true,
      );
      return;
    }

    String finalCategory = 'fuel';
    if (!_isFuelMode) {
      finalCategory =
          _selectedCategory == 'other' &&
              _customCategoryController.text.isNotEmpty
          ? _customCategoryController.text.trim()
          : _selectedCategory;
    }

    double currentFuelQty = double.tryParse(_volumeController.text) ?? 0;
    double? calculatedMileage;
    if (_isFuelMode && _isFullTank) {
      calculatedMileage = _calculateExactMileage(
        provider.currentBikeEntries,
        _calculatedOdo,
        currentFuelQty,
      );
    }

    final entry = BikeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: provider.auth.currentUser?.uid ?? '',
      bikeName: widget.bike.name,
      date: _selectedDate,
      odometerReading: _calculatedOdo,
      fuelQuantity: _isFuelMode ? currentFuelQty : 0,
      fuelAmount: costParsed,
      category: finalCategory,
      notes: _notesController.text.trim(),
      isFullTank: _isFullTank,
      mileage: calculatedMileage,
    );

    try {
      provider.addBikeEntry(entry);

      if (entry.isFullTank && entry.mileage != null && entry.mileage! > 0) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.notifyFuelLogged(
          vehicleName: widget.bike.name,
          mileage: entry.mileage!,
          fuelAmount: entry.fuelQuantity,
          cost: entry.fuelAmount,
        );
      }

      if (_calculatedOdo > widget.bike.currentOdometer) {
        final updatedBike = widget.bike.copyWith(
          currentOdometer: _calculatedOdo,
        );
        provider.updateBike(updatedBike);
      }

      if (_linkToExpense && _selectedAccount != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final txnProvider = context.read<TransactionProvider>();
          final transaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: user.uid,
            type: TransactionType.expense,
            amount: costParsed,
            description: _isFuelMode
                ? '${widget.bike.name} - Fuel (${currentFuelQty.toStringAsFixed(1)}L)'
                : '${widget.bike.name} - $finalCategory',
            categoryId: 'transportation',
            accountId: _selectedAccount!.id,
            date: _selectedDate,
            metadata: {
              'source': 'garage',
              'bikeName': widget.bike.name,
              'entryId': entry.id,
              'category': finalCategory,
              if (_isFuelMode) 'fuelQuantity': currentFuelQty,
              'odometer': _calculatedOdo,
            },
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txnProvider.addTransaction(transaction);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          context,
          _linkToExpense
              ? "Entry added & expense recorded"
              : "Entry added successfully",
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Error adding entry: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isFuelMode
        ? AppColors.primaryBlue
        : AppColors.pastelOrange;

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
                _isFuelMode ? 'Log Fuel' : 'Log Service',
                style: AppTypography.headlineMedium,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkElevated,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildModeBtn(Icons.local_gas_station, true),
                    _buildModeBtn(Icons.build_circle, false),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isInputtingTrip ? "Trip Distance" : "New Odometer",
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleInputMode,
                        icon: const Icon(
                          Icons.swap_vert_circle,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _mainInputController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: _onMainInputChanged,
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: ' km',
                      suffixStyle: AppTypography.displayMedium.copyWith(
                        color: activeColor,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                    ),
                    child: Text(
                      _isInputtingTrip
                          ? "Calculated Odo: ${_calculatedOdo.toStringAsFixed(0)} km (Prev: ${_lastOdo.toStringAsFixed(0)})"
                          : "Calculated Trip: ${_calculatedTrip.toStringAsFixed(1)} km",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  if (_isFuelMode) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fill Status',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Full Tank",
                              style: TextStyle(
                                color: _isFullTank
                                    ? Colors.white
                                    : AppColors.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _isFullTank,
                              activeThumbColor: activeColor,
                              onChanged: (val) =>
                                  setState(() => _isFullTank = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_isFullTank)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          "Mileage cannot be calculated from a partial fill.",
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStandardField(
                            controller: _volumeController,
                            hint: "Litres",
                            icon: Icons.water_drop_outlined,
                            isNumber: true,
                            onChanged: (_) => _onFuelMathChanged(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStandardField(
                            controller: _rateController,
                            hint: "Price/L",
                            icon: Icons.currency_rupee,
                            isNumber: true,
                            onChanged: (_) => _onFuelMathChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  Text(
                    'Total Cost',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStandardField(
                    controller: _costController,
                    hint: "Total Amount (₹)",
                    icon: Icons.account_balance_wallet_outlined,
                    isNumber: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardDarkElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStandardField(
                          controller: _notesController,
                          hint: "Notes (Optional)",
                          icon: Icons.edit_note,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  _buildExpenseLinkingSection(),
                  const SizedBox(height: AppSpacing.xl2),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
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
                      child: Text(
                        _linkToExpense ? 'Save & Record Expense' : 'Save Entry',
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
        ],
      ),
    );
  }

  Widget _buildModeBtn(IconData icon, bool isFuel) {
    final isSelected = _isFuelMode == isFuel;
    return GestureDetector(
      onTap: () => setState(() => _isFuelMode = isFuel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? (_isFuelMode ? AppColors.primaryBlue : AppColors.pastelOrange)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStandardField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
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
    );
  }

  Widget _buildExpenseLinkingSection() {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _linkToExpense
              ? AppColors.success.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                color: _linkToExpense
                    ? AppColors.success
                    : AppColors.textTertiary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link to Expenses",
                      style: AppTypography.titleSmall.copyWith(
                        color: _linkToExpense
                            ? Colors.white
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Auto-create a transaction",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _linkToExpense,
                activeThumbColor: AppColors.success,
                onChanged: (val) => setState(() {
                  _linkToExpense = val;
                  if (!val) _selectedAccount = null;
                }),
              ),
            ],
          ),
          if (_linkToExpense) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundBlack,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _selectedAccount != null
                      ? AppColors.success.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Account>(
                  value: _selectedAccount,
                  isExpanded: true,
                  dropdownColor: AppColors.cardDarkElevated,
                  hint: Text(
                    "Select Account to Debit",
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textTertiary,
                  ),
                  items: accounts.map((account) {
                    final bankLogo = LogoUtils.bankLogoFor(
                      account.bankName ?? account.name,
                    );
                    return DropdownMenuItem<Account>(
                      value: account,
                      child: Row(
                        children: [
                          bankLogo != null
                              ? LogoUtils.buildLogo(bankLogo, size: 20)
                              : const Icon(
                                  Icons.account_balance_wallet,
                                  size: 20,
                                  color: AppColors.primaryBlue,
                                ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            "${account.name} (₹${account.balance.toStringAsFixed(0)})",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (account) =>
                      setState(() => _selectedAccount = account),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> navToAddEntryScreen(
  BuildContext context, {
  required Bike bike,
  double? initialRate,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ModernAddEntryScreen(bike: bike, initialRate: initialRate),
    ),
  );
}
