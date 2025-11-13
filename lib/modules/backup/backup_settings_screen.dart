import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Restore', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.background,
      ),
      backgroundColor: theme.colorScheme.background,
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, BackupProvider provider) {
    if (provider.state == BackupState.Uninitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == BackupState.LoggedOut) {
      return _buildLoggedOutView(context, provider);
    }

    return _buildLoggedInView(context, provider);
  }

  Widget _buildLoggedOutView(BuildContext context, BackupProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            const SizedBox(height: AppSpacing.lg),
            Text('Sign In to Backup', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Sign in with your Google account to back up and restore your Nexus data.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign In with Google'),
              onPressed: () => provider.signIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, BackupProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildStatusCard(context, provider),
        const SizedBox(height: AppSpacing.lg),
        _buildActionsCard(context, provider),
        const SizedBox(height: AppSpacing.lg),
        _buildInfoCard(context),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, BackupProvider provider) {
    final lastBackup = provider.lastBackupTime;
    final statusText = lastBackup != null
        ? 'Last backup: ${DateFormat.yMMMd().add_jms().format(lastBackup)}'
        : 'No backups found.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done, color: Colors.green, size: 32),
                const SizedBox(width: AppSpacing.md),
                Text('Backup Enabled', style: AppTypography.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(statusText, style: AppTypography.bodyMedium),
            if (provider.state == BackupState.InProgress)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            if (provider.state == BackupState.Error)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(provider.error ?? 'An unknown error occurred', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, BackupProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Backup Now'),
              onPressed: provider.state == BackupState.InProgress ? null : () => provider.backupNow(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
              onPressed: provider.state == BackupState.InProgress ? null : () => _confirmRestore(context, provider),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
             const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onPressed: () => provider.signOut(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context, BackupProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('Restoring from a backup will overwrite all current data. This action cannot be undone.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
          FilledButton(child: const Text('Restore'), onPressed: () {
            Navigator.of(dialogContext).pop();
            provider.restoreNow();
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How Backup Works', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              '• Backups are performed automatically every 24 hours.\n'
              '• Your data is securely stored in your personal Google Drive.\n'
              '• Restoring will replace all local data with the backup.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
