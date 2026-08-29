import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';
import '../../modules/security/app_lock_screen.dart';

/// Gates the app behind AppLockScreen whenever biometric app protection is on.

class BiometricAuthWrapper extends StatelessWidget {
  final Widget child;

  const BiometricAuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricProvider>(
      builder: (context, biometricProvider, _) {
        final locked = biometricProvider.isBiometricEnabled ||
            biometricProvider.isAppLockEnabled;

        if (!locked) {
          return child;
        }

        return AppLockScreen(
          key: const ValueKey('biometric-app-lock'),
          child: child,
        );
      },
    );
  }
}
