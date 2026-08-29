import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexus_card.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String trend;
  final bool trendPositive;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trend,
    required this.trendPositive,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      onTap: onTap,
      variant: trendPositive ? NexusCardVariant.success : NexusCardVariant.error,
      padding: AppSpacing.cardPaddingMd,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (trendPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.14),
              borderRadius: AppSpacing.borderRadiusXs,
            ),
            child: Icon(icon, color: trendPositive ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Text(value, style: AppTypography.currencyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(trendPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: trendPositive ? AppColors.success : AppColors.error),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(child: Text(trend, style: AppTypography.labelSmall.copyWith(color: trendPositive ? AppColors.success : AppColors.error), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
