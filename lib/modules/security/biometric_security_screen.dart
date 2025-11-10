import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/biometric_provider.dart';

class BiometricSecurityScreen extends StatefulWidget {
  const BiometricSecurityScreen({super.key});

  @override
  State<BiometricSecurityScreen> createState() =>
      _BiometricSecurityScreenState();
}

class _BiometricSecurityScreenState extends State<BiometricSecurityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BiometricProvider>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Security'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        actions: [
          Consumer<BiometricProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : () => provider.refresh(),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: Consumer<BiometricProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isBiometricAvailable) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biometric Status Card
                _buildStatusCard(context, provider),

                const SizedBox(height: 16),

                // Biometric Settings
                if (provider.isBiometricAvailable) ...[
                  _buildSettingsCard(context, provider),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildNotAvailableCard(context),
                  const SizedBox(height: 16),
                ],

                // Security Information
                _buildSecurityInfoCard(context, provider),

                const SizedBox(height: 16),

                // Test Authentication Button
                if (provider.isBiometricAvailable)
                  _buildTestAuthenticationCard(context, provider),

                // Error Display
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(context, provider.error!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BiometricProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: provider.isBiometricAvailable
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.biometricIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Security Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.securityLevelDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (provider.isBiometricAvailable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.biometricTypeDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, BiometricProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biometric Security',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Single Enable/Disable Biometric Authentication Toggle
            _buildSettingTile(
              context,
              title: 'Enable Biometric Authentication',
              subtitle:
                  'Use biometric authentication to secure your app and sensitive operations',
              icon: Icons.fingerprint,
              value: provider.isBiometricEnabled,
              onChanged: provider.isLoading
                  ? null
                  : (value) async {
                      await provider.setBiometricEnabled(value);
                      // When enabling biometrics, also enable app lock and sensitive operations
                      if (value) {
                        await provider.setAppLockEnabled(true);
                        await provider.setSensitiveOperationsEnabled(true);
                      } else {
                        // When disabling biometrics, disable all related features
                        await provider.setAppLockEnabled(false);
                        await provider.setSensitiveOperationsEnabled(false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled ? null : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled
              ? theme.colorScheme.onSurface.withOpacity(0.7)
              : theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }

  Widget _buildNotAvailableCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.fingerprint_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Biometric Authentication Not Available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your device does not support biometric authentication or no biometric credentials are enrolled.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Guide user to device settings
                _showSetupGuideDialog(context);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Setup Guide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfoCard(
    BuildContext context,
    BiometricProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'When Enabled',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'App Protection',
              'Biometric authentication required when opening the app',
              provider.isBiometricEnabled,
            ),
            _buildInfoItem(
              'Transaction Security',
              'Authentication required for sensitive operations like transactions',
              provider.isBiometricEnabled,
            ),
            _buildInfoItem(
              'Data Privacy',
              'Biometric data stays securely on your device only',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, bool isEnabled) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.circle_outlined,
            color: isEnabled
                ? Colors.green
                : theme.colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestAuthenticationCard(
    BuildContext context,
    BiometricProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Authentication',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Test your biometric authentication to make sure it\'s working properly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final success = await provider.testAuthentication();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Authentication successful!'
                                    : 'Authentication failed or cancelled',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Test Authentication'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Provider.of<BiometricProvider>(
                  context,
                  listen: false,
                ).refresh();
              },
              icon: Icon(Icons.close, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Biometric Authentication'),
        content: const Text(
          'To use biometric authentication:\n\n'
          '1. Go to your device Settings\n'
          '2. Find Security or Privacy settings\n'
          '3. Set up Fingerprint or Face recognition\n'
          '4. Come back to enable biometric security in Nexus',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
