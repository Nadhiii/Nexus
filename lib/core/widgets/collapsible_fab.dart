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

class _CollapsibleFabState extends State<CollapsibleFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  Timer? _collapseTimer;
  late AnimationController _controller;
  late Animation<double> _widthFactor;
  late Animation<double> _labelOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Bumped slightly to 400ms to give the bounce time to breathe
      // without looking glitchy/snappy.
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _widthFactor = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.standardCurve,
      // <-- NEW: This forces the width to "overshoot" backwards, squishing
      // the pill slightly before it settles into a circle!
      reverseCurve: Curves.easeOutBack,
    );

    // Label fades in slightly delayed so it only appears once the pill is wide enough
    _labelOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _expandTemporarily() {
    setState(() => _expanded = true);
    _controller.forward();
    _collapseTimer?.cancel();
    _collapseTimer = Timer(widget.expandedDuration, () {
      if (!mounted) return;
      setState(() => _expanded = false);
      _controller.reverse();
    });
  }

  void _handlePressed() {
    widget.onPressed();
    _expandTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg = widget.foregroundColor ?? Colors.white;
    const fabSize = 56.0;
    const expandedWidth = 160.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final width =
              fabSize + (expandedWidth - fabSize) * _widthFactor.value;
          return GestureDetector(
            onTap: _handlePressed,
            child: Container(
              height: fabSize,
              width: width,
              clipBehavior: Clip.antiAlias, // Smoothly clips the overflow
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(fabSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: OverflowBox(
                // Gives the Row infinite space to prevent layout errors
                maxWidth: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // Keeps the Row hugging its contents tightly
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: fg, size: 24),
                      child: widget.icon,
                    ),
                    // Label slides in as the pill widens
                    if (_controller.value > 0.1)
                      FadeTransition(
                        opacity: _labelOpacity,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            softWrap:
                                false, // Prevents text from wrapping to a new line
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
