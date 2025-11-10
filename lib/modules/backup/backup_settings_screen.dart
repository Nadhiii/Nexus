import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/backup_service.dart';
import '../../core/widgets/translucent_app_bar.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  Map<String, dynamic>? _backupStatus;
  List<Map<String, dynamic>> _backupHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
    _loadBackupHistory();
  }

  Future<void> _loadBackupStatus() async {
    try {
      final status = await _backupService.getBackupStatus();
      setState(() {
        _backupStatus = status;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading backup status: $e')),
        );
      }
    }
  }

  Future<void> _loadBackupHistory() async {
    try {
      final history = await _backupService.getBackupHistory();
      setState(() {
        _backupHistory = history;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading backup history: $e')),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.createBackup();
      await _backupService.cleanupOldBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }

      // Reload data
      await _loadBackupStatus();
      await _loadBackupHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating backup: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.syncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced successfully!')),
        );
      }

      // Reload data
      await _loadBackupStatus();
      await _loadBackupHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error syncing data: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all your current data with the selected backup. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.restoreFromBackup(backupId);

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';

    try {
      final DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const TranslucentAppBar(title: Text('Backup & Sync')),
      body: _backupStatus == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadBackupStatus();
                await _loadBackupHistory();
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _backupStatus!['isLoggedIn']
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: _backupStatus!['isLoggedIn']
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Backup Status',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!_backupStatus!['isLoggedIn']) ...[
                              const Text(
                                'You need to sign in to use backup & sync features.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ] else ...[
                              Text('Account: ${user?.email ?? 'Anonymous'}'),
                              const SizedBox(height: 8),
                              Text(
                                'Last Backup: ${_formatTimestamp(_backupStatus!['lastBackup'])}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Backups: ${_backupStatus!['totalBackups']}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Actions Card
                    if (_backupStatus!['isLoggedIn']) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Actions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _createBackup,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.backup),
                                  label: Text(
                                    _isLoading
                                        ? 'Creating Backup...'
                                        : 'Create Backup',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _syncData,
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Sync Data'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Backup History
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backup History',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (_backupHistory.isEmpty) ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text('No backups found'),
                                  ),
                                ),
                              ] else ...[
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _backupHistory.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final backup = _backupHistory[index];
                                    return ListTile(
                                      leading: const Icon(Icons.folder_zip),
                                      title: Text(
                                        'Backup ${_formatTimestamp(backup['timestamp'])}',
                                      ),
                                      subtitle: Text(
                                        'Accounts: ${backup['accountsCount']}, '
                                        'Transactions: ${backup['transactionsCount']}, '
                                        'Debts: ${backup['debtsCount']}, '
                                        'Goals: ${backup['goalsCount']}, '
                                        'Subscriptions: ${backup['subscriptionsCount']}, '
                                        'Investments: ${backup['investmentsCount']}, '
                                        'Budgets: ${backup['budgetsCount']}'
                                        '${backup['hasUserProfile'] == true ? ', Profile ✓' : ''}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.restore),
                                        onPressed: _isLoading
                                            ? null
                                            : () =>
                                                  _restoreBackup(backup['id']),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Backup & Sync',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '• Your data is automatically synced when you\'re signed in\n'
                              '• Backups include ALL your data:\n'
                              '  - Accounts & Transactions\n'
                              '  - Goals & Debts\n'
                              '  - Subscriptions & Budgets\n'
                              '  - Investments & User Profile\n'
                              '• Only the 5 most recent backups are kept\n'
                              '• Restoring a backup replaces all current data\n'
                              '• Data is securely stored in your Firebase account',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
