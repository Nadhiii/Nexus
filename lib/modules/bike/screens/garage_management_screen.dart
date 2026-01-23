import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';

class GarageManagementScreen extends StatefulWidget {
  const GarageManagementScreen({super.key});

  @override
  State<GarageManagementScreen> createState() => _GarageManagementScreenState();
}

class _GarageManagementScreenState extends State<GarageManagementScreen> {
  late List<Bike> _orderedBikes;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Create a local copy of the list so we can mutate it freely
    _orderedBikes = List.from(
      context.read<BikeProvider>().getBikesSortedByOrder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Manage Garage'),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _saveOrder,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  foregroundColor: AppColors.primaryBlue,
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Order'),
              ),
            ),
        ],
      ),
      body: _orderedBikes.isEmpty
          ? Center(
              child: Text(
                "No vehicles to manage",
                style: TextStyle(color: AppColors.textTertiary),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orderedBikes.length,
              // Drag handle is built-in with this widget
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final Bike item = _orderedBikes.removeAt(oldIndex);
                  _orderedBikes.insert(newIndex, item);
                  _hasChanges = true;
                });
              },
              itemBuilder: (context, index) {
                final bike = _orderedBikes[index];
                return _buildListTile(bike, index);
              },
            ),
    );
  }

  Widget _buildListTile(Bike bike, int index) {
    return Container(
      key: ValueKey(bike.id), // Key is crucial for reordering
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bike.isDashboardBike
              ? Colors.amber.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bike.isDashboardBike
                ? Colors.amber.withOpacity(0.1)
                : AppColors.backgroundBlack,
            shape: BoxShape.circle,
          ),
          child: Icon(
            bike.isDashboardBike ? Icons.star : Icons.directions_bike,
            color: bike.isDashboardBike ? Colors.amber : AppColors.textTertiary,
            size: 20,
          ),
        ),
        title: Text(
          bike.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${bike.make} ${bike.model}',
          style: TextStyle(color: AppColors.textTertiary),
        ),
        // Use a drag handle to make it obvious
        trailing: const Icon(Icons.drag_handle, color: AppColors.textTertiary),
      ),
    );
  }

  Future<void> _saveOrder() async {
    final provider = context.read<BikeProvider>();

    // Use the provider's reorderBikes method instead
    // Build a mapping of old to new positions
    final oldBikes = provider.getBikesSortedByOrder();

    for (int newIndex = 0; newIndex < _orderedBikes.length; newIndex++) {
      final bike = _orderedBikes[newIndex];
      final oldIndex = oldBikes.indexWhere((b) => b.id == bike.id);

      if (oldIndex != newIndex && oldIndex != -1) {
        // Update the bike with new displayOrder
        final updated = bike.copyWith(displayOrder: newIndex);
        await provider.updateBike(updated);
      }
    }

    try {
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
