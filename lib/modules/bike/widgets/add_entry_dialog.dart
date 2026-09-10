// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/models/bike.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_draft.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nexus_switch.dart';
import '../../../core/utils/logo_utils.dart';

// Note: Keeping the name AddEntryDialog so your imports don't break,
// but this is now a full screen Scaffold!
class AddEntryDialog extends StatefulWidget {
  final Bike bike;
  final double? initialRate;

  const AddEntryDialog({super.key, required this.bike, this.initialRate});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
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
  String _selectedCategory = 'maintenance';

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

    _mainInputController.addListener(() => setState(() {}));
    _costController.addListener(() => setState(() {}));
    _volumeController.addListener(() => setState(() {}));
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.backgroundBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  double? _calculateExactMileage(
    List<BikeEntry> history,
    double currentOdo,
    double currentFuel,
  ) {
    if (!_isFullTank) {
      return null;
    }

    final sortedHistory = List<BikeEntry>.from(history)
      ..sort((a, b) => b.odometerReading.compareTo(a.odometerReading));
    BikeEntry? lastFullTankEntry;
    double fuelConsumedBetween = 0.0;

    for (var entry in sortedHistory) {
      if ((entry.category ?? 'fuel') != 'fuel') {
        continue;
      }
      if (entry.isFullTank) {
        lastFullTankEntry = entry;
        break;
      } else {
        fuelConsumedBetween += entry.fuelQuantity;
      }
    }

    if (lastFullTankEntry == null) {
      return null;
    }
    double distance = currentOdo - lastFullTankEntry.odometerReading;
    double totalFuelUsed = currentFuel + fuelConsumedBetween;

    if (totalFuelUsed <= 0) {
      return 0.0;
    }
    return distance / totalFuelUsed;
  }

  void _save() async {
    final provider = context.read<BikeProvider>();

    if (_costController.text.isEmpty || _mainInputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill cost and distance fields")),
      );
      return;
    }

    final costParsed = double.tryParse(_costController.text);
    if (costParsed == null || costParsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid cost amount")),
      );
      return;
    }

    final mainInputParsed = double.tryParse(_mainInputController.text);
    if (mainInputParsed == null || mainInputParsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid distance")),
      );
      return;
    }

    if (_linkToExpense && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an account to debit")),
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
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).notifyFuelLogged(
          vehicleName: widget.bike.name,
          mileage: entry.mileage!,
          fuelAmount: entry.fuelQuantity,
          cost: entry.fuelAmount,
        );
      }

      if (_calculatedOdo > widget.bike.currentOdometer) {
        provider.updateBike(
          widget.bike.copyWith(currentOdometer: _calculatedOdo),
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
          await context.read<TransactionProvider>().commitDraft(
            TransactionDraft.fromTransaction(transaction),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _linkToExpense
                  ? "Entry added & expense recorded"
                  : "Entry added successfully",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error adding entry: $e")));
      }
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
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                _isFuelMode ? 'Add Fuel' : 'Add Expense',
                style: AppTypography.headlineMedium,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black26,
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
                  _buildLiveSummaryCard(),
                  const SizedBox(height: AppSpacing.xl2),

                  Text(
                    _isInputtingTrip ? "Trip Distance" : "New Odometer",
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mainInputController,
                          onChanged: _onMainInputChanged,
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            suffixText: ' km',
                            suffixStyle: AppTypography.displayMedium.copyWith(
                              color: _isFuelMode
                                  ? AppColors.primaryBlue
                                  : AppColors.pastelOrange,
                              fontWeight: FontWeight.bold,
                            ),
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.cardElevated,
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
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(16),
                          onPressed: _toggleInputMode,
                          icon: const Icon(
                            Icons.swap_vert_circle,
                            color: AppColors.textTertiary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  if (_isFuelMode) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Full Tank Fill-up',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        NexusSwitch(
                          value: _isFullTank,
                          activeThumbColor: AppColors.primaryBlue,
                          onChanged: (val) => setState(() => _isFullTank = val),
                        ),
                      ],
                    ),
                    if (!_isFullTank)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          "Mileage won't be calculated for partial fill-ups.",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStandardTextField(
                            controller: _volumeController,
                            hint: "Volume",
                            icon: Icons.water_drop_outlined,
                            suffix: "L",
                            onChanged: (_) => _onFuelMathChanged(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStandardTextField(
                            controller: _rateController,
                            hint: "Rate/L",
                            icon: Icons.price_change_outlined,
                            suffix: "₹",
                            onChanged: (_) => _onFuelMathChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    Text(
                      'Category',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppColors.cardElevated,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                          items:
                              [
                                    'maintenance',
                                    'repair',
                                    'insurance',
                                    'fine',
                                    'other',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c[0].toUpperCase() + c.substring(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
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
                  _buildStandardTextField(
                    controller: _costController,
                    hint: "Total Cost",
                    icon: Icons.currency_rupee,
                    isHighlight: true,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
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
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      DateFormat(
                                        'dd/MMM/yy',
                                      ).format(_selectedDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            Text(
                              'Notes',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildStandardTextField(
                              controller: _notesController,
                              hint: "Optional",
                              icon: Icons.note_alt_outlined,
                              isNumber: false,
                            ),
                          ],
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
                        backgroundColor: _isFuelMode
                            ? AppColors.primaryBlue
                            : AppColors.pastelOrange,
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
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSummaryCard() {
    final themeColor = _isFuelMode
        ? AppColors.primaryBlue
        : AppColors.pastelOrange;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ENTRY SUMMARY",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                _isFuelMode ? Icons.local_gas_station : Icons.build,
                color: themeColor,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURRENT ODOMETER",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    "${_calculatedOdo.toStringAsFixed(0)} km",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isFuelMode ? "VOLUME" : "CATEGORY",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    _isFuelMode
                        ? "${_volumeController.text.isEmpty ? '0' : _volumeController.text} L"
                        : _selectedCategory.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL COST",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${_costController.text.isEmpty ? '0' : _costController.text}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = true,
    bool isHighlight = false,
    String? suffix,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: isHighlight
              ? BorderSide(
                  color:
                      (_isFuelMode
                              ? AppColors.primaryBlue
                              : AppColors.pastelOrange)
                          .withValues(alpha: 0.5),
                )
              : BorderSide.none,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(
            icon,
            color: isHighlight
                ? (_isFuelMode ? AppColors.primaryBlue : AppColors.pastelOrange)
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(IconData icon, bool isFuel) {
    final isSelected = _isFuelMode == isFuel;
    return GestureDetector(
      onTap: () => setState(() => _isFuelMode = isFuel),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? (isFuel ? AppColors.primaryBlue : AppColors.pastelOrange)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildExpenseLinkingSection() {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _linkToExpense
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
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
                    : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link to Expenses",
                      style: TextStyle(
                        color: _linkToExpense
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Auto-create transaction",
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              NexusSwitch(
                value: _linkToExpense,
                activeThumbColor: AppColors.success,
                onChanged: (val) => setState(() {
                  _linkToExpense = val;
                  if (!val) {
                    _selectedAccount = null;
                  }
                }),
              ),
            ],
          ),
          if (_linkToExpense) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Account>(
                  value: _selectedAccount,
                  isExpanded: true,
                  dropdownColor: AppColors.cardElevated,
                  hint: Text(
                    "Select Account to Debit",
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  items: accounts.map((account) {
                    final bankLogo = LogoUtils.bankLogoFor(
                      account.bankName ?? account.name,
                    );
                    return DropdownMenuItem<Account>(
                      value: account,
                      child: Row(
                        children: [
                          if (bankLogo != null)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: LogoUtils.buildLogo(bankLogo, size: 20),
                            )
                          else
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 20,
                              color: AppColors.primaryBlue,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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
