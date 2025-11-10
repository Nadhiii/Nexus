import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppleFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String heroTag;

  const AppleFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  State<AppleFloatingActionButton> createState() => _AppleFloatingActionButtonState();
}

class _AppleFloatingActionButtonState extends State<AppleFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: FloatingActionButton(
                heroTag: widget.heroTag,
                onPressed: null, // Handled by GestureDetector
                backgroundColor: AppTheme.iosBluePrimary,
                foregroundColor: Colors.white,
                elevation: _isPressed ? 4 : 8,
                child: const Icon(
                  Icons.add,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
