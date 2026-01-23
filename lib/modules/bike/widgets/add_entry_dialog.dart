import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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

  // Controllers
  final _mainInputController = TextEditingController();
  final _costController = TextEditingController();
  final _volumeController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'maintenance';

  // Math Helpers
  double _lastOdo = 0.0;
  double _calculatedOdo = 0.0;
  double _calculatedTrip = 0.0;

  final List<String> _expenseCategories = [
    'maintenance',
    'repair',
    'insurance',
    'modification',
    'fine',
    'other',
  ];

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

  void _save() {
    final provider = context.read<BikeProvider>();

    if (_costController.text.isEmpty || _mainInputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill cost and distance fields")),
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
      fuelAmount: double.parse(_costController.text),
      category: finalCategory,
      notes: _notesController.text,
      isFullTank: _isFullTank, // <--- Saving the flag
      mileage: calculatedMileage,
    );

    provider.addBikeEntry(entry);

    if (_calculatedOdo > widget.bike.currentOdometer) {
      final updatedBike = widget.bike.copyWith(currentOdometer: _calculatedOdo);
      provider.updateBike(updatedBike);
    }

    if (mounted) Navigator.pop(context);
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
                        activeColor: AppColors.primaryBlue,
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
                  child: const Text(
                    'Save Entry',
                    style: TextStyle(
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
        duration: const Duration(milliseconds: 200),
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
    bool isNumber = false,
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
}
