import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Compact loading indicator for a row, card, or localized operation.
class NexusInlineLoading extends StatelessWidget {
  final String? label;
  final double size;

  const NexusInlineLoading({super.key, this.label, this.size = AppSpacing.iconSm});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: scheme.primary,
        strokeWidth: 2,
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      label: label ?? 'Loading',
      child: label == null
          ? indicator
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [indicator, const SizedBox(width: AppSpacing.controlGap), Text(label!)],
            ),
    );
  }
}
