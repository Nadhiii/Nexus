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

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isCheckingLock = true;
  DateTime? _lastPausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _lastPausedTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleAppResume() async {
    if (_lastPausedTime == null) return;

    final biometricProvider = Provider.of<BiometricProvider>(
      context,
      listen: false,
    );

    // Check if app lock is enabled
    if (!biometricProvider.isAppLockEnabled) return;

    // Check if app was in background for more than 30 seconds
    final timeDifference = DateTime.now().difference(_lastPausedTime!);
    if (timeDifference.inSeconds > 30) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  Future<void> _checkAppLockStatus() async {
    try {
      final biometricProvider = Provider.of<BiometricProvider>(
        context,
        listen: false,
      );

      // Wait for biometric provider to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      if (biometricProvider.isAppLockEnabled) {
        setState(() {
          _isLocked = true;
          _isCheckingLock = false;
        });
      } else {
        setState(() {
          _isLocked = false;
          _isCheckingLock = false;
        });
      }
    } catch (e) {
      // If there's an error, don't show lock screen
      setState(() {
        _isLocked = false;
        _isCheckingLock = false;
      });
    }
  }

  Future<void> _showAppLockScreen() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppLockScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        settings: const RouteSettings(name: '/app_lock'),
      ),
    );

    if (result == true) {
      // Authentication successful
      setState(() {
        _isLocked = false;
      });
    } else {
      // Authentication failed or cancelled
      // Keep the app locked or exit
      if (mounted) {
        // You could implement app exit logic here
        // For now, just keep showing the lock screen
        _showAppLockScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLock) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLocked) {
      // Show app lock screen immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAppLockScreen();
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
