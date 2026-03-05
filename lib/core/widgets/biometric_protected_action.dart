import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/biometric_provider.dart';

class BiometricProtectedAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String operation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool requireConfirmation;

  const BiometricProtectedAction({
    super.key,
    required this.child,
    required this.onPressed,
    this.operation = 'sensitive operation',
    this.confirmationTitle,
    this.confirmationMessage,
    this.requireConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleProtectedAction(context),
      child: child,
    );
  }

  Future<void> _handleProtectedAction(BuildContext context) async {
    try {
      final biometricProvider = Provider.of<BiometricProvider>(
        context,
        listen: false,
      );

      // Check if biometric protection is required for sensitive operations
      if (biometricProvider.isSensitiveOperationsEnabled) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Authenticate
        final authenticated = await biometricProvider
            .authenticateForSensitiveOperation(operation: operation);

        // Close loading indicator
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (!authenticated) {
          if (context.mounted) {
            _showAuthenticationFailedDialog(context);
          }
          return;
        }
      }

      // If confirmation is required, show confirmation dialog
      if (requireConfirmation) {
        if (!context.mounted) { return; }
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(confirmationTitle ?? 'Confirm Action'),
                content: Text(
                  confirmationMessage ??
                      'Are you sure you want to proceed with this $operation?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!confirmed) { return; }
      }

      // Execute the protected action
      onPressed();
    } catch (e) {
      // Swallow errors to avoid using BuildContext across async gaps.
    }
  }

  void _showAuthenticationFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Text(
          'Biometric authentication is required to proceed with this $operation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Helper widget for buttons that need biometric protection
class BiometricProtectedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String operation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool requireConfirmation;

  const BiometricProtectedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.operation = 'sensitive operation',
    this.confirmationTitle,
    this.confirmationMessage,
    this.requireConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricProvider>(
      builder: (context, biometricProvider, _) {
        return BiometricProtectedAction(
          operation: operation,
          confirmationTitle: confirmationTitle,
          confirmationMessage: confirmationMessage,
          requireConfirmation: requireConfirmation,
          onPressed: onPressed,
          child: child,
        );
      },
    );
  }
}
