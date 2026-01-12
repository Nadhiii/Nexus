import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class QuickBikeEntryUI {
  /// Build the main container with the new "Dark Slate" look
  static Widget buildContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface, // Dark Blue-Grey
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd), // 12px
        border: Border.all(
          color: Colors.white.withOpacity(0.05), // Subtle highlight border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Build header section
  static Widget buildHeader({
    required String bikeName,
    required String mileage,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Vehicle',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bikeName,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Mileage Badge (Pastel Teal)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pastelTeal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm), // Squared
            border: Border.all(color: AppColors.pastelTeal.withOpacity(0.3)),
          ),
          child: Text(
            mileage,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.pastelTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Build action buttons row
  static Widget buildActionButtons({
    required VoidCallback onAddFuel,
    required VoidCallback onAddTrip,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAddFuel,
            icon: const Icon(Icons.local_gas_station_outlined, size: 20),
            label: const Text('Add Fuel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              textStyle: AppTypography.labelLarge,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddTrip,
            icon: const Icon(Icons.directions_car_outlined, size: 20),
            label: const Text('Add Trip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pastelTeal,
              side: const BorderSide(color: AppColors.pastelTeal),
              minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              textStyle: AppTypography.labelLarge,
            ),
          ),
        ),
      ],
    );
  }

  /// Build last fill-up info card
  static Widget buildLastFillupInfo({
    required int daysSince,
    required double fuelCost,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardElevated, // Slightly lighter than background
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Last Fill-up: $daysSince days ago',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            '₹${fuelCost.toStringAsFixed(0)}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
