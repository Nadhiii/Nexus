import 'package:flutter/material.dart';
import '../../../core/theme/app_animations.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/collapsible_fab.dart';
import '../../../core/widgets/top_snackbar.dart';

import '../widgets/bike_stats_widget.dart';
import '../widgets/add_bike.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/edit_entry_dialog.dart';
import '../widgets/fuel_price_widget.dart';
import '../widgets/vehicle_rc_card.dart';
import '../screens/garage_screen.dart';

class ModernBikeScreen extends StatefulWidget {
  const ModernBikeScreen({super.key});

  @override
  State<ModernBikeScreen> createState() => _ModernBikeScreenState();
}

class _ModernBikeScreenState extends State<ModernBikeScreen> {
  // Enhanced State for Filter & Sort
  String _sortOrder = 'Newest';
  String _filterCategory = 'All';
  String _filterTime = 'All Time';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _showAllLogs = false;

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
    if (_initialized) {
      return;
    }
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
        if (provider.selectedBikeId == null &&
            provider.bikes.isNotEmpty &&
            _initialized) {
          final userId = provider.auth.currentUser?.uid;
          if (userId != null) {
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
              ? CollapsibleFab(
                  onPressed: () =>
                      _showAddEntryDialog(context, _currentFuelPrice),
                  backgroundColor: AppColors.primaryBlue,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: 'Log Activity',
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
                        showTopSnackBar(
                          context,
                          '${selectedBike.name} is now on Dashboard',
                          icon: Icons.star_rounded,
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Redesigned Filter & Sort Chips
                              Row(
                                children: [
                                  _buildActionChip(
                                    icon: Icons.tune,
                                    label:
                                        _filterCategory == 'All' &&
                                            _filterTime == 'All Time'
                                        ? 'Filter'
                                        : 'Filtered',
                                    isActive:
                                        _filterCategory != 'All' ||
                                        _filterTime != 'All Time',
                                    onTap: () =>
                                        _showFilterSheet(context, provider),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionChip(
                                    icon: Icons.sort,
                                    label: _sortOrder,
                                    isActive: false,
                                    onTap: () => _showSortSheet(context),
                                  ),
                                ],
                              ),
                              // Check Rates button
                              GestureDetector(
                                onTap: () => _showFuelPriceSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pastelGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.pastelGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_gas_station,
                                        size: 14,
                                        color: AppColors.pastelGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Rates",
                                        style: TextStyle(
                                          color: AppColors.pastelGreen,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (_filterCategory != 'All' ||
                                    _filterTime != 'All Time')
                                ? 'FILTERED LOGS'
                                : (_showAllLogs
                                      ? 'ALL LOGS'
                                      : 'RECENT LOGS (Last 5)'),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selectedBike != null) _buildTimelineList(context, provider),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ), // Clears floating Nav Bar
              ],
            ],
          ),
        );
      },
    );
  }

  // --- NEW: UI Builders for Chips & Bottom Sheets ---

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primaryBlue.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primaryBlue : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primaryBlue : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort By',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRadioListTile('Newest First', 'Newest', _sortOrder, (val) {
                setState(() => _sortOrder = val.toString());
                Navigator.pop(ctx);
              }),
              _buildRadioListTile('Oldest First', 'Oldest', _sortOrder, (val) {
                setState(() => _sortOrder = val.toString());
                Navigator.pop(ctx);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioListTile(
    String title,
    String value,
    String groupValue,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = value == groupValue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => onChanged(value),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.primaryBlue : Colors.white54,
      ),
    );
  }

  void _showFilterSheet(BuildContext context, BikeProvider provider) {
    // 1. Extract dynamic categories from current entries
    final Set<String> uniqueCategories = {'All'};
    for (var entry in provider.currentBikeEntries) {
      if (entry.category != null && entry.category!.isNotEmpty) {
        String cat = entry.category!.toLowerCase();
        cat = cat.toUpperCase() + cat.substring(1); // Capitalize
        uniqueCategories.add(cat);
      }
    }
    final List<String> categories = uniqueCategories.toList();

    // Time filter options
    final List<String> timeOptions = [
      'All Time',
      '7 Days',
      '1 Month',
      '3 Months',
      '1 Year',
      'Custom',
    ];

    // Temporary state variables for the BottomSheet
    String tempCategory = _filterCategory;
    String tempTime = _filterTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCategory = 'All';
                            tempTime = 'All Time';
                            _customStartDate = null;
                            _customEndDate = null;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Section
                  Text(
                    'CATEGORY',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = tempCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => tempCategory = cat);
                          }
                        },
                        backgroundColor: AppColors.backgroundBlack,
                        selectedColor: AppColors.primaryBlue.withValues(
                          alpha: 0.2,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white70,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.5)
                              : Colors.white24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Time Section
                  Text(
                    'TIME RANGE',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeOptions.map((time) {
                      final isSelected = tempTime == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (selected) {
                            if (time == 'Custom') {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.primaryBlue,
                                        surface: AppColors.backgroundBlack,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  tempTime = time;
                                  _customStartDate = picked.start;
                                  _customEndDate = picked.end;
                                });
                              }
                            } else {
                              setModalState(() => tempTime = time);
                            }
                          }
                        },
                        backgroundColor: AppColors.backgroundBlack,
                        selectedColor: AppColors.primaryBlue.withValues(
                          alpha: 0.2,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white70,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.5)
                              : Colors.white24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),

                  if (tempTime == 'Custom' &&
                      _customStartDate != null &&
                      _customEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Selected: ${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _filterCategory = tempCategory;
                          _filterTime = tempTime;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- End of Filter UI Methods ---

  Widget _buildBikeSelector(BuildContext context, BikeProvider provider) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.bikes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bike = provider.bikes[index];
          final isSelected = provider.selectedBikeId == bike.id;
          return GestureDetector(
            onTap: () {
              provider.loadBikeEntries(provider.auth.currentUser!.uid, bike.id);
              provider.selectBike(bike.id);
            },
            child: AnimatedContainer(
              duration: AppAnimations.standard,
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
    List<BikeEntry> entries = List<BikeEntry>.from(provider.currentBikeEntries);

    // Apply Advanced Category Filters
    if (_filterCategory != 'All') {
      entries = entries.where((e) {
        final cat = (e.category ?? '').toLowerCase();
        return cat == _filterCategory.toLowerCase();
      }).toList();
    }

    // Apply Time Filters
    if (_filterTime != 'All Time') {
      final now = DateTime.now();
      entries = entries.where((e) {
        final diff = now.difference(e.date).inDays;
        switch (_filterTime) {
          case '7 Days':
            return diff <= 7;
          case '1 Month':
            return diff <= 30;
          case '3 Months':
            return diff <= 90;
          case '1 Year':
            return diff <= 365;
          case 'Custom':
            if (_customStartDate != null && _customEndDate != null) {
              return e.date.isAfter(
                    _customStartDate!.subtract(const Duration(days: 1)),
                  ) &&
                  e.date.isBefore(_customEndDate!.add(const Duration(days: 1)));
            }
            return true;
          default:
            return true;
        }
      }).toList();
    }

    // Apply Sort
    if (_sortOrder == 'Newest') {
      entries.sort((a, b) => b.date.compareTo(a.date));
    } else {
      entries.sort((a, b) => a.date.compareTo(b.date));
    }

    // --- NEW LIMITING LOGIC ---
    bool isFiltering = _filterCategory != 'All' || _filterTime != 'All Time';
    bool hasMore = false;

    // Only limit to 5 if we are NOT filtering and NOT showing all logs
    if (!isFiltering && !_showAllLogs && entries.length > 5) {
      hasMore = true;
      entries = entries.take(5).toList();
    }

    // Check if we should show a "Show Less" button
    bool canCollapse =
        !isFiltering && _showAllLogs && provider.currentBikeEntries.length > 5;

    if (entries.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              "No history matches your filters",
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Render the "View All" or "Show Less" button at the very end of the list
          if (index == entries.length) {
            if (hasMore) {
              return TextButton(
                onPressed: () => setState(() => _showAllLogs = true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All History',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primaryBlue,
                      size: 18,
                    ),
                  ],
                ),
              );
            } else if (canCollapse) {
              return TextButton(
                onPressed: () => setState(() => _showAllLogs = false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Show Less',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final entry = entries[index];
          final isLast =
              index == entries.length - 1 && !(hasMore || canCollapse);
          final isFuel = (entry.category ?? 'fuel').toLowerCase() == 'fuel';
          final color = isFuel ? AppColors.primaryBlue : AppColors.pastelOrange;
          final icon = isFuel ? Icons.local_gas_station : Icons.build;

          String mileageText = '';
          if (isFuel) {
            final mileage = provider.getMileageForEntry(entry.id);
            if (mileage != null && mileage > 0) {
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
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBlack,
                        border: Border.all(color: color, width: 2.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
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
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
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
                              color.withValues(alpha: 0.12),
                              AppColors.cardSurface,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.08),
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
                                        color: color.withValues(alpha: 0.15),
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
                                if (mileageText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withValues(alpha: 0.2),
                                          color.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.3),
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
                                const Icon(
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
                                const Icon(
                                  Icons.speed,
                                  size: 12,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${entry.odometerReading.toStringAsFixed(1)} km",
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
        }, childCount: entries.length + ((hasMore || canCollapse) ? 1 : 0)),
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
      showDialog(context: context, builder: (_) => ModernAddBikeScreen());

  void _showAddEntryDialog(BuildContext context, double currentPrice) {
    final provider = context.read<BikeProvider>();
    if (provider.selectedBike == null) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryDialog(
          bike: provider.selectedBike!,
          initialRate: currentPrice,
        ),
      ),
    );
  }

  void _showEditEntryDialog(
    BuildContext context,
    BikeProvider provider,
    BikeEntry entry,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEntryDialog(entry: entry)),
    );
  }

  void _showFuelPriceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
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
              showTopSnackBar(
                context,
                'Entry deleted',
                isError: true,
                icon: Icons.delete_outline_rounded,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}