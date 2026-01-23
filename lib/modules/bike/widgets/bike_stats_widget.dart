import 'package:flutter/material.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';

class BikeStatsWidget extends StatelessWidget {
  final BikeProvider provider;

  const BikeStatsWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.primaryBlue;

    // Use provider's mileage calculation for consistency
    final avgMileage = provider.getAverageMileage();
    final totalFuelCost = provider.getTotalFuelCost();
    final totalFillups = provider.getTotalFillups();
    final totalDistance = provider.getKmTraveled();

    final stats = [
      _StatData(
        'Avg Mileage',
        avgMileage > 0 ? avgMileage.toStringAsFixed(1) : '-',
        'km/l',
        Icons.speed,
      ),
      _StatData(
        'Cost',
        '₹${totalFuelCost.toStringAsFixed(0)}',
        '',
        Icons.account_balance_wallet_outlined,
      ),
      _StatData(
        'Fill-ups',
        '$totalFillups',
        '',
        Icons.local_gas_station_outlined,
      ),
      _StatData(
        'Distance',
        totalDistance > 0 ? totalDistance.toStringAsFixed(1) : '-',
        'km',
        Icons.add_road,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppColors.white.withOpacity(0.4),
                    ),
                  ),
                  Icon(
                    stat.icon,
                    size: 18,
                    color: accentColor.withOpacity(0.7),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      height: 1.0,
                    ),
                  ),
                  if (stat.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        stat.unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  _StatData(this.label, this.value, this.unit, this.icon);
}
