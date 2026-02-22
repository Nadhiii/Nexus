import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

class CollapsibleFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Object? heroTag;
  final Duration expandedDuration;

  const CollapsibleFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
    this.expandedDuration = const Duration(seconds: 3),
  });

  @override
  State<CollapsibleFab> createState() => _CollapsibleFabState();
}

class _CollapsibleFabState extends State<CollapsibleFab> {
  bool _expanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _expandTemporarily() {
    setState(() => _expanded = true);
    _collapseTimer?.cancel();
    _collapseTimer = Timer(widget.expandedDuration, () {
      if (!mounted) return;
      setState(() => _expanded = false);
    });
  }

  void _handlePressed() {
    widget.onPressed();
    _expandTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    // Add margin to lift the FAB above the floating NavBar
    // 70 (NavBar height) + 32 (NavBar bottom margin) + 16 (extra spacing) = ~118
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: AnimatedCrossFade(
        duration: AppAnimations.fabCrossFadeDuration,
        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: FloatingActionButton(
          heroTag: widget.heroTag,
          onPressed: _handlePressed,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          child: widget.icon,
        ),
        secondChild: FloatingActionButton.extended(
          heroTag: widget.heroTag,
          onPressed: _handlePressed,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          icon: widget.icon,
          label: Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        firstCurve: AppAnimations.fadeOutCurve,
        secondCurve: AppAnimations.fadeInCurve,
        sizeCurve: AppAnimations.sizeCurve,
      ),
    );
  }
}
