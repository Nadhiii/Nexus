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

  // Getters
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isSensitiveOperationsEnabled => _isSensitiveOperationsEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (!_isBiometricAvailable && enabled) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    if (enabled) {
      // Test authentication before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Please authenticate to enable biometric security',
      );

      if (!authenticated) {
        _setError('Authentication failed. Biometric not enabled.');
        return;
      }
    }

    try {
      await _biometricService.setBiometricEnabled(enabled);
      _isBiometricEnabled = enabled;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update biometric setting: $e');
    }
  }

  /// Enable/disable all biometric features with single authentication
  Future<void> setAllBiometricFeatures(bool enabled) async {
    if (!_isBiometricAvailable && enabled) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    if (enabled) {
      // Single authentication for all features
      final authenticated = await _biometricService.authenticate(
        reason: 'Please authenticate to enable biometric security features',
      );

      if (!authenticated) {
        _setError('Authentication failed. Biometric features not enabled.');
        return;
      }
    }

    try {
      // Update all settings without additional authentication
      await _biometricService.setBiometricEnabled(enabled);
      await _biometricService.setAppLockEnabled(enabled);
      await _biometricService.setSensitiveOperationsBiometricEnabled(enabled);

      // Update local state
      _isBiometricEnabled = enabled;
      _isAppLockEnabled = enabled;
      _isSensitiveOperationsEnabled = enabled;

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update biometric settings: $e');
    }
  }

  /// Enable/disable app lock
  Future<void> setAppLockEnabled(bool enabled) async {
    if (!_isBiometricAvailable && enabled) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    if (enabled && !_isBiometricEnabled) {
      _setError('Please enable biometric authentication first');
      return;
    }

    if (enabled) {
      // Test authentication before enabling app lock
      final authenticated = await _biometricService.authenticate(
        reason: 'Please authenticate to enable app lock',
      );

      if (!authenticated) {
        _setError('Authentication failed. App lock not enabled.');
        return;
      }
    }

    try {
      await _biometricService.setAppLockEnabled(enabled);
      _isAppLockEnabled = enabled;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update app lock setting: $e');
    }
  }

  /// Enable/disable sensitive operations biometric
  Future<void> setSensitiveOperationsEnabled(bool enabled) async {
    if (!_isBiometricAvailable && enabled) {
      _setError('Biometric authentication is not available on this device');
      return;
    }

    if (enabled && !_isBiometricEnabled) {
      _setError('Please enable biometric authentication first');
      return;
    }

    if (enabled) {
      // Test authentication before enabling
      final authenticated = await _biometricService.authenticate(
        reason:
            'Please authenticate to enable biometric security for sensitive operations',
      );

      if (!authenticated) {
        _setError('Authentication failed. Setting not enabled.');
        return;
      }
    }

    try {
      await _biometricService.setSensitiveOperationsBiometricEnabled(enabled);
      _isSensitiveOperationsEnabled = enabled;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update sensitive operations setting: $e');
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

  /// Test biometric authentication
  Future<bool> testAuthentication() async {
    if (!_isBiometricAvailable) {
      _setError('Biometric authentication is not available on this device');
      return false;
    }

    try {
      final result = await _biometricService.authenticate(
        reason: 'Testing biometric authentication',
      );

      if (result) {
        _clearError();
      } else {
        _setError('Authentication was cancelled or failed');
      }

      return result;
    } catch (e) {
      _setError('Authentication test failed: $e');
      return false;
    }
  }

  /// Refresh biometric capabilities and settings
  Future<void> refresh() async {
    await initialize();
  }

  /// Check if any biometric features are enabled
  bool get hasAnyBiometricEnabled =>
      _isBiometricEnabled || _isAppLockEnabled || _isSensitiveOperationsEnabled;

  /// Get security level description
  String get securityLevelDescription {
    if (!_isBiometricAvailable) {
      return 'Biometric security not available';
    }

    if (_isAppLockEnabled && _isSensitiveOperationsEnabled) {
      return 'Maximum security - App lock and sensitive operations protected';
    } else if (_isAppLockEnabled) {
      return 'High security - App access protected';
    } else if (_isSensitiveOperationsEnabled) {
      return 'Medium security - Sensitive operations protected';
    } else if (_isBiometricEnabled) {
      return 'Basic security - Biometric available';
    } else {
      return 'No biometric security enabled';
    }
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
