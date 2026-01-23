import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/swipe_to_delete.dart';

import '../widgets/bike_stats_widget.dart';
import '../widgets/add_bike_dialog.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/edit_entry_dialog.dart';
import '../widgets/fuel_price_widget.dart';
import '../widgets/vehicle_rc_card.dart';
import '../screens/garage_management_screen.dart';
import '../screens/deleted_bikes_screen.dart';

class ModernBikeScreen extends StatefulWidget {
  const ModernBikeScreen({super.key});

  @override
  State<ModernBikeScreen> createState() => _ModernBikeScreenState();
}

class _ModernBikeScreenState extends State<ModernBikeScreen> {
  double _currentFuelPrice = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BikeProvider>();
      provider.fetchBikes();
      final userId = provider.auth.currentUser?.uid;
      if (userId != null && provider.selectedBikeId != null) {
        provider.loadBikeEntries(userId, provider.selectedBikeId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        if (provider.selectedBikeId == null && provider.bikes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userId = provider.auth.currentUser?.uid;
            if (userId != null) provider.selectBike(provider.bikes.first.id);
          });
        }

        final selectedBike = provider.selectedBike;
        final isDashboardBike = selectedBike?.isDashboardBike ?? false;

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,
          floatingActionButton: selectedBike != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 90.0),
                  child: FloatingActionButton.extended(
                    onPressed: () =>
                        _showAddEntryDialog(context, _currentFuelPrice),
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white10),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Log Activity",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: AppColors.backgroundBlack,
                elevation: 0,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Garage',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                actions: [
                  if (selectedBike != null)
                    IconButton(
                      icon: Icon(
                        isDashboardBike
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isDashboardBike
                            ? Colors.amber
                            : AppColors.textTertiary,
                      ),
                      onPressed: () {
                        provider.setDashboardBike(selectedBike.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${selectedBike.name} is now on Dashboard',
                            ),
                          ),
                        );
                      },
                    ),
                  if (provider.bikes.length >= 2)
                    IconButton(
                      icon: const Icon(
                        Icons.sort_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => _navigateToGarageManagement(context),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white70,
                    ),
                    onPressed: () => _showAddBikeDialog(context),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (provider.bikes.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildBikeSelector(context, provider),
                  ),
                ),
                if (selectedBike != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          VehicleRCWidget(bike: selectedBike),
                          const SizedBox(height: 16),
                          BikeStatsWidget(provider: provider),
                        ],
                      ),
                    ),
                  ),
                if (selectedBike != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Updated Label: OLDEST FIRST
                          Text(
                            'TIMELINE (OLDEST FIRST)',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showFuelPriceSheet(context),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_gas_station,
                                  size: 14,
                                  color: AppColors.pastelGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Check Rates",
                                  style: TextStyle(
                                    color: AppColors.pastelGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selectedBike != null) _buildTimelineList(context, provider),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBikeSelector(BuildContext context, BikeProvider provider) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.bikes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bike = provider.bikes[index];
          final isSelected = provider.selectedBikeId == bike.id;
          return GestureDetector(
            onTap: () {
              provider.loadBikeEntries(provider.auth.currentUser!.uid, bike.id);
              provider.selectBike(bike.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                ),
              ),
              child: Text(
                bike.name,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context, BikeProvider provider) {
    // 1. Sort OLDEST FIRST (Ascending)
    final entries = List<BikeEntry>.from(provider.currentBikeEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              "No history yet",
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = entries[index];
          final isLast = index == entries.length - 1;
          final isFuel = (entry.category ?? 'fuel').toLowerCase() == 'fuel';
          final color = isFuel ? AppColors.primaryBlue : AppColors.pastelOrange;
          final icon = isFuel ? Icons.local_gas_station : Icons.build;

          // 2. Mileage Calculation for THIS CARD
          // Logic: (Current Odo - Previous Odo) / Current Fuel
          String mileageText = '';
          if (isFuel && entry.fuelQuantity > 0 && index > 0) {
            final prev = entries[index - 1]; // Previous entry in sorted list
            final dist = entry.odometerReading - prev.odometerReading;
            if (dist > 0) {
              final mileage = dist / entry.fuelQuantity;
              mileageText = '${mileage.toStringAsFixed(1)} km/L';
            }
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlack,
                        border: Border.all(color: color, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: Colors.white10),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: GestureDetector(
                      onTap: () =>
                          _showEditEntryDialog(context, provider, entry),
                      child: SwipeToDelete(
                        itemKey: ValueKey(entry.id),
                        itemId: entry.id,
                        itemName: "Entry",
                        onDelete: () => provider.deleteBikeEntry(entry.id),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.03),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${entry.date.day}/${entry.date.month}/${entry.date.year}",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, size: 16, color: color),
                                      const SizedBox(width: 8),
                                      Text(
                                        isFuel
                                            ? "Fuel Top-up"
                                            : (entry.category ?? 'EXPENSE')
                                                  .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // 3. SHOW TRIP MILEAGE
                                  if (mileageText.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: color.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        mileageText,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFuel
                                    ? "${entry.fuelQuantity} L  •  ${entry.odometerReading.toStringAsFixed(0)} km"
                                    : "Odometer: ${entry.odometerReading.toStringAsFixed(0)} km",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              if (entry.notes != null &&
                                  entry.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  entry.notes!,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
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
        }, childCount: entries.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text('No Vehicles Found', style: TextStyle(color: Colors.white)),
    );
  }

  void _navigateToGarageManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GarageManagementScreen()),
    );
  }

  void _showAddBikeDialog(BuildContext context) =>
      showDialog(context: context, builder: (_) => const AddBikeDialog());

  void _showAddEntryDialog(BuildContext context, double currentPrice) {
    final provider = context.read<BikeProvider>();
    if (provider.selectedBike == null) return;
    showDialog(
      context: context,
      builder: (_) => AddEntryDialog(
        bike: provider.selectedBike!,
        initialRate: currentPrice,
      ),
    );
  }

  void _showEditEntryDialog(
    BuildContext context,
    BikeProvider provider,
    BikeEntry entry,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditEntryDialog(entry: entry, provider: provider),
    );
  }

  void _showFuelPriceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelPriceWidget(
        onPriceSelected: (price) => setState(() => _currentFuelPrice = price),
      ),
    );
  }
}
