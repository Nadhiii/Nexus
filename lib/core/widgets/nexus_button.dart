import 'package:flutter/material.dart';
import '../theme/app_animations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum NexusButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive,
  compact,
  icon,
}

/// Canonical Nexus action primitive. Use semantic variants instead of styling
/// buttons independently in feature screens.
class NexusButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final Widget? icon;
  final NexusButtonVariant variant;
  final bool isLoading;
  final String? tooltip;
  final bool emphasizedPrimary;
  final double? width;

  const NexusButton({
    super.key,
    this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.variant = NexusButtonVariant.primary,
    this.isLoading = false,
    this.tooltip,
    this.emphasizedPrimary = false,
    this.width,
  }) : assert(child != null || label != null || icon != null),
       assert(
         variant != NexusButtonVariant.icon ||
             (icon != null && tooltip != null && tooltip != ''),
         'Icon buttons require an icon and an accessible tooltip.',
       );

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    final accessibleButton = isLoading
        ? Semantics(
            label: label ?? 'Loading',
            button: true,
            enabled: false,
            liveRegion: true,
            child: button,
          )
        : button;
    final sizedButton = width == null
        ? accessibleButton
        : SizedBox(width: width, child: accessibleButton);
    return tooltip == null
        ? sizedButton
        : Tooltip(message: tooltip!, child: sizedButton);
  }

  Widget _buildButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = isLoading
        ? const SizedBox(
            width: AppSpacing.iconSm,
            height: AppSpacing.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon!,
              if (icon != null && (label != null || child != null))
                const SizedBox(width: AppSpacing.controlGap),
              if (child != null) child! else if (label != null) Text(label!),
            ],
          );

    if (variant == NexusButtonVariant.icon) {
      return IconButton(
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        icon: icon!,
        color: colorScheme.onSurface,
      );
    }

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size.fromHeight(
          variant == NexusButtonVariant.compact
              ? AppSpacing.buttonHeightSm
              : AppSpacing.buttonHeightMd,
        ),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
          horizontal: variant == NexusButtonVariant.compact
              ? AppSpacing.lg
              : AppSpacing.xl2,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),
      textStyle: WidgetStateProperty.all(AppTypography.controlLabel),
      animationDuration: AppAnimations.interactionDuration,
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    switch (variant) {
      case NexusButtonVariant.primary:
        final primaryButton = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.all(
              emphasizedPrimary ? Colors.transparent : colorScheme.primary,
            ),
            foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
          ),
          child: content,
        );
        return emphasizedPrimary
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.blueGradient),
                  borderRadius: AppSpacing.borderRadiusSm,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: primaryButton,
              )
            : primaryButton;
      case NexusButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style.copyWith(
            foregroundColor: WidgetStateProperty.all(colorScheme.onSurface),
            side: WidgetStateProperty.all(
              BorderSide(color: colorScheme.outline),
            ),
          ),
          child: content,
        );
      case NexusButtonVariant.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style.copyWith(
            foregroundColor: WidgetStateProperty.all(colorScheme.onSurfaceVariant),
          ),
          child: content,
        );
      case NexusButtonVariant.destructive:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.all(colorScheme.error),
            foregroundColor: WidgetStateProperty.all(colorScheme.onError),
          ),
          child: content,
        );
      case NexusButtonVariant.compact:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
            foregroundColor: WidgetStateProperty.all(colorScheme.onSurface),
          ),
          child: content,
        );
      case NexusButtonVariant.icon:
        throw StateError('Icon variant is handled above');
    }
  }
}
