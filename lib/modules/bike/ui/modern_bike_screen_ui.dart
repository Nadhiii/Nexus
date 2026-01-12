import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/swipe_to_delete.dart';

// Dialogs & Widgets
import '../widgets/bike_stats_widget.dart';
import '../widgets/add_bike_dialog.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/fuel_price_widget.dart';
import '../widgets/vehicle_rc_card.dart';

class ModernBikeScreen extends StatefulWidget {
  const ModernBikeScreen({super.key});

  @override
  State<ModernBikeScreen> createState() => _ModernBikeScreenState();
}

class _ModernBikeScreenState extends State<ModernBikeScreen> {
  // Store the fetched price to use in the "Add Fuel" dialog
  double _currentFuelPrice = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundBlack,

          // --- 1. FLOATING ACTION BUTTON (Fixed Height) ---
          floatingActionButton: provider.selectedBike != null
              ? Padding(
                  // Lift FAB above the Bottom Navigation Bar
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
              // --- 2. HEADER ---
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
                // --- 3. BIKE TABS (Pills) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildBikeSelector(context, provider),
                  ),
                ),

                // --- 4. DASHBOARD AREA (Card + Stats) ---
                if (provider.selectedBike != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Digital RC Card
                          VehicleRCWidget(bike: provider.selectedBike!),
                          const SizedBox(height: 16),
                          // Stats Grid
                          BikeStatsWidget(provider: provider),
                        ],
                      ),
                    ),
                  ),

                // --- 5. TIMELINE HEADER ---
                if (provider.selectedBike != null)
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
                          // Small Fuel Price Indicator
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

                // --- 6. TIMELINE LIST ---
                if (provider.selectedBike != null)
                  _buildTimelineList(context, provider),

                // Bottom Padding to ensure last item is visible behind FAB
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
            onTap: () => provider.loadBikeEntries(
              provider.auth.currentUser!.uid,
              bike.id,
            ),
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
              child: Text(
                bike.name,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.backgroundBlack
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

          // Logic
          final isFuel = (entry.category ?? 'fuel').toLowerCase() == 'fuel';
          final isService = [
            'maintenance',
            'repair',
          ].contains((entry.category ?? '').toLowerCase());

          final color = isFuel
              ? AppColors.primaryBlue
              : (isService ? AppColors.pastelOrange : AppColors.textSecondary);
          final icon = isFuel
              ? Icons.local_gas_station
              : (isService ? Icons.build : Icons.description);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Timeline Line & Dot
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

                // 2. Content Card
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
                            // Header: Date & Cost
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

                            // Main Info
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

                            // Details (Odo / Litres)
                            const SizedBox(height: 6),
                            Text(
                              isFuel
                                  ? "${entry.fuelQuantity} Litres  •  ${entry.odometerReading.toStringAsFixed(0)} km"
                                  : "Odometer: ${entry.odometerReading.toStringAsFixed(0)} km",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),

                            // Notes (if any)
                            if (entry.notes != null &&
                                entry.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundBlack,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  entry.notes!,
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
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

  // --- ACTIONS ---

  void _showAddBikeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddBikeDialog());
  }

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

  // Put the heavy Fuel Widget in a Bottom Sheet to keep UI clean
  void _showFuelPriceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundBlack,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            FuelPriceWidget(
              onPriceSelected: (price) {
                setState(() => _currentFuelPrice = price);
                // Optional: Close sheet on selection or keep open
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showBikeOptions(BuildContext context, BikeProvider provider, bike) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryBlue),
              title: Text(
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
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'Delete Vehicle',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.deleteBike(bike.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
