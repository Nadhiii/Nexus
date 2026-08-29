import 'package:flutter/material.dart';
import '../theme/app_animations.dart'; // Adjust path based on your folder structure
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum NexusCardVariant { base, accent, hero, success, warning, error }

class NexusCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final NexusCardVariant variant;

  const NexusCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.borderRadius,
    this.border,
    this.variant = NexusCardVariant.base,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.cardColor;
    final effectiveRadius = borderRadius ?? AppSpacing.borderRadiusMd;
    final accent = switch (variant) {
      NexusCardVariant.accent => AppColors.primaryBlue,
      NexusCardVariant.hero => AppColors.pastelPurple,
      NexusCardVariant.success => AppColors.success,
      NexusCardVariant.warning => AppColors.warning,
      NexusCardVariant.error => AppColors.error,
      NexusCardVariant.base => null,
    };
    final effectiveBorder = border ?? (accent == null ? null : Border.all(color: accent.withValues(alpha: 0.34)));

    // AnimatedContainer ensures that any state changes (like color)
    // feel smooth and consistent across the app.
    return AnimatedContainer(
      duration: AppAnimations.interactionDuration,
      curve: AppAnimations.interactionCurve,
      decoration: BoxDecoration(
        color: variant == NexusCardVariant.hero ? null : effectiveColor,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        gradient: variant == NexusCardVariant.hero
            ? const LinearGradient(colors: [AppColors.nboxHeroStart, AppColors.nboxHeroEnd], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.borderSubtle,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding, // 20px padding
            child: child,
          ),
        ),
      ),
    );
  }
}
