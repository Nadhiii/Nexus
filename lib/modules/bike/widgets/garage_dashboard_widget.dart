import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Dashboard-level garage card.
/// Shows the active bike's live stats (mileage, odometer, fuel cost).
/// Tapping "Open" switches to the Garage tab via [onNavigate] instead of
/// pushing a new route, so the user lands on the same screen as the nav-bar.
class GarageDashboardWidget extends StatelessWidget {
  /// Callback wired up in ModernDashboardScreen to switch the bottom-nav
  /// index to the Garage tab (pass the index your app uses, e.g. 2).
  final VoidCallback? onOpenGarage;

  const GarageDashboardWidget({super.key, this.onOpenGarage});

  @override
  Widget build(BuildContext context) {
    return Consumer<BikeProvider>(
      builder: (context, provider, _) {
        final bike = provider.currentBike;

        if (bike == null) {
          return _EmptyGarageCard(onOpenGarage: onOpenGarage);
        }

        // ── Derived stats ──────────────────────────────────────────────
        final fuelEntries = provider.currentBikeEntries
            .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
            .toList();

        final double latestOdo = fuelEntries.isNotEmpty
            ? fuelEntries
                .reduce((a, b) =>
                    a.odometerReading > b.odometerReading ? a : b)
                .odometerReading
            : 0;

        final double totalCost = fuelEntries.fold(
          0.0,
          (sum, e) => sum + e.fuelAmount,
        );

        final double mileage = provider.getReliableAverageMileage();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.two_wheeler_rounded,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GARAGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              bike.name,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Open button — uses callback instead of Navigator.push
                    GestureDetector(
                      onTap: onOpenGarage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'Open',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 12),

              // ── Stats row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _StatCell(
                      label: 'MILEAGE',
                      value: mileage > 0
                          ? mileage.toStringAsFixed(1)
                          : '--',
                      unit: 'km/L',
                      color: AppColors.primaryBlue,
                      icon: Icons.speed_rounded,
                    ),
                    _vDivider(),
                    _StatCell(
                      label: 'ODOMETER',
                      value: latestOdo > 0
                          ? _formatOdo(latestOdo)
                          : '--',
                      unit: 'km',
                      color: AppColors.pastelGreen,
                      icon: Icons.route_rounded,
                    ),
                    _vDivider(),
                    _StatCell(
                      label: 'FUEL COST',
                      value: totalCost > 0
                          ? '₹${_formatCost(totalCost)}'
                          : '--',
                      unit: 'total',
                      color: AppColors.pastelOrange,
                      icon: Icons.local_gas_station_rounded,
                    ),
                  ],
                ),
              ),

              // ── Last fill chip ────────────────────────────────────────
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
        height: 44,
        color: Colors.white.withValues(alpha: 0.06),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  String _formatOdo(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  String _formatCost(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Last fill banner
// ─────────────────────────────────────────────────────────────────────────────

class _LastFillBanner extends StatelessWidget {
  final BikeProvider provider;
  final List<dynamic> fuelEntries;
  const _LastFillBanner(
      {required this.provider, required this.fuelEntries});

  @override
  Widget build(BuildContext context) {
    // Most recent entry by date
    final last = fuelEntries.reduce(
        (a, b) => a.date.isAfter(b.date) ? a : b);
    final daysAgo = DateTime.now().difference(last.date).inDays;
    final daysLabel = daysAgo == 0
        ? 'today'
        : daysAgo == 1
            ? 'yesterday'
            : '$daysAgo days ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 13,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            'Last fill: ${last.odometerReading.toStringAsFixed(0)} km  ·  ${last.fuelQuantity.toStringAsFixed(1)} L  ·  $daysLabel',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat cell
// ─────────────────────────────────────────────────────────────────────────────

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
          const SizedBox(height: 4),
          // Value + unit
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyGarageCard extends StatelessWidget {
  final VoidCallback? onOpenGarage;
  const _EmptyGarageCard({this.onOpenGarage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenGarage,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              color: AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No bike added yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to open Garage',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}