import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart'; // <-- Added import to fix the typing crash
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';


class GarageDashboardWidget extends StatelessWidget {

  final VoidCallback? onOpenGarage;

  const GarageDashboardWidget({super.key, this.onOpenGarage});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        final bike = provider.dashboardDisplayBike;

        if (bike == null) {
          return _EmptyGarageCard(onOpenGarage: onOpenGarage);
        }

        // ΓöÇΓöÇ Derived stats ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
        final fuelEntries = provider.dashboardBikeEntries
            .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
            .toList();

        final double latestOdo = fuelEntries.isNotEmpty
            ? fuelEntries
                  .reduce(
                    (a, b) => a.odometerReading > b.odometerReading ? a : b,
                  )
                  .odometerReading
            : 0;

        final double totalCost = fuelEntries.fold(
          0.0,
          (sum, e) => sum + e.fuelAmount,
        );

        final double mileage = provider.getDashboardReliableAverageMileage();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ΓöÇΓöÇ Header ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: AppSpacing.borderRadiusXs,
                          ),
                          child: Icon(
                            Icons.two_wheeler_rounded,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.controlGap),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GARAGE',
                              style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2),
                            ),
                            Text(
                              bike.name,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: AppTypography.titleSmall.fontWeight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Open button ΓÇö uses callback instead of Navigator.push
                    GestureDetector(
                      onTap: onOpenGarage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: AppSpacing.borderRadiusXs,
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Text(
                          'Open',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: AppTypography.labelMedium.fontSize,
                            fontWeight: AppTypography.labelMedium.fontWeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.contentGap),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: AppSpacing.contentGap),

              // ΓöÇΓöÇ Stats row ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Row(
                  children: [
                    _StatCell(
                      label: 'MILEAGE',
                      value: mileage > 0 ? mileage.toStringAsFixed(1) : '--',
                      unit: 'km/L',
                      color: AppColors.primaryBlue,
                      icon: Icons.speed_rounded,
                    ),
                    _vDivider(),
                    _StatCell(
                      label: 'ODOMETER',
                      value: latestOdo > 0 ? _formatOdo(latestOdo) : '--',
                      unit: 'km',
                      color: AppColors.pastelGreen,
                      icon: Icons.route_rounded,
                    ),
                    _vDivider(),
                    _StatCell(
                      label: 'FUEL COST',
                      value: totalCost > 0
                          ? 'Γé╣${_formatCost(totalCost)}'
                          : '--',
                      unit: 'total',
                      color: AppColors.pastelOrange,
                      icon: Icons.local_gas_station_rounded,
                    ),
                  ],
                ),
              ),

              // ΓöÇΓöÇ Last fill chip ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              if (fuelEntries.isNotEmpty) ...[
                _LastFillBanner(provider: provider, fuelEntries: fuelEntries),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: AppSpacing.xl3,
    color: Colors.white.withValues(alpha: 0.06),
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
  );

  String _formatOdo(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  String _formatCost(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Last fill banner
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _LastFillBanner extends StatelessWidget {
  final BikeProvider provider;
  final List<BikeEntry>
  fuelEntries; // <-- FIXED: Was dynamic, now strongly typed

  const _LastFillBanner({required this.provider, required this.fuelEntries});

  @override
  Widget build(BuildContext context) {
    // Most recent entry by date
    final last = fuelEntries.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    final daysAgo = DateTime.now().difference(last.date).inDays;
    final daysLabel = daysAgo == 0
        ? 'today'
        : daysAgo == 1
        ? 'yesterday'
        : '$daysAgo days ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusMd)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Last fill: ${last.odometerReading.toStringAsFixed(0)} km  ┬╖  ${last.fuelQuantity.toStringAsFixed(1)} L  ┬╖  $daysLabel',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Stat cell
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(icon, size: 14, color: color),
          const SizedBox(height: AppSpacing.xs),
          // Value + unit
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1,
              ),
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Empty state
// ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

class _EmptyGarageCard extends StatelessWidget {
  final VoidCallback? onOpenGarage;
  const _EmptyGarageCard({this.onOpenGarage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenGarage,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              color: AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No bike added yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.titleSmall.fontWeight,
                  ),
                ),
                Text(
                  'Tap to open Garage',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
