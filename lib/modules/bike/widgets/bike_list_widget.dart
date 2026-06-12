import 'package:flutter/material.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/bike.dart';
import '../../../core/models/trip.dart';
import 'edit_entry_dialog.dart';
import '../../../core/widgets/swipe_to_delete.dart';

class BikeListWidget extends StatelessWidget {
  final BikeProvider provider;

  const BikeListWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final allActivities = _getCombinedActivities(provider);

    if (allActivities.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No recent activity',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TIMELINE (OLDEST FIRST)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          );
        }

        final activityIndex = index - 1;
        final activity = allActivities[activityIndex];
        final isLast = index == allActivities.length;

        // Get previous activity for dynamic distance calc if needed
        _ActivityWrapper? prevActivity;
        if (activityIndex > 0) {
          prevActivity = allActivities[activityIndex - 1];
        }

        if (activity.type == _ActivityType.entry) {
          return _buildEntryItem(
            context,
            activity.entry!,
            isLast,
            prevActivity?.entry,
          );
        } else {
          return _buildTripItem(context, activity.trip!, isLast);
        }
      }, childCount: allActivities.length + 1),
    );
  }

  List<_ActivityWrapper> _getCombinedActivities(BikeProvider provider) {
    List<_ActivityWrapper> activities = [];
    for (var entry in provider.currentBikeEntries) {
      activities.add(
        _ActivityWrapper(
          date: entry.date,
          type: _ActivityType.entry,
          entry: entry,
        ),
      );
    }
    for (var trip in provider.currentTrips) {
      activities.add(
        _ActivityWrapper(date: trip.date, type: _ActivityType.trip, trip: trip),
      );
    }
    // CHANGED: Sort a.compareTo(b) for Oldest First
    activities.sort((a, b) => a.date.compareTo(b.date));
    return activities;
  }

  Widget _buildEntryItem(
    BuildContext context,
    BikeEntry entry,
    bool isLast,
    BikeEntry? prevEntry,
  ) {
    final isFuel = (entry.category ?? 'fuel').toLowerCase() == 'fuel';
    final color = isFuel ? AppColors.primaryBlue : AppColors.pastelOrange;

    // Reliable Mileage (Full Tank -> Full Tank method)
    String mileageDisplay = '-';
    if (isFuel) {
      final mileage = provider.getMileageForEntry(entry.id);
      if (mileage != null && mileage > 0) {
        mileageDisplay = mileage.toStringAsFixed(1);
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16),
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.cardSurface),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 20),
              child: SwipeToDelete(
                itemKey: ValueKey(entry.id),
                itemId: entry.id,
                itemName: "Entry",
                onDelete: () => provider.deleteBikeEntry(entry.id),
                child: GestureDetector(
                  onTap: () => _showEditEntryDialog(context, entry),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isFuel
                                  ? "FUEL TOP-UP"
                                  : (entry.category ?? "EXPENSE").toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "₹${entry.fuelAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${entry.odometerReading.toStringAsFixed(1)} km",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isFuel && mileageDisplay != '-')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundBlack,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withValues(alpha: 
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "$mileageDisplay km/L",
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFuel
                              ? "${entry.fuelQuantity} Litres @ ₹${(entry.fuelAmount / entry.fuelQuantity).toStringAsFixed(2)}/L"
                              : entry.notes ?? "",
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem(BuildContext context, Trip trip, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16),
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.cardSurface),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Trip Recorded",
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    Text(
                      "${trip.distanceKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEntryDialog(BuildContext context, BikeEntry entry) {
    showDialog(
      context: context,
      builder: (_) => EditEntryDialog(entry: entry),
    );
  }
}

enum _ActivityType { entry, trip }

class _ActivityWrapper {
  final DateTime date;
  final _ActivityType type;
  final BikeEntry? entry;
  final Trip? trip;
  _ActivityWrapper({
    required this.date,
    required this.type,
    this.entry,
    this.trip,
  });
}