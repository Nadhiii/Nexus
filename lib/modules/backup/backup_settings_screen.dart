import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/nexus_switch.dart';
import '../../core/widgets/nexus_button.dart';
import '../../core/widgets/nexus_card.dart';
import '../../core/widgets/nexus_initial_loading.dart';
import '../../core/widgets/nexus_empty_state.dart';
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
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        _showSnackBar('Error loading backups: $e', isError: true);
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      await _backupService.createBackup();
      if (mounted) {
        _showSnackBar('Backup created successfully!');
      }
      await _loadBackups();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error creating backup: $e', isError: true);
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _restoreBackup(String backupId, {bool replace = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Padding(
          padding: AppSpacing.cardPaddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restore Backup', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: replace
                      ? AppColors.lossRose.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: replace
                        ? AppColors.lossRose.withValues(alpha: 0.3)
                        : AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      replace ? Icons.warning_amber : Icons.info_outline,
                      color: replace
                          ? AppColors.lossRose
                          : AppColors.primaryBlueLight,
                      size: AppSpacing.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        replace
                            ? 'This will replace all your current data with the backup. This action cannot be undone.'
                            : 'This will merge the backup data with your current data.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: replace
                              ? AppColors.pastelPink
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl3),
              Row(
                children: [
                  Expanded(
                  child: NexusButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                    variant: NexusButtonVariant.secondary,
                    width: double.infinity,
                  ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                  child: NexusButton(
                    label: 'Restore',
                    onPressed: () => Navigator.pop(context, true),
                    variant: replace
                        ? NexusButtonVariant.destructive
                        : NexusButtonVariant.primary,
                    width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.restoreBackup(backupId, replace: replace);
      if (mounted) {
        _showSnackBar('Backup restored successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error restoring backup: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Padding(
          padding: AppSpacing.cardPaddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Backup', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Are you sure you want to delete this backup? This cannot be undone.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl3),
              Row(
                children: [
                  Expanded(
                  child: NexusButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                    variant: NexusButtonVariant.secondary,
                    width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                  child: NexusButton(
                    label: 'Delete',
                    onPressed: () => Navigator.pop(context, true),
                    variant: NexusButtonVariant.destructive,
                    width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _backupService.deleteBackup(backupId);
      if (mounted) {
        _showSnackBar('Backup deleted');
      }
      await _loadBackups();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting backup: $e', isError: true);
      }
    }
  }

  void _showRestoreOptions(BuildContext context, String backupId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore Options', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            _buildRestoreOptionCard(
              icon: Icons.merge_type_rounded,
              title: 'Merge Data',
              description:
                  'Add backup data to your current data. Keeps both old and new entries.',
              onTap: () {
                Navigator.pop(context);
                _restoreBackup(backupId, replace: false);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRestoreOptionCard(
              icon: Icons.restore_rounded,
              title: 'Replace Data',
              description:
                  'Replace all current data with backup. This action cannot be undone.',
              onTap: () {
                Navigator.pop(context);
                _restoreBackup(backupId, replace: true);
              },
              isDangerous: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteBackup(backupId);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text(
                  'Delete Backup',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.lossRose,
                  ),
                ),
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
    return NexusCard(
      onTap: onTap,
      variant: isDangerous ? NexusCardVariant.error : NexusCardVariant.base,
      padding: AppSpacing.cardPaddingMd,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDangerous
                    ? AppColors.lossRose.withValues(alpha: 0.1)
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                icon,
                color: isDangerous
                    ? AppColors.lossRose
                    : AppColors.primaryBlueLight,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDangerous
                          ? AppColors.pastelPink
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(description, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: isError ? AppColors.lossRose : AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textPrimary,
            onPressed: _isLoading ? null : _loadBackups,
          ),
        ],
      ),
      body: _isLoading && _backups == null
          ? const Center(
              child: NexusInitialLoading(),
            )
          : Column(
              children: [
                // Settings Section
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Column(
                      children: [
                        _buildSwitch(
                          title: 'Auto backup daily',
                          subtitle:
                              'Create a backup after login if latest is older than 24h.',
                          value: _autoBackupEnabled,
                          onChanged: (v) async {
                            setState(() => _autoBackupEnabled = v);
                            await _backupService.setAutoBackupEnabled(v);
                          },
                        ),
                        Divider(color: AppColors.cardElevated, height: 1),
                        _buildSwitch(
                          title: 'Auto-restore when empty',
                          subtitle:
                              'Restore latest backup (merge) if data is empty after login.',
                          value: _autoRestoreEnabled,
                          onChanged: (v) async {
                            setState(() => _autoRestoreEnabled = v);
                            await _backupService.setAutoRestoreEnabled(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: NexusButton(
                    onPressed: _isCreatingBackup ? null : _createBackup,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: 'Create Backup',
                    isLoading: _isCreatingBackup,
                    emphasizedPrimary: true,
                    width: double.infinity,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Backups List
                Expanded(
                  child: _backups == null || _backups!.isEmpty
                      ? Center(
                          child: NexusEmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'No backups yet',
                            message: 'Create your first backup to secure your data',
                            inCard: false,
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

                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: AppSpacing.borderRadiusMd,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_done_rounded,
                                      color: AppColors.primaryBlueLight,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateFormat.format(backup.createdAt),
                                          style: AppTypography.titleMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '$totalItems items backed up',
                                          style: AppTypography.bodySmall,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: backup.counts.entries
                                              .where((e) => e.value > 0)
                                              .map((entry) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal:
                                                            AppSpacing.sm,
                                                        vertical: AppSpacing.xs,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.cardElevated,
                                                    borderRadius: AppSpacing
                                                        .borderRadiusXs,
                                                  ),
                                                  child: Text(
                                                    '${entry.key}: ${entry.value}',
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () =>
                                        _showRestoreOptions(context, backup.id),
                                  ),
                                ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          NexusSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
