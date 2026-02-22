import 'package:flutter/material.dart';
import 'dart:async';

/// AnimatedNumberText animates a number appearing digit by digit, like a typewriter or coding error effect.
class AnimatedNumberText extends StatefulWidget {
  final num number;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final int decimalPlaces;

  const AnimatedNumberText({
    super.key,
    required this.number,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
  });

  @override
  State<AnimatedNumberText> createState() => _AnimatedNumberTextState();
}

class _AnimatedNumberTextState extends State<AnimatedNumberText> {
  String _display = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animateNumber();
  }

  @override
  void didUpdateWidget(covariant AnimatedNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _animateNumber();
    }
  }

  void _animateNumber() {
    _timer?.cancel();
    final formatted = widget.number.toStringAsFixed(widget.decimalPlaces);
    int i = 0;
    _display = '';
    _timer = Timer.periodic(
      Duration(
        milliseconds: (widget.duration.inMilliseconds ~/ formatted.length)
            .clamp(20, 80),
      ),
      (timer) {
        setState(() {
          _display = formatted.substring(0, i + 1);
        });
        i++;
        if (i >= formatted.length) {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}$_display${widget.suffix}',
      style: widget.style,
    );
  }
}
