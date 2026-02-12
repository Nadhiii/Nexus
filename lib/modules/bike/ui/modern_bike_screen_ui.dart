import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

import '../widgets/bike_stats_widget.dart';
import '../widgets/add_bike_dialog.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/edit_entry_dialog.dart';
import '../widgets/fuel_price_widget.dart';
import '../widgets/vehicle_rc_card.dart';
import '../screens/garage_management_screen.dart';

class ModernBikeScreen extends StatefulWidget {
  const ModernBikeScreen({super.key});

  @override
  State<ModernBikeScreen> createState() => _ModernBikeScreenState();
}

class _ModernBikeScreenState extends State<ModernBikeScreen> {
  double _currentFuelPrice = 0.0;
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBikes();
    });
  }

  void _initializeBikes() {
    if (_initialized) return;
    _initialized = true;

    final provider = context.read<BikeProvider>();
    provider.fetchBikes();
    final userId = provider.auth.currentUser?.uid;
    if (userId != null && provider.selectedBikeId != null) {
      provider.loadBikeEntries(userId, provider.selectedBikeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        // Only select first bike once, not on every rebuild
        if (provider.selectedBikeId == null &&
            provider.bikes.isNotEmpty &&
            _initialized) {
          final userId = provider.auth.currentUser?.uid;
          if (userId != null) {
            // Use Future.microtask to avoid calling during build
            Future.microtask(() {
              if (mounted && provider.selectedBikeId == null) {
                provider.selectBike(provider.bikes.first.id);
              }
            });
          }
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
                      side: const BorderSide(color: Colors.white10),
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
                                const SizedBox(width: 4),
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
    // Sort entries by date DESCENDING (newest first for timeline display)
    final entries = List<BikeEntry>.from(provider.currentBikeEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) {
      return const SliverToBoxAdapter(
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

          // Mileage Calculation for THIS CARD
          // Logic: (Current Odo - Previous Entry Odo) / Current Fuel
          // Find the entry with the next lower odometer reading
          String mileageText = '';
          if (isFuel && entry.fuelQuantity > 0) {
            // Find previous entry (one with lower odometer reading)
            BikeEntry? prevEntry;
            for (var e in entries) {
              if (e.id != entry.id &&
                  e.odometerReading < entry.odometerReading) {
                if (prevEntry == null ||
                    e.odometerReading > prevEntry.odometerReading) {
                  prevEntry = e;
                }
              }
            }

            if (prevEntry != null) {
              final dist = entry.odometerReading - prevEntry.odometerReading;
              if (dist > 0) {
                final mileage = dist / entry.fuelQuantity;
                mileageText = '${mileage.toStringAsFixed(1)} km/L';
              }
            }
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlack,
                        border: Border.all(color: color, width: 2.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
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
                    // Note: SwipeToDelete removed due to crash with IntrinsicHeight in SliverList
                    // Use the delete button in edit dialog instead
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('Entry tapped: ${entry.id}');
                        _showEditEntryDialog(context, provider, entry);
                      },
                      onLongPress: () => _showDeleteConfirmation(
                        context,
                        provider,
                        entry,
                        isFuel,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.12),
                              AppColors.cardSurface,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${entry.date.day}/${entry.date.month}/${entry.date.year}",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "₹${entry.fuelAmount.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(icon, size: 16, color: color),
                                    ),
                                    const SizedBox(width: 10),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.2),
                                          color.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_gas_station,
                                  size: 12,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFuel
                                      ? "${entry.fuelQuantity} L"
                                      : "Service",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.speed,
                                  size: 12,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${entry.odometerReading.toStringAsFixed(0)} km",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
              ],
            ),
          );
        }, childCount: entries.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
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
    debugPrint('Opening edit screen for entry: ${entry.id}');
    showDialog(
      context: context,
      builder: (_) => EditEntryDialog(entry: entry),
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

  void _showDeleteConfirmation(
    BuildContext context,
    BikeProvider provider,
    BikeEntry entry,
    bool isFuel,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this ${isFuel ? "fuel" : "log"} entry?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteBikeEntry(entry.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
