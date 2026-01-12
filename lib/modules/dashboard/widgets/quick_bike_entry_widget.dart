import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../bike/widgets/add_entry_dialog.dart';
import 'quick_bike_entry_ui.dart';

/// Quick bike entry widget for dashboard
class QuickBikeEntryWidget extends StatelessWidget {
  const QuickBikeEntryWidget({super.key});

  void _showQuickAddEntry(BuildContext context, BikeProvider provider, bike) {
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(bike: bike),
    ).then((result) {
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel entry added!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        // Don't show if no bikes
        if (provider.bikes.isEmpty) {
          return const SizedBox.shrink();
        }

        final bike = provider.selectedBike;
        if (bike == null) return const SizedBox.shrink();

        final mileage = provider.getAverageMileage().toStringAsFixed(1);

        // Get bottom navigation bar height for proper padding
        final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: QuickBikeEntryUI.buildContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with bike name and mileage
                QuickBikeEntryUI.buildHeader(
                  bikeName: bike.name,
                  mileage: '$mileage km/l',
                ),
                const SizedBox(height: 12),

                // Action button (Add Entry - handles both fuel and expenses)
                QuickBikeEntryUI.buildActionButtons(
                  onAddFuel: () => _showQuickAddEntry(context, provider, bike),
                  onAddTrip: () => _showQuickAddEntry(context, provider, bike),
                ),

                // Last fill-up info if available
                if (provider.currentBikeEntries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildLastFillupInfo(provider),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastFillupInfo(BikeProvider provider) {
    final lastEntry = provider.currentBikeEntries.first;
    final daysSince = DateTime.now().difference(lastEntry.date).inDays;

    return QuickBikeEntryUI.buildLastFillupInfo(
      daysSince: daysSince,
      fuelCost: lastEntry.fuelAmount,
    );
  }
}
