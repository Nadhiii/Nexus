import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/top_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handle(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();

      if (errorMessage.contains('Google Play Services') ||
          errorMessage.contains('GoogleSignInApi') ||
          errorMessage.contains('SIGN_IN_REQUIRED')) {
        errorMessage =
            'Google Play Services is not available or needs updating. Please use "Use without account" option.';
      } else if (errorMessage.contains('Configuration error')) {
        errorMessage =
            'App configuration issue. Please contact support or use "Use without account" option.';
      } else if (errorMessage
          .contains('account-exists-with-different-credential')) {
        errorMessage =
            'This email is already registered with a different sign-in method. Please try a different account.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Google Sign-In is not available')) {
        errorMessage =
            'Google Sign-In is currently not available. Please try "Use without account" option.';
      } else if (errorMessage.contains('cancelled')) {
        return;
      } else if (errorMessage.contains('Google Sign-In failed')) {
        errorMessage =
            'Google Sign-In failed due to configuration or service issues. Please try "Use without account" option.';
      } else {
        errorMessage =
            'Sign-in failed. Please try again later or use "Use without account" option.';
      }

      showTopSnackBar(
        context,
        errorMessage,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nexus',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rammettoOne(
                      fontSize: 42,
                      height: 1.1,
                      letterSpacing: .5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _handle(() async {
                              await authService.signInWithGoogle();
                            }),
                    icon: const Icon(Icons.login),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Continue with Google',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handle(() async {
                              await authService.signInAnonymously();
                            }),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Use without account',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can switch to a Google account later; data will sync across devices when signed in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: theme.textTheme.bodySmall?.fontSize,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
