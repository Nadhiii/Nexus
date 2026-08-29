import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexus_button.dart';
import 'nexus_card.dart';

/// Canonical recoverable or retryable inline error state.
class NexusErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool inCard;

  const NexusErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.inCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Semantics(
      container: true,
      liveRegion: true,
      label: 'Error: $message',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: AppSpacing.iconLg, color: scheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: scheme.error)),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            NexusButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: NexusButtonVariant.secondary,
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
