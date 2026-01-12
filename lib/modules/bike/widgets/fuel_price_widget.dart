import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/fuel_price_provider.dart';

class FuelPriceWidget extends StatefulWidget {
  final Function(double) onPriceSelected;

  const FuelPriceWidget({super.key, required this.onPriceSelected});

  @override
  State<FuelPriceWidget> createState() => _FuelPriceWidgetState();
}

class _FuelPriceWidgetState extends State<FuelPriceWidget> {
  String _fuelType = 'Petrol';
  String _selectedBrand = 'Indian Oil';

  final Map<String, double> _brandVariance = {
    'Indian Oil': 0.0,
    'HPCL': 0.0,
    'BPCL': 0.0,
    'Jio-BP': 0.50,
    'Shell': 3.43,
    'Nayara': 0.20,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateFinalPrice();
    });
  }

  void _calculateFinalPrice() {
    final priceProvider = context.read<FuelPriceProvider>();
    final currentPrice = priceProvider.currentPrice;

    if (currentPrice != null) {
      double base = _fuelType == 'Petrol'
          ? currentPrice.petrol
          : currentPrice.diesel;
      double variance = _brandVariance[_selectedBrand] ?? 0.0;
      double finalPrice = base + variance;

      widget.onPriceSelected(finalPrice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuelPriceProvider>(
      builder: (context, priceProvider, _) {
        final currentPrice = priceProvider.currentPrice;
        final selectedCity = priceProvider.selectedCity ?? 'Loading...';
        final isLoading = priceProvider.isLoading;

        double base = currentPrice != null
            ? (_fuelType == 'Petrol'
                  ? currentPrice.petrol
                  : currentPrice.diesel)
            : 100.0;
        double variance = _brandVariance[_selectedBrand] ?? 0.0;
        double displayPrice = base + variance;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        DropdownButton<String>(
                          value:
                              priceProvider.supportedCities.contains(
                                selectedCity,
                              )
                              ? selectedCity
                              : priceProvider.supportedCities.first,
                          dropdownColor: AppColors.cardSurface,
                          underline: const SizedBox(),
                          isDense: true,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          items: priceProvider.supportedCities
                              .map(
                                (city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              priceProvider.loadPriceForCity(val);
                              _calculateFinalPrice();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await priceProvider.detectAndLoadCity();
                                _calculateFinalPrice();
                                if (mounted &&
                                    priceProvider.selectedCity != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '📍 Location: ${priceProvider.selectedCity}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                      ),
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await priceProvider.refresh();
                                _calculateFinalPrice();
                              },
                        icon: Icon(
                          Icons.refresh,
                          color: isLoading
                              ? AppColors.textTertiary
                              : AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.white10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Current Rate',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (currentPrice?.lastUpdated != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Updated today',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.pastelGreen,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayPrice.toStringAsFixed(2),
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBlack,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        _buildFuelTypeBtn('Petrol', AppColors.pastelOrange),
                        _buildFuelTypeBtn('Diesel', AppColors.primaryBlue),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _brandVariance.keys.map((brand) {
                    bool isSelected = _selectedBrand == brand;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedBrand = brand);
                          _calculateFinalPrice();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.textPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                          child: Text(
                            brand,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.backgroundBlack
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuelTypeBtn(String type, Color color) {
    bool isSelected = _fuelType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _fuelType = type);
        _calculateFinalPrice();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          type,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? color : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
