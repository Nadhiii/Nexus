import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../services/backup_service.dart';

enum BackupState { Uninitialized, LoggedOut, LoggedIn, InProgress, Success, Error }

class BackupProvider extends ChangeNotifier {
  late final BackupService _backupService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  BackupState _state = BackupState.Uninitialized;
  DateTime? _lastBackupTime;
  String? _error;
  Timer? _backupTimer;

  BackupState get state => _state;
  DateTime? get lastBackupTime => _lastBackupTime;
  String? get error => _error;
  bool get isLoggedIn => _state == BackupState.LoggedIn || _state == BackupState.InProgress || _state == BackupState.Success;
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  BackupProvider() {
    _backupService = BackupService(_googleSignIn);
    _initialize();
  }

  @override
  void dispose() {
    _backupTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Listen for subsequent changes
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account == null) {
        _updateState(BackupState.LoggedOut);
        _backupTimer?.cancel();
      } else {
        _updateState(BackupState.LoggedIn);
        fetchLastBackupTime();
        _startAutomaticBackups();
      }
    });

    // Handle the initial state explicitly
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        _updateState(BackupState.LoggedOut);
      } else {
        _updateState(BackupState.LoggedIn);
        fetchLastBackupTime();
        _startAutomaticBackups();
      }
    } catch (e) {
      _setError('Automatic sign-in failed. Please sign in manually.');
    }
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      _setError('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      _setError('Google Sign-Out failed: $e');
    }
  }

  Future<void> fetchLastBackupTime() async {
    try {
      final status = await _backupService.getBackupStatus();
      if (status['isLoggedIn']) {
        _lastBackupTime = status['lastBackup'] as DateTime?;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail is ok here
    }
  }

  Future<void> backupNow() async {
    if (!isLoggedIn) return;
    _updateState(BackupState.InProgress);
    try {
      await _backupService.createBackup();
      await fetchLastBackupTime();
      _updateState(BackupState.Success);
      Future.delayed(const Duration(seconds: 3), () => _updateState(BackupState.LoggedIn));
    } catch (e) {
      _setError('Backup failed: $e');
    }
  }

  Future<void> restoreNow() async {
    if (!isLoggedIn) return;
    final status = await _backupService.getBackupStatus();
    final fileId = status['fileId'];
    if (fileId == null) {
      _setError('No backup file found to restore.');
      return;
    }

    _updateState(BackupState.InProgress);
    try {
      await _backupService.restoreFromBackup(fileId);
      _updateState(BackupState.Success);
      Future.delayed(const Duration(seconds: 3), () => _updateState(BackupState.LoggedIn));
    } catch (e) {
      _setError('Restore failed: $e');
    }
  }

  void _startAutomaticBackups() {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      if (isLoggedIn) {
        await backupNow();
      }
    });
  }

  void _updateState(BackupState newState) {
    if (_state == newState && newState != BackupState.Success) return;
    _state = newState;
    if (newState == BackupState.Error) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_state == BackupState.Error) {
          if (_googleSignIn.currentUser != null) {
            _updateState(BackupState.LoggedIn);
          } else {
            _updateState(BackupState.LoggedOut);
          }
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
