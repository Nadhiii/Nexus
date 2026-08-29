import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Canonical initial or full-section loading state.
class NexusInitialLoading extends StatelessWidget {
  final String? message;

  const NexusInitialLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.contentGap),
              Text(message!, style: AppTypography.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
