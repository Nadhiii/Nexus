import 'dart:async';
import 'package:flutter/material.dart';

/// Shows a custom drop-down notification from the top of the screen.
///
/// [message] is the text to display.
/// Set [isError] to true to display the error variant (e.g., with a red background).
void showTopSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  // Ensure we're working with the root overlay to appear above all other widgets
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey<TopSnackBarState>();
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => TopSnackBar(
      key: key,
      message: message,
      isError: isError,
      onDismissed: () {
        overlayEntry?.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-dismiss after a few seconds
  Future.delayed(const Duration(seconds: 4), () {
    key.currentState?.reverseAnimation();
  });
}

/// A widget that displays a drop-down notification from the top.
/// This widget is intended to be used via the [showTopSnackBar] function.
class TopSnackBar extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  const TopSnackBar({
    super.key,
    required this.message,
    this.isError = false,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = widget.isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foregroundColor = widget.isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;
    final icon = widget.isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 8.0,
      left: 16.0,
      right: 16.0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
