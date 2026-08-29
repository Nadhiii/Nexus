import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';

class BiometricProvider extends ChangeNotifier {
  final BiometricService _biometricService = BiometricService();

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isAppLockEnabled = false;
  bool _isSensitiveOperationsEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isSensitiveOperationsEnabled => _isSensitiveOperationsEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  String get biometricTypeDescription =>
      _biometricService.getBiometricTypeDescription(_availableBiometrics);

  String get biometricIcon =>
      _biometricService.getBiometricIcon(_availableBiometrics);

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadBiometricCapabilities();
      await _loadSettings();
      _isInitialized = true;
      _clearError();
    } catch (e) {
      _setError('Failed to initialize biometric settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadBiometricCapabilities() async {
    _isBiometricAvailable = await _biometricService.isBiometricAvailable();
    _availableBiometrics = _isBiometricAvailable
        ? await _biometricService.getAvailableBiometrics()
        : [];
  }

  Future<void> _loadSettings() async {
    _isBiometricEnabled = await _biometricService.isBiometricEnabled();
    _isAppLockEnabled = await _biometricService.isAppLockEnabled();
    _isSensitiveOperationsEnabled =
        await _biometricService.isSensitiveOperationsBiometricEnabled();

    // Repair older/inconsistent preference states. The app-lock switch is
    // controlled by the single "Biometric Lock" setting in MoreScreen.
    if (_isBiometricEnabled != _isAppLockEnabled) {
      _isAppLockEnabled = _isBiometricEnabled;
      await _biometricService.setAppLockEnabled(_isBiometricEnabled);
    }
  }

  Future<bool> setupBiometric() async {
    _setLoading(true);
    try {
      final result = await _biometricService.setupBiometric();
      if (result.isSuccess) {
        await _loadSettings();
        _clearError();
        return true;
      }

      _setError(result.message);
      return false;
    } catch (e) {
      _setError('Failed to setup biometric: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setAllBiometricFeatures(bool enabled) async {
    if (!_isBiometricAvailable) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: enabled
          ? 'Please authenticate to enable biometric security features'
          : 'Please authenticate to disable biometric security features',
    );

    if (!authenticated) {
      _setError('Authentication failed. Settings remain unchanged.');
      return;
    }

    try {
      await _biometricService.setBiometricEnabled(enabled);
      await _biometricService.setAppLockEnabled(enabled);
      await _biometricService.setSensitiveOperationsBiometricEnabled(enabled);

      _isBiometricEnabled = enabled;
      _isAppLockEnabled = enabled;
      _isSensitiveOperationsEnabled = enabled;

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update biometric settings: $e');
    }
  }

  Future<bool> authenticateForAppAccess() async {
    try {
      if (!_isBiometricEnabled && !_isAppLockEnabled) {
        return true;
      }

      return await _biometricService.authenticateForAppAccess();
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    }
  }

  Future<bool> authenticateForSensitiveOperation({
    String operation = 'sensitive operation',
  }) async {
    try {
      return await _biometricService.authenticateForSensitiveOperation(
        operation: operation,
      );
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    }
  }

  Future<void> refresh() => initialize();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

extension on BiometricSetupResult {
  bool get isSuccess => this == BiometricSetupResult.success;
}
