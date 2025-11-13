import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/services/auth_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({super.key, required this.onAuthenticated});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _authenticateOnLoad();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _authenticateOnLoad() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final biometricProvider = Provider.of<BiometricProvider>(
        context,
        listen: false,
      );
      final authenticated = await biometricProvider.authenticateForAppAccess();

      if (authenticated && mounted) {
        widget.onAuthenticated();
      } else if (mounted) {
        _showAuthFailedDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: const Text(
          'Could not verify your identity. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // This provides a safe exit if biometrics fail repeatedly.
              await AuthService().signOut();
              if (mounted) {
                // No need to pop, AuthGate will handle navigation.
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authenticate();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(
          'An error occurred during authentication: $error\n\nPlease try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authenticate();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey[900]!, Colors.black]
                : [
                    theme.colorScheme.primaryContainer.withOpacity(0.1),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              size: 60,
                              color: theme.colorScheme.primary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Nexus',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Personal Finance Manager',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          Consumer<BiometricProvider>(
                            builder: (context, provider, child) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: _isAuthenticating
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        Icons.fingerprint,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          Consumer<BiometricProvider>(
                            builder: (context, provider, child) {
                              return Column(
                                children: [
                                  Text(
                                    _isAuthenticating
                                        ? 'Authenticating...'
                                        : 'Touch ${provider.biometricTypeDescription}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isAuthenticating
                                        ? 'Please wait while we verify your identity'
                                        : 'Use your ${provider.biometricTypeDescription.toLowerCase()} to unlock Nexus',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 48),

                          if (!_isAuthenticating)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _authenticate,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Authenticate'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
