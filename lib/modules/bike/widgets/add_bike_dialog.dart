import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/rto_service.dart';

class AddBikeDialog extends StatefulWidget {
  final Bike? bikeToEdit;
  const AddBikeDialog({super.key, this.bikeToEdit});

  @override
  State<AddBikeDialog> createState() => _AddBikeDialogState();
}

class _AddBikeDialogState extends State<AddBikeDialog> {
  final _registrationController = TextEditingController();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();

  // Hidden RTO Storage... (Keep existing logic vars)
  String? _fetchedMake,
      _fetchedOwner,
      _fetchedInsurer,
      _fetchedFuelType,
      _fetchedRtoLocation,
      _fetchedChassis,
      _fetchedEngine;
  DateTime? _fetchedExpiry;
  bool _isFetching = false, _fetchSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.bikeToEdit != null) {
      final b = widget.bikeToEdit!;
      _registrationController.text = b.registrationNumber;
      _nameController.text = b.name;
      _modelController.text = b.model;
      _yearController.text = b.year.toString();
      _odometerController.text = b.currentOdometer.toString();
      _fetchSuccess = true; // Assume valid for edit
    }
  }

  // ... (Keep _fetchVehicleDetails, _parseDate logic same as before) ...
  // Simplified here for brevity, assume logic block is preserved

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      // Try parsing different date formats
      // Format: "05-Sep-2027"
      final formats = [
        DateFormat('dd-MMM-yyyy'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-dd'),
      ];

      for (var format in formats) {
        try {
          return format.parse(dateString);
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchVehicleDetails() async {
    final regNo = _registrationController.text.trim();
    if (regNo.isEmpty) {
      setState(() => _errorMessage = 'Enter registration number first');
      return;
    }

    setState(() {
      _isFetching = true;
      _errorMessage = null;
      _fetchSuccess = false;
    });

    try {
      final rtoService = RTOService();
      final details = await rtoService.getVehicleDetails(regNo);

      if (details != null) {
        setState(() {
          // Store RTO data in hidden vars
          _fetchedMake = details.make;
          _fetchedOwner = details.ownerName;
          _fetchedInsurer = details.insurer;
          _fetchedFuelType = details.fuelType;
          _fetchedRtoLocation = details.rtoLocation;
          _fetchedChassis = details.chassisNumber;
          _fetchedEngine = details.engineNumber;
          _fetchedExpiry = _parseDate(details.policyExpiry);

          // Auto-populate visible fields for convenience
          if (_modelController.text.isEmpty) {
            _modelController.text = details.model;
          }
          if (_yearController.text.isEmpty) {
            _yearController.text = details.modelYear;
          }

          _fetchSuccess = true;
          _isFetching = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Vehicle not found. Please check number.';
          _isFetching = false;
          _fetchSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Try again later.';
        _isFetching = false;
        _fetchSuccess = false;
      });
    }
  }

  void _saveBike() {
    final provider = context.read<BikeProvider>();

    // Basic validation
    final reg = _registrationController.text.trim();
    final model = _modelController.text.trim();
    final yearStr = _yearController.text.trim();
    final name = _nameController.text.trim();
    final odoStr = _odometerController.text.trim();

    if (reg.isEmpty) {
      setState(() => _errorMessage = 'Please enter registration number');
      return;
    }
    if (model.isEmpty) {
      setState(() => _errorMessage = 'Please enter vehicle model');
      return;
    }

    int year = DateTime.now().year;
    try {
      if (yearStr.isNotEmpty) {
        year = int.parse(yearStr);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Year must be a number');
      return;
    }

    double odometer = 0;
    try {
      if (odoStr.isNotEmpty) {
        odometer = double.parse(odoStr);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Odometer must be a number');
      return;
    }

    // Use fetched RTO values if present, else sensible defaults
    final make =
        (_fetchedMake ??
                (model.isNotEmpty ? model.split(' ').first : 'Unknown'))
            .trim();
    final owner = _fetchedOwner;
    final fuelType = _fetchedFuelType;
    final rtoLocation = _fetchedRtoLocation;
    final insurer = _fetchedInsurer;
    final policyExpiry = _fetchedExpiry;
    final chassis = _fetchedChassis;
    final engine = _fetchedEngine;

    // Construct Bike model
    final bike = Bike(
      id: widget.bikeToEdit?.id ?? '',
      userId: widget.bikeToEdit?.userId ?? '',
      name: name.isEmpty ? 'My Vehicle' : name,
      model: model,
      year: year,
      currentOdometer: odometer,
      createdAt: widget.bikeToEdit?.createdAt ?? DateTime.now(),
      isActive: widget.bikeToEdit?.isActive ?? true,
      registrationNumber: reg,
      make: make,
      ownerName: owner,
      fuelType: fuelType,
      rtoLocation: rtoLocation,
      insurer: insurer,
      policyExpiry: policyExpiry,
      chassisNumber: chassis,
      engineNumber: engine,
    );

    setState(() => _errorMessage = null);

    // Call Provider
    if (widget.bikeToEdit == null) {
      provider
          .addBike(bike)
          .then((_) {
            Navigator.pop(context);
          })
          .catchError((e) {
            setState(() => _errorMessage = 'Failed to save vehicle: $e');
          });
    } else {
      provider
          .updateBike(bike)
          .then((_) {
            Navigator.pop(context);
          })
          .catchError((e) {
            setState(() => _errorMessage = 'Failed to update vehicle: $e');
          });
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
              Text(
                widget.bikeToEdit != null ? 'Edit Vehicle' : 'New Vehicle',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // RTO SEARCH
              _buildLabel('REGISTRATION'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _fetchSuccess
                        ? AppColors.pastelGreen.withOpacity(0.5)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _registrationController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'KA01AB1234',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: _fetchVehicleDetails,
                        icon: _isFetching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.search,
                                color: _fetchSuccess
                                    ? AppColors.pastelGreen
                                    : AppColors.primaryBlue,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 24),
              _buildLabel('DETAILS'),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassField(
                      controller: _modelController,
                      hint: "Model",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassField(
                      controller: _yearController,
                      hint: "Year",
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGlassField(
                controller: _nameController,
                hint: "Nickname (Optional)",
              ),
              const SizedBox(height: 16),
              _buildGlassField(
                controller: _odometerController,
                hint: "Current Odometer (km)",
                isNumber: true,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveBike,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.bikeToEdit != null ? 'Update' : 'Save Vehicle',
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
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
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
