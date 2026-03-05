import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/backup_service.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final BackupService _backupService = BackupService();
  List<BackupSummary>? _backups;
  bool _isLoading = false;
  bool _isCreatingBackup = false;
  bool _autoBackupEnabled = true;
  bool _autoRestoreEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefsAndBackups();
  }

  Future<void> _loadPrefsAndBackups() async {
    setState(() => _isLoading = true);
    try {
      _autoBackupEnabled = await _backupService.getAutoBackupEnabled();
      _autoRestoreEnabled = await _backupService.getAutoRestoreEnabled();
    } catch (_) {}
    await _loadBackups();
    if (mounted) { setState(() => _isLoading = false); }
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading backups: $e')));
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      await _backupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }
      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating backup: $e')));
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _restoreBackup(String backupId, {bool replace = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restore Backup',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: replace
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: replace
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      replace ? Icons.warning_amber : Icons.info_outline,
                      color: replace ? AppColors.error : AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        replace
                            ? 'This will replace all your current data with the backup. This action cannot be undone.'
                            : 'This will merge the backup data with your current data.',
                        style: TextStyle(
                          color: replace
                              ? AppColors.error
                              : AppColors.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: replace
                              ? AppColors.error
                              : AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Restore',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) { return; }

    setState(() => _isLoading = true);
    try {
      await _backupService.restoreBackup(backupId, replace: replace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error restoring backup: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Backup',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this backup?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) { return; }

    try {
      await _backupService.deleteBackup(backupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup deleted')));
      }
      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting backup: $e')));
      }
    }
  }

  void _showRestoreOptions(BuildContext context, String backupId) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore Backup',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildRestoreOptionCard(
              icon: Icons.merge,
              title: 'Merge',
              description:
                  'Add backup data to your current data. Keeps both old and new entries.',
              onTap: () {
                Navigator.pop(context);
                _restoreBackup(backupId, replace: false);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRestoreOptionCard(
              icon: Icons.restore,
              title: 'Replace',
              description:
                  'Replace all current data with backup. This action cannot be undone.',
              onTap: () {
                Navigator.pop(context);
                _restoreBackup(backupId, replace: true);
              },
              isDangerous: true,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteBackup(backupId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Delete Backup'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDangerous
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDangerous
              ? theme.colorScheme.error.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDangerous
                    ? theme.colorScheme.error.withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDangerous
                    ? theme.colorScheme.error
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDangerous ? theme.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Backup & Restore',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackups,
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading && _backups == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      _buildSwitch(
                        title: 'Auto backup daily',
                        subtitle:
                            'If the latest backup is older than 24 hours, create one after login.',
                        value: _autoBackupEnabled,
                        onChanged: (v) async {
                          setState(() => _autoBackupEnabled = v);
                          await _backupService.setAutoBackupEnabled(v);
                        },
                      ),
                      _buildSwitch(
                        title: 'Auto-restore when empty',
                        subtitle:
                            'After login, if your data is empty, restore the latest backup (merge only).',
                        value: _autoRestoreEnabled,
                        onChanged: (v) async {
                          setState(() => _autoRestoreEnabled = v);
                          await _backupService.setAutoRestoreEnabled(v);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: FilledButton.icon(
                    onPressed: _isCreatingBackup ? null : _createBackup,
                    icon: _isCreatingBackup
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.backup),
                    label: Text(
                      _isCreatingBackup ? 'Creating...' : 'Create Backup',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                Expanded(
                  child: _backups == null || _backups!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 80,
                                color: theme.colorScheme.onSurface.withValues(alpha: 
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'No backups yet',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Create your first backup to secure your data',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: _backups!.length,
                          itemBuilder: (context, index) {
                            final backup = _backups![index];
                            final dateFormat = DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            );
                            final totalItems = backup.counts.values.fold<int>(
                              0,
                              (sum, count) => sum + count,
                            );

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(
                                  AppSpacing.md,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.backup,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  dateFormat.format(backup.createdAt),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '$totalItems items backed up',
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: backup.counts.entries.map((
                                        entry,
                                      ) {
                                        if (entry.value == 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Chip(
                                          label: Text(
                                            '${entry.key}: ${entry.value}',
                                            style: AppTypography.labelSmall,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showRestoreOptions(context, backup.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTypography.titleMedium),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }
}
