import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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

    final entry = BikeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: provider.auth.currentUser?.uid ?? '',
      bikeName: widget.bike.name,
      date: _selectedDate,
      odometerReading: _calculatedOdo,
      fuelQuantity: _isFuelMode
          ? (double.tryParse(_volumeController.text) ?? 0)
          : 0,
      fuelAmount: double.parse(_costController.text),
      category: finalCategory,
      notes: _notesController.text,
      mileage:
          (_isFuelMode &&
              _calculatedTrip > 0 &&
              (double.tryParse(_volumeController.text) ?? 0) > 0)
          ? _calculatedTrip / double.parse(_volumeController.text)
          : null,
    );

    provider.addBikeEntry(entry);

    // Update bike odometer locally
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
                  // Mode Toggle Pill
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
                _buildLabel('Category'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: AppColors.cardSurface,
                      isExpanded: true,
                      items: _expenseCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                ),
                if (_selectedCategory == 'other') ...[
                  const SizedBox(height: 12),
                  _buildGlassField(
                    controller: _customCategoryController,
                    hint: "Custom Name",
                  ),
                ],
              ],

              const SizedBox(height: 16),
              _buildGlassField(
                controller: _costController,
                hint: "Total Cost",
                suffix: "₹",
                isHighlight: true,
              ),
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

  Widget _buildModeBtn(IconData icon, bool isFuel) {
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
