import 'package:flutter/material.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';

class BikeStatsWidget extends StatelessWidget {
  final BikeProvider provider;

  const BikeStatsWidget({super.key, required this.provider});

  void _showMileageInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mileage Calculation',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your mileage is calculated using the Full Tank to Full Tank method. We measure the distance driven between two full tanks and divide it by the total fuel added, automatically accounting for any partial fill-ups along the way.',
          style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                  color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalFuel = 0.0;
    double totalKm = 0.0;

    final fuelEntries = provider.currentBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    if (fuelEntries.isNotEmpty) {
      // Use min/max odometer for total distance (more robust than
      // relying on sort order matching chronological order)
      double minOdo = fuelEntries.first.odometerReading;
      double maxOdo = fuelEntries.first.odometerReading;
      for (final e in fuelEntries) {
        if (e.odometerReading < minOdo) minOdo = e.odometerReading;
        if (e.odometerReading > maxOdo) maxOdo = e.odometerReading;
      }
      totalKm = maxOdo - minOdo;

      // Calculate total fuel (all entries)
      for (final entry in fuelEntries) {
        totalFuel += entry.fuelQuantity;
      }

      // Reliable mileage: full-tank-to-full-tank average
      final reliableMileage = provider.getReliableAverageMileage();

      // Prepare stats list
      final stats = [
        _StatData(
          'Mileage',
          reliableMileage > 0 ? reliableMileage.toStringAsFixed(1) : '--',
          'km/l',
          Icons.speed,
        ),
        _StatData(
          'Fuel-ups',
          fuelEntries.length.toString(),
          '',
          Icons.local_gas_station,
        ),
        _StatData(
          'Distance',
          totalKm > 0 ? totalKm.toStringAsFixed(1) : '--',
          'km',
          Icons.route,
        ),
        _StatData(
          'Cost',
          fuelEntries
              .fold<double>(0, (sum, e) => sum + (e.fuelAmount))
              .toStringAsFixed(0),
          '₹',
          Icons.currency_rupee,
          subtitle: fuelEntries.isNotEmpty
              ? '${fuelEntries.map((e) => '${e.date.day}/${e.date.month}').toSet().length} days'
              : '',
        ),
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Explicitly set tight vertical padding to close the gap between surrounding widgets
        padding: const EdgeInsets.symmetric(vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio:
              1.5, // Slightly adjusted to give the layout breathing room
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          final statColor = _getStatColor(index);
          
          final cardWidget = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statColor.withValues(alpha: 0.15),
                  const Color(0xFF1E1E1E),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: statColor.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW: Heading (Left) & Logo (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: statColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(stat.icon, size: 14, color: statColor),
                    ),
                  ],
                ),

                const Spacer(), // Pushes the data down to the center
                // CENTERED DATA: Left Aligned horizontally
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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
                            color: statColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // SUBTEXT: Directly below the data
                if (stat.subtitle != null && stat.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      stat.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: statColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const Spacer(), // Balances the vertical centering
              ],
            ),
          );

          // Add tap detection only to the Mileage card
          if (stat.label == 'Mileage') {
            return GestureDetector(
              onTap: () => _showMileageInfoDialog(context),
              child: cardWidget,
            );
          }

          return cardWidget;
        },
      );
    }
    // If no fuel entries, show empty grid
    return const SizedBox.shrink();
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
  final String? subtitle;
  _StatData(this.label, this.value, this.unit, this.icon, {this.subtitle});
}