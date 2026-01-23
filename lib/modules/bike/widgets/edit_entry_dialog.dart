import 'package:flutter/material.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';

class EditEntryDialog extends StatefulWidget {
  final BikeEntry entry;
  final BikeProvider provider;

  const EditEntryDialog({
    super.key,
    required this.entry,
    required this.provider,
  });

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  final _odometerController = TextEditingController();
  final _fuelQuantityController = TextEditingController();
  final _fuelAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'fuel';
  DateTime _selectedDate = DateTime.now();

  // Define standard categories
  final List<String> _categories = [
    'fuel',
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
    // 1. Safe Initialization
    _odometerController.text = widget.entry.odometerReading.toString();
    _fuelQuantityController.text = widget.entry.fuelQuantity.toString();
    _fuelAmountController.text = widget.entry.fuelAmount.toString();
    _notesController.text = widget.entry.notes ?? '';
    _selectedDate = widget.entry.date;

    // 2. CRASH FIX: Handle Category Mismatch
    // Ensure the saved category exists in the dropdown list
    String savedCat = (widget.entry.category ?? 'fuel').toLowerCase();
    if (!_categories.contains(savedCat)) {
      _categories.add(savedCat); // Add it dynamically if missing
    }
    _selectedCategory = savedCat;
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _fuelQuantityController.dispose();
    _fuelAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Entry',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null)
                        setState(() => _selectedCategory = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildField('Odometer (km)', _odometerController, isNumber: true),
              const SizedBox(height: 16),

              // Show Fuel fields only if category is fuel
              if (_selectedCategory == 'fuel') ...[
                _buildField(
                  'Fuel (Liters)',
                  _fuelQuantityController,
                  isNumber: true,
                ),
                const SizedBox(height: 16),
              ],

              _buildField('Amount (₹)', _fuelAmountController, isNumber: true),
              const SizedBox(height: 16),

              _buildField('Notes', _notesController, maxLines: 2),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _updateEntry() {
    final odometer = double.tryParse(_odometerController.text.trim());
    final amount = double.tryParse(_fuelAmountController.text.trim());
    final quantity =
        double.tryParse(_fuelQuantityController.text.trim()) ?? 0.0;

    if (odometer == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    final updatedEntry = BikeEntry(
      id: widget.entry.id,
      userId: widget.entry.userId,
      bikeName: widget.entry.bikeName,
      date: _selectedDate,
      fuelQuantity: quantity,
      fuelAmount: amount,
      odometerReading: odometer,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      // Reset mileage to null so the list recalculates it properly
      mileage: null,
      category: _selectedCategory,
      isFullTank: widget.entry.isFullTank,
    );

    widget.provider
        .updateBikeEntry(updatedEntry)
        .then((_) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry updated')));
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
        });
  }
}
