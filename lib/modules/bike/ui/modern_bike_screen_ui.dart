import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/swipe_to_delete.dart';

// Dialogs & Widgets
import '../widgets/bike_stats_widget.dart';
import '../widgets/add_bike_dialog.dart';
import '../widgets/add_entry_dialog.dart';
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
    // 1. FETCH BIKES ON LOAD
    // This tells the provider to actually go get the data from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BikeProvider>();
      provider.fetchBikes();
      
      // 2. If there's a selected bike, ensure entries are loaded
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
        // 2. AUTO-SELECT LOGIC
        // If we have bikes but none selected, select the first one automatically
        if (provider.selectedBikeId == null && provider.bikes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userId = provider.auth.currentUser?.uid;
            if (userId != null) {
              // Use selectBike instead of setDashboardBike to ensure entries load
              provider.selectBike(provider.bikes.first.id);
            }
          });
        }

        final selectedBike = provider.selectedBike;
        final isDashboardBike = selectedBike?.isDashboardBike ?? false;

        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,

          // FAB
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
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
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
              // --- HEADER ---
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Garage',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                actions: [
                  // 3. EASY FAVORITE (STAR) BUTTON
                  if (selectedBike != null)
                    IconButton(
                      icon: Icon(
                        isDashboardBike
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isDashboardBike
                            ? Colors.amber
                            : AppColors.textTertiary,
                        size: 28,
                      ),
                      tooltip: isDashboardBike
                          ? 'Dashboard Vehicle'
                          : 'Set as Dashboard Vehicle',
                      onPressed: isDashboardBike
                          ? null
                          : () {
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

                  // MANAGE BUTTON (Only if 2+ bikes)
                  if (provider.bikes.length >= 2)
                    IconButton(
                      icon: const Icon(
                        Icons.sort_rounded,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Rearrange Vehicles',
                      onPressed: () => _navigateToGarageManagement(context),
                    ),

                  // VIEW DELETED BUTTON (Only if deleted bikes exist)
                  if (provider.deletedBikes.isNotEmpty)
                    IconButton(
                      icon: Badge(
                        label: Text('${provider.deletedBikes.length}'),
                        child: const Icon(
                          Icons.restore_from_trash_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      tooltip: 'View Deleted Vehicles',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeletedBikesScreen(),
                          ),
                        );
                      },
                    ),

                  // ADD BUTTON
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Add New Vehicle',
                    onPressed: () => _showAddBikeDialog(context),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              if (provider.bikes.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else ...[
                // BIKE TABS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildBikeSelector(context, provider),
                  ),
                ),

                // DASHBOARD AREA
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

                // TIMELINE HEADER
                if (selectedBike != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TIMELINE',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 1.5,
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
                                const SizedBox(width: 4),
                                Text(
                                  "Check Rates",
                                  style: TextStyle(
                                    color: AppColors.pastelGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // TIMELINE LIST
                if (selectedBike != null) _buildTimelineList(context, provider),

                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

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
              // Load data for the selected bike
              provider.loadBikeEntries(provider.auth.currentUser!.uid, bike.id);
              // Also set it as the "Selected" bike in UI (separate from Dashboard bike)
              provider.selectBike(bike.id);
            },
            onLongPress: () => _showBikeOptions(context, provider, bike),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textTertiary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  if (bike.isDashboardBike) ...[
                    Icon(
                      Icons.star,
                      size: 12,
                      color: isSelected
                          ? AppColors.backgroundBlack
                          : Colors.amber,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    bike.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.backgroundBlack
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (Keep _buildTimelineList, _buildEmptyState, and Actions exactly as they are) ...
  // Paste the rest of the helper methods from your previous file here:
  // _buildTimelineList, _buildEmptyState, _showAddBikeDialog, _showAddEntryDialog, _showFuelPriceSheet, _showBikeOptions

  // NOTE: Ensure _navigateToGarageManagement is defined:
  void _navigateToGarageManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GarageManagementScreen()),
    );
  }

  // --- ACTIONS ---
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

  void _showFuelPriceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelPriceWidget(
        onPriceSelected: (price) {
          setState(() => _currentFuelPrice = price);
        },
      ),
    );
  }

  void _showBikeOptions(BuildContext context, BikeProvider provider, bike) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundBlack,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
              title: const Text(
                'Edit Vehicle',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AddBikeDialog(bikeToEdit: bike),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete Vehicle',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.deleteBike(bike.id);
              },
            ),
            if (provider.deletedBikes.isNotEmpty)
              ListTile(
                leading: const Icon(
                  Icons.restore_from_trash,
                  color: AppColors.primaryBlue,
                ),
                title: Text(
                  'View Deleted Vehicles (${provider.deletedBikes.length})',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeletedBikesScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ... (Include _buildTimelineList implementation here) ...
  Widget _buildTimelineList(BuildContext context, BikeProvider provider) {
    final entries = provider.currentBikeEntries;

    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 48,
                color: AppColors.textTertiary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "No history yet",
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ],
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
                        child: Container(
                          width: 2,
                          color: AppColors.textTertiary.withOpacity(0.1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${entry.date.day}/${entry.date.month}/${entry.date.year}",
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  "₹${entry.fuelAmount.toStringAsFixed(0)}",
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(icon, size: 16, color: color),
                                const SizedBox(width: 8),
                                Text(
                                  isFuel
                                      ? "Fuel Top-up"
                                      : (entry.category ?? 'Expense')
                                            .toUpperCase(),
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isFuel
                                  ? "${entry.fuelQuantity} Litres  •  ${entry.odometerReading.toStringAsFixed(0)} km"
                                  : "Odometer: ${entry.odometerReading.toStringAsFixed(0)} km",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (entry.notes != null &&
                                entry.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                entry.notes!,
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
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
              ],
            ),
          );
        }, childCount: entries.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.two_wheeler,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text('No Vehicles Found', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showAddBikeDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Your First Bike'),
          ),
        ],
      ),
    );
  }
}
