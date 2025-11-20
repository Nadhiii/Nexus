import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backup_service.dart';
import 'transaction_provider.dart';
import 'account_provider.dart';
import 'goal_provider.dart';
import 'subscription_provider.dart';
import 'debt_provider.dart';

enum BackupState { Uninitialized, LoggedOut, LoggedIn, InProgress, Success, Error }

class BackupProvider extends ChangeNotifier {
  late final FirebaseBackupService _backupService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BackupState _state = BackupState.Uninitialized;
  DateTime? _lastBackupTime;
  String? _error;
  User? _user;

  TransactionProvider? _transactionProvider;
  AccountProvider? _accountProvider;
  GoalProvider? _goalProvider;
  SubscriptionProvider? _subscriptionProvider;
  DebtProvider? _debtProvider;

  BackupState get state => _state;
  DateTime? get lastBackupTime => _lastBackupTime;
  String? get error => _error;
  bool get isLoggedIn => _state == BackupState.LoggedIn || _state == BackupState.InProgress || _state == BackupState.Success;
  User? get currentUser => _user;

  BackupProvider() {
    _backupService = FirebaseBackupService();
    _initialize();
  }

  void update({
    TransactionProvider? transactionProvider,
    AccountProvider? accountProvider,
    GoalProvider? goalProvider,
    SubscriptionProvider? subscriptionProvider,
    DebtProvider? debtProvider,
  }) {
    _transactionProvider = transactionProvider;
    _accountProvider = accountProvider;
    _goalProvider = goalProvider;
    _subscriptionProvider = subscriptionProvider;
    _debtProvider = debtProvider;
  }

  Future<void> _initialize() async {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user == null) {
        _updateState(BackupState.LoggedOut);
      } else {
        _updateState(BackupState.LoggedIn);
        fetchLastBackupTime();
      }
    });
  }

  Future<void> fetchLastBackupTime() async {
    if (_user == null) return;
    try {
      final timestamp = await _backupService.getLastBackupTimestamp(_user!.uid);
      if (timestamp != null) {
        _lastBackupTime = timestamp;
        notifyListeners();
      }
    } catch (e) {
      // It's okay if this fails silently.
    }
  }

  Future<void> backupNow() async {
    if (_user == null ||
        _transactionProvider == null ||
        _accountProvider == null ||
        _goalProvider == null ||
        _subscriptionProvider == null ||
        _debtProvider == null) {
      _setError('One of the data providers is not ready.');
      return;
    }

    _updateState(BackupState.InProgress);

    try {
      final backupData = {
        'transactions': _transactionProvider!.transactions.map((t) => t.toJson()).toList(),
        'accounts': _accountProvider!.accounts.map((a) => a.toJson()).toList(),
        'goals': _goalProvider!.goals.map((g) => g.toJson()).toList(),
        'subscriptions': _subscriptionProvider!.subscriptions.map((s) => s.toJson()).toList(),
        'debts': _debtProvider!.debts.map((d) => d.toJson()).toList(),
      };

      await _backupService.createBackup(_user!.uid, backupData);
      await fetchLastBackupTime();
      _updateState(BackupState.Success);
      Future.delayed(const Duration(seconds: 3), () => _updateState(BackupState.LoggedIn));
    } catch (e) {
      _setError('Backup failed: $e');
    }
  }

  Future<void> restoreNow() async {
    if (_user == null) {
      _setError('You must be logged in to restore a backup.');
      return;
    }

    _updateState(BackupState.InProgress);

    try {
      final backupData = await _backupService.restoreFromBackup(_user!.uid);
      
      if (backupData == null) {
        _setError('No backup found to restore.');
        _updateState(BackupState.LoggedIn);
        return;
      }
      
      final data = backupData['data'];

      if (data == null) {
        _setError('Backup data is corrupt or empty.');
         _updateState(BackupState.LoggedIn);
        return;
      }

      // Clear existing data
      await _transactionProvider?.clearAllData();
      await _accountProvider?.clearAllData();
      await _goalProvider?.clearAllData();
      await _subscriptionProvider?.clearAllData();
      await _debtProvider?.clearAllData();

      // Restore new data
      if (data['transactions'] != null) await _transactionProvider?.restoreFromBackup(data['transactions']);
      if (data['accounts'] != null) await _accountProvider?.restoreFromBackup(data['accounts']);
      if (data['goals'] != null) await _goalProvider?.restoreFromBackup(data['goals']);
      if (data['subscriptions'] != null) await _subscriptionProvider?.restoreFromBackup(data['subscriptions']);
      if (data['debts'] != null) await _debtProvider?.restoreFromBackup(data['debts']);
      
      // Data will be reloaded automatically by the stream listeners in each provider.

      _updateState(BackupState.Success);
      Future.delayed(const Duration(seconds: 3), () => _updateState(BackupState.LoggedIn));
    } catch (e) {
      _setError('Restore failed: $e');
    }
  }

  // Dummy methods for deprecated Google Drive sign-in
  Future<void> signIn() async {
     _setError('Google Drive backup is no longer supported. Backups are now automatic with your Nexus account.');
  }

  Future<void> signOut() async {
     _setError('Google Drive backup is no longer supported. Backups are now automatic with your Nexus account.');
  }

  void _updateState(BackupState newState) {
    if (_state == newState && newState != BackupState.Success) return;
    _state = newState;
    if (newState == BackupState.Error) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_state == BackupState.Error) {
          _updateState(BackupState.LoggedIn);
        }
      });
    }
    notifyListeners();
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    _updateState(BackupState.Error);
  }
}
