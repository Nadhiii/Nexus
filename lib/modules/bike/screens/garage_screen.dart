import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bike_image_utils.dart';

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
    _orderedBikes = List.from(
      context.read<BikeProvider>().getBikesSortedByOrder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('Manage Garage', style: AppTypography.headlineMedium),
            ),
            actions: [
              if (_hasChanges)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: TextButton.icon(
                    onPressed: _saveOrder,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          _orderedBikes.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No vehicles to manage",
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverReorderableList(
                    itemCount: _orderedBikes.length,
                    itemBuilder: (context, index) =>
                        _buildListTile(_orderedBikes[index], index),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final Bike item = _orderedBikes.removeAt(oldIndex);
                        _orderedBikes.insert(newIndex, item);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildListTile(Bike bike, int index) {
    final imagePath = BikeImageUtils.getBikeImagePath(
      bike.image,
      bike.name,
      bike.model,
    );
    final hasImage = imagePath != null;

    // Moving the key to a wrapping Padding widget handles reorder gaps much better
    return Padding(
      key: ValueKey(bike.id),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent, // Ensures dragged item looks correct
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardDarkElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: bike.isDashboardBike
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              if (hasImage)
                Positioned.fill(
                  // Replaced hard-coded negative offsets with Positioned.fill + Alignment
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: 150, // Constrain the image width directly here
                      ),
                    ),
                  ),
                ),
              ListTile(
                // Removed default content margins that can cause internal gaps
                dense: true,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bike.isDashboardBike
                        ? Colors.amber.withOpacity(0.1)
                        : AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    bike.isDashboardBike ? Icons.star : Icons.two_wheeler,
                    color: bike.isDashboardBike
                        ? Colors.amber
                        : AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                title: Text(
                  bike.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${bike.make} ${bike.model}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.drag_indicator,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    final provider = context.read<BikeProvider>();
    final oldBikes = provider.getBikesSortedByOrder();

    for (int newIndex = 0; newIndex < _orderedBikes.length; newIndex++) {
      final bike = _orderedBikes[newIndex];
      final oldIndex = oldBikes.indexWhere((b) => b.id == bike.id);
      if (oldIndex != newIndex && oldIndex != -1) {
        await provider.updateBike(bike.copyWith(displayOrder: newIndex));
      }
    }

    if (mounted) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order saved successfully')));
    }
  }
}
