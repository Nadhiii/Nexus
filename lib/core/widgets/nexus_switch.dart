import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';

/// A custom Switch with spring-physics thumb movement.
/// The thumb overshoots slightly past the end position then snaps back,
/// giving it the same alive feel as AirSync's toggles.
/// Drop-in replacement for Flutter's Switch widget.
class NexusSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;
  final Color? activeThumbColor;

  const NexusSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
    this.activeThumbColor,
  });

  @override
  State<NexusSwitch> createState() => _NexusSwitchState();
}

class _NexusSwitchState extends State<NexusSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 0.0 = fully off, 1.0 = fully on
  double get _targetValue => widget.value ? 1.0 : 0.0;

  static const double _trackWidth = 50.0;
  static const double _trackHeight = 28.0;
  static const double _thumbSize = 22.0;
  static const double _thumbPadding = 3.0;
  static const double _thumbTravel = _trackWidth - _thumbSize - (_thumbPadding * 2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: _targetValue,
      lowerBound: -0.1, // allows slight overshoot on the off side
      upperBound: 1.1,  // allows slight overshoot on the on side
    );
  }

  @override
  void didUpdateWidget(NexusSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animateToTarget();
    }
  }

  void _animateToTarget() {
    final spring = SpringDescription(
      mass: AppAnimations.springMass,
      stiffness: AppAnimations.springStiffness,
      damping: AppAnimations.springDamping,
    );
    // Initial velocity gives the thumb a kick in the right direction
    final velocity = widget.value ? 4.0 : -4.0;
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      _targetValue,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  void _onTap() {
    if (widget.onChanged == null) return;
    widget.onChanged!(!widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.primaryBlue;
    final inactiveColor =
        widget.inactiveTrackColor ?? AppColors.cardElevated;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value.clamp(0.0, 1.0);
          final rawT = _controller.value; // unclamped for thumb position

          return Container(
            width: _trackWidth,
            height: _trackHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              color: Color.lerp(inactiveColor, activeColor, t),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: _thumbPadding,
                  left: _thumbPadding + (rawT * _thumbTravel),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.activeThumbColor ?? Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
