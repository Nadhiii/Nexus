import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backup_service.dart';

class BackupProvider extends ChangeNotifier {
  final BackupService _backupService = BackupService();

  bool _isLoading = false;
  bool _autoSyncEnabled = true;
  Map<String, dynamic>? _lastBackupStatus;
  String? _lastError;

  bool get isLoading => _isLoading;
  bool get autoSyncEnabled => _autoSyncEnabled;
  Map<String, dynamic>? get lastBackupStatus => _lastBackupStatus;
  String? get lastError => _lastError;

  /// Initialize backup provider
  void initialize() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, refresh backup status
        refreshBackupStatus();

        // Auto sync if enabled
        if (_autoSyncEnabled) {
          autoSync();
        }
      } else {
        // User signed out, clear backup status
        _lastBackupStatus = null;
        notifyListeners();
      }
    });
  }

  /// Refresh backup status
  Future<void> refreshBackupStatus() async {
    try {
      _lastError = null;
      final status = await _backupService.getBackupStatus();
      _lastBackupStatus = status;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Create a manual backup
  Future<bool> createBackup() async {
    if (_isLoading) return false;

    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _backupService.createBackup();
      await _backupService.cleanupOldBackups();
      await refreshBackupStatus();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync data (same as create backup but with different semantics)
  Future<bool> syncData() async {
    if (_isLoading) return false;

    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _backupService.syncData();
      await refreshBackupStatus();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Auto sync (silent sync without loading state)
  Future<void> autoSync() async {
    try {
      // Don't show loading for auto sync
      await _backupService.syncData();
      await refreshBackupStatus();
    } catch (e) {
      // Silent fail for auto sync
      debugPrint('Auto sync failed: $e');
    }
  }

  /// Restore from backup
  Future<bool> restoreFromBackup(String backupId) async {
    if (_isLoading) return false;

    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _backupService.restoreFromBackup(backupId);
      await refreshBackupStatus();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get backup history
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      return await _backupService.getBackupHistory();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Toggle auto sync
  void toggleAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();

    // If enabling auto sync and user is logged in, do a sync
    if (enabled && FirebaseAuth.instance.currentUser != null) {
      autoSync();
    }
  }

  /// Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Check if backup is needed (e.g., if data has changed significantly)
  bool shouldBackup() {
    if (_lastBackupStatus == null || !_lastBackupStatus!['isLoggedIn']) {
      return false;
    }

    final lastBackup = _lastBackupStatus!['lastBackup'];
    if (lastBackup == null) return true;

    try {
      final lastBackupTime = lastBackup.toDate();
      final now = DateTime.now();
      final difference = now.difference(lastBackupTime);

      // Suggest backup if more than 24 hours old
      return difference.inHours > 24;
    } catch (e) {
      return true;
    }
  }

  /// Get backup status summary for UI
  String getStatusSummary() {
    if (_lastBackupStatus == null) {
      return 'Loading...';
    }

    if (!_lastBackupStatus!['isLoggedIn']) {
      return 'Sign in to enable backup';
    }

    final lastBackup = _lastBackupStatus!['lastBackup'];
    if (lastBackup == null) {
      return 'No backups yet';
    }

    try {
      final lastBackupTime = lastBackup.toDate();
      final now = DateTime.now();
      final difference = now.difference(lastBackupTime);

      if (difference.inMinutes < 1) {
        return 'Just backed up';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
