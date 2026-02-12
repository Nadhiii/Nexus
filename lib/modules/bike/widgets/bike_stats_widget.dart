import 'package:flutter/material.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';

class BikeStatsWidget extends StatelessWidget {
  final BikeProvider provider;

  const BikeStatsWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // --- SIMPLE AVERAGE CALCULATION (matches spreadsheet) ---
    double avgMileage = 0.0;
    double totalFuel = 0.0;
    double totalKm = 0.0;

    final fuelEntries = provider.currentBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    if (fuelEntries.isNotEmpty) {
      // Sort by odometer reading for distance calculation
      fuelEntries.sort(
        (a, b) => a.odometerReading.compareTo(b.odometerReading),
      );

      double minOdo = fuelEntries.first.odometerReading;
      double maxOdo = fuelEntries.last.odometerReading;
      totalKm = maxOdo - minOdo;

      // Calculate total fuel (all entries)
      for (final entry in fuelEntries) {
        totalFuel += entry.fuelQuantity;
      }

      // Simple average of individual mileages (matches spreadsheet AVERAGE)
      final entriesWithMileage = fuelEntries
          .where((e) => e.mileage != null && e.mileage! > 0)
          .toList();
      if (entriesWithMileage.isNotEmpty) {
        final totalMileage = entriesWithMileage.fold<double>(
          0,
          (sum, e) => sum + e.mileage!,
        );
        avgMileage = totalMileage / entriesWithMileage.length;
      }
    }

    final stats = [
      _StatData(
        'Avg Mileage',
        avgMileage > 0 ? avgMileage.toStringAsFixed(1) : '-',
        'km/l',
        Icons.speed,
      ),
      _StatData(
        'Cost',
        '₹${provider.getTotalFuelCost().toStringAsFixed(0)}',
        '',
        Icons.account_balance_wallet_outlined,
      ),
      _StatData(
        'Fill-ups',
        '${provider.getTotalFillups()}',
        '',
        Icons.local_gas_station_outlined,
      ),
      _StatData(
        'Distance',
        totalKm > 0 ? totalKm.toStringAsFixed(1) : '-',
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
        final statColor = _getStatColor(index);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statColor.withOpacity(0.15), const Color(0xFF1E1E1E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: statColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.white.withOpacity(0.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stat.icon, size: 16, color: statColor),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      height: 1.0,
                    ),
                  ),
                  if (stat.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text(
                        stat.unit,
                        style: TextStyle(
                          fontSize: 12,
                          color: statColor,
                          fontWeight: FontWeight.w600,
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

  Color _getStatColor(int index) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.pastelGreen,
      AppColors.pastelOrange,
      AppColors.pastelPurple,
    ];
    return colors[index % colors.length];
  }
}

class _StatData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  _StatData(this.label, this.value, this.unit, this.icon);
}
