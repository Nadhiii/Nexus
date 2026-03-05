// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../core/providers/biometric_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;

  const AppLockScreen({super.key, required this.child});

  @override
  _AppLockScreenState createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    final biometricProvider = Provider.of<BiometricProvider>(
      context,
      listen: false,
    );
    if (biometricProvider.isBiometricEnabled) {
      _authenticate();
    } else {
      setState(() {
        _isUnlocked = true;
      });
    }
  }

  Future<void> _authenticate() async {
    final localAuth = LocalAuthentication();
    try {
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      setState(() {
        _isUnlocked = didAuthenticate;
      });
    } on PlatformException {
      // Handle error
      setState(() {
        _isUnlocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isUnlocked ? widget.child : _buildLockScreen();
  }

  Widget _buildLockScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Nexus is Locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Authenticate to continue',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Authenticate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
