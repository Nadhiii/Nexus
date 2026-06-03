import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

/// Animates a child in with a fade + slide-up on first build.
/// Use [delay] to stagger multiple items in a list.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slideDistance;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideDistance = 18.0,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.standardCurve),
    );

    _slide = Tween<double>(
      begin: widget.slideDistance,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.standardCurve),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
