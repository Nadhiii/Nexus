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
  late final TextEditingController _odometerController;
  late final TextEditingController _fuelQuantityController;
  late final TextEditingController _fuelAmountController;
  late final TextEditingController _notesController;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final _categories = ['fuel', 'maintenance', 'insurance', 'repairs', 'other'];

  @override
  void initState() {
    super.initState();
    _odometerController = TextEditingController(
      text: widget.entry.odometerReading.toString(),
    );
    _fuelQuantityController = TextEditingController(
      text: widget.entry.fuelQuantity.toString(),
    );
    _fuelAmountController = TextEditingController(
      text: widget.entry.fuelAmount.toString(),
    );
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _selectedCategory = widget.entry.category ?? 'fuel';
    _selectedDate = widget.entry.date;
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
                'Edit Fuel Entry',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Date
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
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: AppColors.whiteDim,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

              // Category
              Text(
                'Category',
                style: TextStyle(color: AppColors.whiteDim, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.white.withOpacity(0.12)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.toUpperCase(),
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'fuel';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Odometer
              _buildDarkTextField(
                'Odometer Reading (km)',
                _odometerController,
                TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Fuel Quantity
              _buildDarkTextField(
                'Fuel Quantity (Liters)',
                _fuelQuantityController,
                const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Fuel Amount
              _buildDarkTextField(
                'Amount (₹)',
                _fuelAmountController,
                const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Notes
              _buildDarkTextField(
                'Notes (Optional)',
                _notesController,
                TextInputType.text,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.whiteDim),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Update Entry',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.whiteDim, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: AppColors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.white.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateEntry() {
    if (_odometerController.text.isEmpty ||
        _fuelQuantityController.text.isEmpty ||
        _fuelAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final odometer = double.tryParse(_odometerController.text.trim());
    final quantity = double.tryParse(_fuelQuantityController.text.trim());
    final amount = double.tryParse(_fuelAmountController.text.trim());

    if (odometer == null || quantity == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
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
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      mileage: widget.entry.mileage, // Keep existing mileage
      category: _selectedCategory,
    );

    widget.provider.updateBikeEntry(updatedEntry).then((_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated successfully')),
      );
    });
  }
}
