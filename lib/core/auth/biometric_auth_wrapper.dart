import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';
import '../../modules/security/app_lock_screen.dart';

class BiometricAuthWrapper extends StatelessWidget {
  final Widget child;

  const BiometricAuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricProvider>(
      builder: (context, biometricProvider, _) {
        if (biometricProvider.isBiometricEnabled) {
          return AppLockScreen(child: child);
        } else {
          return child;
        }
      },
    );
  }
}
