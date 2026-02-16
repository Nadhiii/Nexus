import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
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
import '../../../core/utils/logo_utils.dart';

class AddEntryDialog extends StatefulWidget {
  final Bike bike;
  final double? initialRate;

  const AddEntryDialog({super.key, required this.bike, this.initialRate});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  // --- STATE ---
  bool _isFuelMode = true;
  bool _isInputtingTrip = true;
  bool _isFullTank = true; // <--- NEW: State for Full Tank Toggle
  bool _linkToExpense = true; // Link garage entries to expense transactions
  Account? _selectedAccount;

  // Controllers
  final _mainInputController = TextEditingController();
  final _costController = TextEditingController();
  final _volumeController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final String _selectedCategory = 'maintenance';

  // Math Helpers
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

  // --- LOGIC ---
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

  // --- THE CORE MILEAGE LOGIC ---
  double? _calculateExactMileage(
    List<BikeEntry> history,
    double currentOdo,
    double currentFuel,
  ) {
    if (!_isFullTank) return null; // Partial fill-ups cannot determine mileage

    // Sort history by Odometer descending (Newest first)
    // Note: Ensure your provider returns a sorted list or sort it here
    final sortedHistory = List<BikeEntry>.from(history)
      ..sort((a, b) => b.odometerReading.compareTo(a.odometerReading));

    // 1. Find the LAST "Full Tank" entry
    BikeEntry? lastFullTankEntry;
    double fuelConsumedBetween = 0.0;

    for (var entry in sortedHistory) {
      // Only look at fuel entries
      if ((entry.category ?? 'fuel') != 'fuel') continue;

      if (entry.isFullTank) {
        lastFullTankEntry = entry;
        break; // Found the start point!
      } else {
        // This was a partial fill-up between the last full tank and now.
        // We must add this fuel to the total consumption.
        fuelConsumedBetween += entry.fuelQuantity;
      }
    }

    if (lastFullTankEntry == null) {
      return null; // This is the first ever full tank, can't calculate yet.
    }

    // 2. Calculate Distance
    double distance = currentOdo - lastFullTankEntry.odometerReading;

    // 3. Calculate Total Fuel Used
    // (Fuel added TODAY) + (Fuel added in partial fills since last full tank)
    double totalFuelUsed = currentFuel + fuelConsumedBetween;

    if (totalFuelUsed <= 0) return 0.0;

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

    // Validate cost is a valid number
    final costParsed = double.tryParse(_costController.text);
    if (costParsed == null || costParsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid cost amount")),
      );
      return;
    }

    // Validate distance is a valid number
    final mainInputParsed = double.tryParse(_mainInputController.text);
    if (mainInputParsed == null || mainInputParsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid distance")),
      );
      return;
    }

    // Validate account selection if linking to expense
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

    // Calculate Mileage using the robust function
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

      // Trigger notification if mileage was calculated (full tank)
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

      // Create expense transaction if linked
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
            categoryId: _isFuelMode
                ? 'transportation'
                : 'transportation', // Map to Transportation category
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
    return Dialog(
      backgroundColor: AppColors.backgroundBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isFuelMode ? 'Add Fuel' : 'Add Expense',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
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
              const SizedBox(height: 24),

              // ODOMETER CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isInputtingTrip
                                    ? "TRIP DISTANCE"
                                    : "NEW ODOMETER",
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextField(
                                controller: _mainInputController,
                                keyboardType: TextInputType.number,
                                onChanged: _onMainInputChanged,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  suffixText: 'km',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleInputMode,
                          icon: const Icon(
                            Icons.swap_vert_circle,
                            color: AppColors.textTertiary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isInputtingTrip
                              ? "New Odometer: ${_calculatedOdo.toStringAsFixed(0)} km"
                              : "Trip Distance: ${_calculatedTrip.toStringAsFixed(1)} km",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        if (_isInputtingTrip)
                          Text(
                            "(Prev: ${_lastOdo.toStringAsFixed(0)})",
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FIELDS
              if (_isFuelMode) ...[
                // --- NEW: Full Tank Toggle ---
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _isFullTank,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: (val) => setState(() => _isFullTank = val),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Full Tank",
                        style: TextStyle(
                          color: _isFullTank
                              ? Colors.white
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!_isFullTank)
                        Text(
                          "(Mileage won't be calculated)",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildGlassField(
                        controller: _volumeController,
                        hint: "Litres",
                        onChanged: (_) => _onFuelMathChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassField(
                        controller: _rateController,
                        hint: "Price/L",
                        suffix: "₹",
                        onChanged: (_) => _onFuelMathChanged(),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // (Expense UI remains the same as your original file)
                _buildLabel('Category'),
                // ... existing expense dropdown code ...
              ],

              const SizedBox(height: 16),
              _buildGlassField(
                controller: _costController,
                hint: "Total Cost",
                suffix: "₹",
                isHighlight: true,
              ),

              // ... (Date and Notes UI remains the same)
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassField(
                      controller: _notesController,
                      hint: "Notes",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- LINK TO EXPENSE SECTION ---
              _buildExpenseLinkingSection(),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFuelMode
                        ? AppColors.primaryBlue
                        : AppColors.pastelOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _linkToExpense ? 'Save & Record Expense' : 'Save Entry',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Keep your helper methods _buildModeBtn, _buildLabel, _buildGlassField exactly as they were)
  Widget _buildModeBtn(IconData icon, bool isFuel) {
    // ... same as your original
    final isSelected = _isFuelMode == isFuel;
    return GestureDetector(
      onTap: () => setState(() => _isFuelMode = isFuel),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? (_isFuelMode ? AppColors.primaryBlue : AppColors.pastelOrange)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    bool isHighlight = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isHighlight
              ? (_isFuelMode ? AppColors.primaryBlue : AppColors.pastelOrange)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          suffixText: suffix,
          suffixStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseLinkingSection() {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _linkToExpense
              ? AppColors.success.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Row
          Row(
            children: [
              Icon(
                Icons.link,
                color: _linkToExpense
                    ? AppColors.success
                    : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Link to Expenses",
                      style: TextStyle(
                        color: _linkToExpense
                            ? Colors.white
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Auto-create expense transaction",
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
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

          // Account Dropdown (when enabled)
          if (_linkToExpense) ...[
            const SizedBox(height: 16),
            Text(
              "DEBIT FROM",
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundBlack,
                borderRadius: BorderRadius.circular(30),
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
                  dropdownColor: AppColors.cardSurface,
                  hint: Text(
                    "Select Account",
                    style: TextStyle(
                      color: AppColors.textTertiary.withOpacity(0.7),
                    ),
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: bankLogo != null
                                  ? LogoUtils.buildLogo(bankLogo, size: 16)
                                  : const Icon(
                                      Icons.account_balance_wallet,
                                      size: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "₹${account.balance.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
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
