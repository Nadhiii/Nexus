import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexus_button.dart';
import 'nexus_card.dart';

/// Canonical empty collection or first-use state.
class NexusEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool inCard;

  const NexusEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.inCard = true,
  }) : assert(primaryLabel == null || onPrimary != null),
       assert(secondaryLabel == null || onSecondary != null);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconLg, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(title, textAlign: TextAlign.center, style: AppTypography.titleMedium),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(message!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
          ],
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.controlGap,
              runSpacing: AppSpacing.controlGap,
              children: [
                if (primaryLabel != null)
                  NexusButton(label: primaryLabel, onPressed: onPrimary),
                if (secondaryLabel != null)
                  NexusButton(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                    variant: NexusButtonVariant.secondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return inCard
        ? NexusCard(padding: const EdgeInsets.all(AppSpacing.xl2), child: content)
        : Padding(padding: const EdgeInsets.all(AppSpacing.xl2), child: content);
  }
}
