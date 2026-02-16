import 'package:flutter/material.dart';
import '../theme/app_animations.dart'; // Adjust path based on your folder structure
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NexusCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const NexusCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedContainer ensures that any state changes (like color)
    // feel smooth and consistent across the app.
    return AnimatedContainer(
      duration: AppAnimations.standard, // 200ms reaction
      curve: AppAnimations.standardCurve, // easeOutCubic
      decoration: BoxDecoration(
        color: color ?? AppColors.cardSurface, // #1E293B
        borderRadius: AppSpacing.borderRadiusMd, // 24px Radius
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          splashColor: AppColors.white12,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding, // 20px padding
            child: child,
          ),
        ),
      ),
    );
  }
}
