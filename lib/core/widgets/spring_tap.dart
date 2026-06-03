import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_animations.dart';

/// Wraps any widget with a spring-physics press effect.
/// On press-down: scales to 0.95 instantly.
/// On release: springs back with a slight overshoot to ~1.02 then settles at 1.0.
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 2.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.animateTo(
      0.95,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails _) {
    _springBack();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _springBack();
  }

  void _springBack() {
    final spring = SpringDescription(
      mass: AppAnimations.springMass,
      stiffness: AppAnimations.springStiffness,
      damping: AppAnimations.springDamping,
    );
    final simulation = SpringSimulation(spring, _controller.value, 1.0, 0.0);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _controller.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
