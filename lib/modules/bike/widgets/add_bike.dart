import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/rto_service.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddBikeScreen extends StatefulWidget {
  final Bike? bikeToEdit;
  const ModernAddBikeScreen({super.key, this.bikeToEdit});

  @override
  State<ModernAddBikeScreen> createState() => _ModernAddBikeScreenState();
}

class _ModernAddBikeScreenState extends State<ModernAddBikeScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _registrationController = TextEditingController();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();

  late AnimationController _logoAnimationController;
  late Animation<Offset> _logoSlideAnimation;

  String? _fetchedMake,
      _fetchedOwner,
      _fetchedInsurer,
      _fetchedFuelType,
      _fetchedRtoLocation,
      _fetchedChassis,
      _fetchedEngine;
  DateTime? _fetchedExpiry;
  bool _isFetching = false;
  bool _fetchSuccess = false;

  @override
  void initState() {
    super.initState();

    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _logoAnimationController,
            curve: Curves.easeOut,
          ),
        );

    if (widget.bikeToEdit != null) {
      final b = widget.bikeToEdit!;
      _registrationController.text = b.registrationNumber;
      _nameController.text = b.name;
      _modelController.text = b.model;
      _yearController.text = b.year.toString();
      _odometerController.text = b.currentOdometer.toStringAsFixed(0);
      _fetchSuccess = true;
    }

    // Add listeners to update the Live Card dynamically
    _registrationController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _modelController.addListener(() => setState(() {}));
    _yearController.addListener(() => setState(() {}));
    _odometerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _registrationController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
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
    return null;
  }

  Future<void> _fetchVehicleDetails() async {
    final regNo = _registrationController.text.trim();
    if (regNo.isEmpty) {
      showTopSnackBar(
        context,
        'Enter registration number first',
        isError: true,
      );
      return;
    }

    setState(() {
      _isFetching = true;
      _fetchSuccess = false;
    });

    try {
      final details = await RTOService().getVehicleDetails(regNo);
      if (details != null) {
        setState(() {
          _fetchedMake = details.make;
          _fetchedOwner = details.ownerName;
          _fetchedInsurer = details.insurer;
          _fetchedFuelType = details.fuelType;
          _fetchedRtoLocation = details.rtoLocation;
          _fetchedChassis = details.chassisNumber;
          _fetchedEngine = details.engineNumber;
          _fetchedExpiry = _parseDate(details.policyExpiry);

          if (_modelController.text.isEmpty) {
            _modelController.text = details.model;
          }
          if (_yearController.text.isEmpty) {
            _yearController.text = details.modelYear;
          }

          _fetchSuccess = true;
          _isFetching = false;
        });
        _logoAnimationController.forward(from: 0.0);
        if (mounted) {
          showTopSnackBar(context, 'Vehicle details fetched successfully');
        }
      } else {
        setState(() {
          _isFetching = false;
          _fetchSuccess = false;
        });
        if (mounted) {
          showTopSnackBar(
            context,
            'Vehicle not found. Please check number.',
            isError: true,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isFetching = false;
        _fetchSuccess = false;
      });
      if (mounted) {
        showTopSnackBar(
          context,
          'Network error. Try again later.',
          isError: true,
        );
      }
    }
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BikeProvider>();
    final reg = _registrationController.text.trim();
    final model = _modelController.text.trim();
    final yearStr = _yearController.text.trim();
    final name = _nameController.text.trim();
    final odoStr = _odometerController.text.trim();

    int year = DateTime.now().year;
    if (yearStr.isNotEmpty) year = int.tryParse(yearStr) ?? year;
    double odometer = double.tryParse(odoStr) ?? 0.0;

    // Use newly fetched make, OR existing make, OR guess from the model
    final make =
        (_fetchedMake ??
                widget.bikeToEdit?.make ??
                (model.isNotEmpty ? model.split(' ').first : 'Unknown'))
            .trim();

    Bike bike;

    if (widget.bikeToEdit != null) {
      // ✅ EDIT MODE: Keep existing data (image, displayOrder, etc.) and only update changed fields
      bike = widget.bikeToEdit!.copyWith(
        name: name.isEmpty ? 'My Vehicle' : name,
        model: model,
        year: year,
        currentOdometer: odometer,
        registrationNumber: reg.toUpperCase(),
        make: make,
        ownerName: _fetchedOwner ?? widget.bikeToEdit!.ownerName,
        fuelType: _fetchedFuelType ?? widget.bikeToEdit!.fuelType,
        rtoLocation: _fetchedRtoLocation ?? widget.bikeToEdit!.rtoLocation,
        insurer: _fetchedInsurer ?? widget.bikeToEdit!.insurer,
        policyExpiry: _fetchedExpiry ?? widget.bikeToEdit!.policyExpiry,
        chassisNumber: _fetchedChassis ?? widget.bikeToEdit!.chassisNumber,
        engineNumber: _fetchedEngine ?? widget.bikeToEdit!.engineNumber,
      );
    } else {
      // ✅ ADD MODE: Create a brand new bike
      bike = Bike(
        id: '',
        userId: '',
        name: name.isEmpty ? 'My Vehicle' : name,
        model: model,
        year: year,
        currentOdometer: odometer,
        createdAt: DateTime.now(),
        isActive: true,
        registrationNumber: reg.toUpperCase(),
        make: make,
        ownerName: _fetchedOwner,
        fuelType: _fetchedFuelType,
        rtoLocation: _fetchedRtoLocation,
        insurer: _fetchedInsurer,
        policyExpiry: _fetchedExpiry,
        chassisNumber: _fetchedChassis,
        engineNumber: _fetchedEngine,
      );
    }

    if (widget.bikeToEdit == null) {
      provider
          .addBike(bike)
          .then((_) => Navigator.pop(context))
          .catchError(
            (e) =>
                showTopSnackBar(context, 'Failed to save: $e', isError: true),
          );
    } else {
      provider
          .updateBike(bike)
          .then((_) => Navigator.pop(context))
          .catchError(
            (e) =>
                showTopSnackBar(context, 'Failed to update: $e', isError: true),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bikeToEdit != null ? 'Edit Vehicle' : 'New Vehicle';

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
              title: Text(title, style: AppTypography.headlineMedium),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveCard(),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Current Odometer',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _odometerController,
                      autofocus: widget.bikeToEdit == null,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: ' km',
                        suffixStyle: AppTypography.displayMedium.copyWith(
                          color: AppColors.primaryBlue,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Registration Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardTextField(
                      controller: _registrationController,
                      hint: "Registration Number (e.g. KA01AB1234)",
                      icon: Icons.numbers,
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isFetching ? null : _fetchVehicleDetails,
                        icon: _isFetching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _fetchSuccess
                                    ? Icons.check_circle
                                    : Icons.search,
                                color: _fetchSuccess
                                    ? AppColors.pastelGreen
                                    : Colors.white,
                              ),
                        label: Text(
                          _fetchSuccess
                              ? "RTO Details Fetched"
                              : "Fetch RTO Details",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _fetchSuccess
                                ? AppColors.pastelGreen.withOpacity(0.5)
                                : Colors.white.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Vehicle Information',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardTextField(
                      controller: _nameController,
                      hint: "Nickname (e.g. Daily Commuter)",
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildStandardTextField(
                            controller: _modelController,
                            hint: "Make & Model",
                            icon: Icons.motorcycle,
                            validator: (val) =>
                                val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 1,
                          child: _buildStandardTextField(
                            controller: _yearController,
                            hint: "Year",
                            icon: Icons.calendar_today,
                            isNumber: true,
                            maxLength: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveBike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
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
                          widget.bikeToEdit != null
                              ? 'Save Changes'
                              : 'Add Vehicle',
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
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.cardDarkElevated,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLiveCard() {
    String displayReg = _registrationController.text.isEmpty
        ? "REG NUMBER"
        : _registrationController.text.toUpperCase();
    String displayName = _nameController.text.isEmpty
        ? (_modelController.text.isEmpty
              ? "New Vehicle"
              : _modelController.text)
        : _nameController.text;
    String displayOdo = _odometerController.text.isEmpty
        ? "0"
        : _odometerController.text;
    String displayYear = _yearController.text.isEmpty
        ? "YYYY"
        : _yearController.text;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF111111),
            Colors.black.withOpacity(0.8),
            const Color(0xFF0A0A0A).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: Icon(
                        Icons.two_wheeler,
                        color: Colors.white.withOpacity(0.8),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "RC STATUS: ${_fetchSuccess ? 'VERIFIED' : 'PENDING'}",
                    style: TextStyle(
                      color: _fetchSuccess
                          ? AppColors.pastelGreen
                          : AppColors.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayReg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Monospace",
                        fontSize: 18,
                        letterSpacing: 3,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ODOMETER",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              "$displayOdo km",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "YEAR",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              displayYear,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
