import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

void showTopNotification(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  // Safety check: ensure context is still valid and mounted
  if (!context.mounted) {
    debugPrint(
      'showTopNotification: Context not mounted, skipping notification',
    );
    return;
  }

  OverlayState? overlay;
  try {
    overlay = Overlay.of(context);
  } catch (e) {
    debugPrint('showTopNotification: Could not get overlay - $e');
    return;
  }

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _TopNotificationWidget(
      message: message,
      isError: isError,
      onDismiss: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  @override
  _TopNotificationWidgetState createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, -2.0),
          end: const Offset(0, 1.0),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.fadeOutCurve,
          ),
        );
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = widget.isError
        ? colorScheme.error
        : theme.primaryColor;
    final textColor = widget.isError
        ? colorScheme.onError
        : theme.colorScheme.onPrimary;

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
