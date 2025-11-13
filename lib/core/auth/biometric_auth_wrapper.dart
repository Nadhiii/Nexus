import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';
import '../../modules/security/app_lock_screen.dart';

class BiometricAuthWrapper extends StatefulWidget {
  final Widget child;

  const BiometricAuthWrapper({super.key, required this.child});

  @override
  State<BiometricAuthWrapper> createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper> with WidgetsBindingObserver {
  bool _isLocked = true;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  void _checkInitialLock() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BiometricProvider>();
      if (!provider.isAppLockEnabled) {
        setState(() {
          _isLocked = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final provider = context.read<BiometricProvider>();
    if (!provider.isAppLockEnabled) return;

    if (state == AppLifecycleState.paused) {
      _startLockTimer();
    } else if (state == AppLifecycleState.resumed) {
      _stopLockTimer();
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel(); // Cancel any existing timer
    _lockTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _isLocked = true;
        });
      }
    });
  }

  void _stopLockTimer() {
    _lockTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BiometricProvider>();

    if (!provider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.isAppLockEnabled && _isLocked) {
      return AppLockScreen(
        onAuthenticated: () {
          if (mounted) {
            setState(() {
              _isLocked = false;
            });
          }
        },
      );
    }

    return widget.child;
  }
}
