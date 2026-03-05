import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

/// Shows a custom drop-down notification from the top of the screen.
///
/// [message] is the text to display.
/// Set [isError] to true to display the error variant (e.g., with a red background).
/// [icon] optional custom icon to display.
/// [backgroundColor] optional custom background color.
/// [action] optional action button with label and callback.
/// [duration] how long to show (default 3 seconds).
void showTopSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData? icon,
  Color? backgroundColor,
  TopSnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  // Safety check: ensure context is still valid and mounted
  if (!context.mounted) {
    debugPrint('showTopSnackBar: Context not mounted, skipping snackbar');
    return;
  }

  OverlayState? overlay;
  try {
    overlay = Overlay.of(context, rootOverlay: true);
  } catch (e) {
    debugPrint('showTopSnackBar: Could not get overlay - $e');
    return;
  }

  final key = GlobalKey<TopSnackBarState>();
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => TopSnackBar(
      key: key,
      message: message,
      isError: isError,
      icon: icon,
      backgroundColor: backgroundColor,
      action: action,
      onDismissed: () {
        overlayEntry?.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-dismiss after duration
  Future.delayed(duration, () {
    key.currentState?.reverseAnimation();
  });
}

/// Data class for snackbar action button
class TopSnackBarAction {
  final String label;
  final VoidCallback onPressed;

  const TopSnackBarAction({required this.label, required this.onPressed});
}

/// A widget that displays a drop-down notification from the top.
/// This widget is intended to be used via the [showTopSnackBar] function.
class TopSnackBar extends StatefulWidget {
  final String message;
  final bool isError;
  final IconData? icon;
  final Color? backgroundColor;
  final TopSnackBarAction? action;
  final VoidCallback onDismissed;

  const TopSnackBar({
    super.key,
    required this.message,
    this.isError = false,
    this.icon,
    this.backgroundColor,
    this.action,
    required this.onDismissed,
  });

  @override
  TopSnackBarState createState() => TopSnackBarState();
}

/// The state for the [TopSnackBar] widget, exposed to allow the
/// `showTopSnackBar` function to trigger the exit animation.
class TopSnackBarState extends State<TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.standardCurve,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.fadeOutCurve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the exit animation.
  void reverseAnimation() {
    if (mounted && !_controller.isDismissed) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Position below status bar + some padding for app bar area
    final topPadding = mediaQuery.viewPadding.top + 56.0 + 8.0;

    // Use custom backgroundColor, or default based on isError
    final bgColor =
        widget.backgroundColor ??
        (widget.isError
            ? const Color(0xFFDC2626) // Red for errors
            : const Color(0xFF22C55E)); // Green for success

    // Use custom icon, or default based on isError
    final iconData =
        widget.icon ??
        (widget.isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded);

    return Positioned(
      top: topPadding,
      left: 16.0,
      right: 16.0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: reverseAnimation, // Tap to dismiss
              onHorizontalDragEnd: (_) =>
                  reverseAnimation(), // Swipe to dismiss
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(iconData, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.action != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          reverseAnimation();
                          widget.action!.onPressed();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.action!.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
