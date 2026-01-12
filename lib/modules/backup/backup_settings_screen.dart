import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    if (mounted) setState(() => _isLoading = false);
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
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          replace
              ? 'This will replace all your current data with the backup. This action cannot be undone.'
              : 'This will merge the backup data with your current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'No backups yet',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Create your first backup to secure your data',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
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
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'merge',
                                      child: Row(
                                        children: [
                                          Icon(Icons.merge),
                                          SizedBox(width: AppSpacing.sm),
                                          Text('Restore (Merge)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'replace',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore),
                                          SizedBox(width: AppSpacing.sm),
                                          Text('Restore (Replace)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'merge':
                                        _restoreBackup(
                                          backup.id,
                                          replace: false,
                                        );
                                        break;
                                      case 'replace':
                                        _restoreBackup(
                                          backup.id,
                                          replace: true,
                                        );
                                        break;
                                      case 'delete':
                                        _deleteBackup(backup.id);
                                        break;
                                    }
                                  },
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
