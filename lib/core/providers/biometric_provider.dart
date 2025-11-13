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

  // Getters
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

  /// Initialize biometric settings
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

  /// Load biometric capabilities from device
  Future<void> _loadBiometricCapabilities() async {
    _isBiometricAvailable = await _biometricService.isBiometricAvailable();
    if (_isBiometricAvailable) {
      _availableBiometrics = await _biometricService.getAvailableBiometrics();
    }
  }

  /// Load current settings
  Future<void> _loadSettings() async {
    _isBiometricEnabled = await _biometricService.isBiometricEnabled();
    _isAppLockEnabled = await _biometricService.isAppLockEnabled();
    _isSensitiveOperationsEnabled = await _biometricService
        .isSensitiveOperationsBiometricEnabled();
    notifyListeners();
  }

  /// Setup biometric authentication
  Future<bool> setupBiometric() async {
    _setLoading(true);
    try {
      final result = await _biometricService.setupBiometric();
      if (result.isSuccess) {
        await _loadSettings();
        _clearError();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to setup biometric: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enable/disable all biometric features with single authentication
  Future<void> setAllBiometricFeatures(bool enabled) async {
    if (!_isBiometricAvailable) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    // Always require authentication to change security settings.
    final reason = enabled
        ? 'Please authenticate to enable biometric security features'
        : 'Please authenticate to disable biometric security features';

    final authenticated = await _biometricService.authenticate(reason: reason);

    if (!authenticated) {
      _setError('Authentication failed. Settings remain unchanged.');
      // Important: Do not proceed if authentication fails.
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

  /// Authenticate for app access
  Future<bool> authenticateForAppAccess() async {
    try {
      return await _biometricService.authenticateForAppAccess();
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    }
  }

  /// Authenticate for sensitive operations
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

  /// Refresh biometric capabilities and settings
  Future<void> refresh() async {
    await initialize();
  }

  // Helper methods
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
    notifyListeners();
  }
}
