import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _sensitiveOperationsKey =
      'sensitive_operations_biometric';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    try {
      // For mobile platforms, check actual biometric availability
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        // First try to get available biometrics (sometimes this works when canCheckBiometrics doesn't)
        try {
          final biometrics = await _localAuth.getAvailableBiometrics();
          if (biometrics.isNotEmpty) {
            debugPrint('Found available biometrics: $biometrics');
            return true;
          }
        } catch (e) {
          debugPrint('getAvailableBiometrics failed: $e');
        }

        // Then try the standard checks
        try {
          final bool isAvailable = await _localAuth.canCheckBiometrics;
          final bool isDeviceSupported = await _localAuth.isDeviceSupported();
          debugPrint(
            'Biometric availability - canCheckBiometrics: $isAvailable, isDeviceSupported: $isDeviceSupported',
          );
          return isAvailable || isDeviceSupported; // Either should work
        } catch (e) {
          debugPrint('Standard biometric checks failed: $e');
        }

        // If all else fails, assume biometrics are available on Android devices
        // since most modern Android devices have some form of biometric authentication
        if (defaultTargetPlatform == TargetPlatform.android) {
          debugPrint('Assuming biometrics available on Android device');
          return true;
        }
      }

      // For desktop platforms (during development), simulate availability in debug mode
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return kDebugMode; // Only available in debug mode for desktop
      }

      return false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException checking biometric availability: $e');
      // On Android, if we get a channel error but we're on a mobile platform,
      // let's assume biometrics might still work and let the user try
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('Assuming biometrics might work despite channel error');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      // For mobile platforms, get actual available biometrics
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('Available biometrics: $biometrics');
        return biometrics;
      }

      // For desktop in debug mode, simulate fingerprint availability
      if (kDebugMode &&
          (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        return [BiometricType.fingerprint];
      }

      return [];
    } on PlatformException catch (e) {
      debugPrint('PlatformException getting available biometrics: $e');
      // If we get a channel error on Android, assume common biometric types are available
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint(
          'Assuming fingerprint available on Android despite channel error',
        );
        return [BiometricType.fingerprint];
      }
      return [];
    } catch (e) {
      debugPrint('Unexpected error getting available biometrics: $e');
      // Return a default list if we can't determine available types
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return [BiometricType.fingerprint]; // Assume fingerprint as fallback
      }
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
  String reason = 'Please authenticate to access this feature',
  bool biometricOnly = false, // kept for API compatibility, no longer passed to local_auth
}) async {
  try {
    // Desktop debug simulation — unchanged
    if (kDebugMode &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('Attempting biometric authentication with reason: $reason');

      // v3: options parameter removed, no AuthenticationOptions
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      debugPrint('Authentication result: $didAuthenticate');
      return didAuthenticate;
    }

    return false;
  } on PlatformException catch (e) {
    debugPrint('PlatformException during authentication: $e');
    if (e.code == 'NotAvailable') {
      debugPrint('Biometric authentication is not available on this device');
    } else if (e.code == 'NotEnrolled') {
      debugPrint('No biometric credentials are enrolled');
    } else if (e.code == 'LockedOut') {
      debugPrint('Biometric authentication is temporarily locked out');
    } else if (e.code == 'channel-error') {
      debugPrint('Channel communication error');
    } else if (e.code == 'no_fragment_activity') {
      debugPrint('MainActivity needs to extend FlutterFragmentActivity');
    }
    return false;
  } catch (e) {
    debugPrint('Unexpected error during authentication: $e');
    return false;
  }
}
  /// Check if biometric authentication is enabled for the app
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable/disable biometric authentication for the app
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Check if app lock is enabled
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  /// Enable/disable app lock
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  /// Check if biometric authentication is required for sensitive operations
  Future<bool> isSensitiveOperationsBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sensitiveOperationsKey) ?? false;
  }

  /// Enable/disable biometric authentication for sensitive operations
  Future<void> setSensitiveOperationsBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sensitiveOperationsKey, enabled);
  }

  /// Get user-friendly biometric type description
  String getBiometricTypeDescription(List<BiometricType> types) {
    if (types.isEmpty) {
      return 'No biometric authentication available';
    }

    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris scan';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric authentication';
    } else if (types.contains(BiometricType.weak)) {
      return 'Biometric authentication (weak)';
    } else {
      return 'Biometric authentication';
    }
  }

  /// Get biometric icon based on available types
  String getBiometricIcon(List<BiometricType> types) {
    if (types.isEmpty) {
      return '🔒';
    }

    if (types.contains(BiometricType.face)) {
      return '👤';
    } else if (types.contains(BiometricType.fingerprint)) {
      return '👆';
    } else if (types.contains(BiometricType.iris)) {
      return '👁️';
    } else {
      return '🔐';
    }
  }

  /// Authenticate for sensitive operations (transactions, account changes, etc.)
  Future<bool> authenticateForSensitiveOperation({
    String operation = 'sensitive operation',
  }) async {
    final bool isEnabled = await isSensitiveOperationsBiometricEnabled();
    if (!isEnabled) {
      return true; // Allow operation if biometric is not required
    }

    return await authenticate(
      reason: 'Please authenticate to proceed with $operation',
      biometricOnly: false,
    );
  }

  /// Authenticate for app access
  Future<bool> authenticateForAppAccess() async {
    final bool isEnabled = await isAppLockEnabled();
    if (!isEnabled) {
      return true; // Allow access if app lock is not enabled
    }

    return await authenticate(
      reason: 'Please authenticate to access Nexus',
      biometricOnly: false,
    );
  }

  /// Setup biometric authentication (guide user through enabling it)
  Future<BiometricSetupResult> setupBiometric() async {
    try {
      // Check if biometric is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricSetupResult.notAvailable;
      }

      // Check if any biometrics are enrolled
      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricSetupResult.notEnrolled;
      }

      // Test authentication
      final bool authenticated = await authenticate(
        reason: 'Please authenticate to enable biometric security for Nexus',
        biometricOnly: false,
      );

      if (authenticated) {
        await setBiometricEnabled(true);
        return BiometricSetupResult.success;
      } else {
        return BiometricSetupResult.authenticationFailed;
      }
    } catch (e) {
      debugPrint('Error setting up biometric: $e');
      return BiometricSetupResult.error;
    }
  }
}

enum BiometricSetupResult {
  success,
  notAvailable,
  notEnrolled,
  authenticationFailed,
  error,
}

extension BiometricSetupResultExtension on BiometricSetupResult {
  String get message {
    switch (this) {
      case BiometricSetupResult.success:
        return 'Biometric authentication enabled successfully!';
      case BiometricSetupResult.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricSetupResult.notEnrolled:
        return 'No biometric credentials are enrolled. Please set up fingerprint or face recognition in your device settings.';
      case BiometricSetupResult.authenticationFailed:
        return 'Authentication failed. Please try again.';
      case BiometricSetupResult.error:
        return 'An error occurred while setting up biometric authentication.';
    }
  }

  bool get isSuccess => this == BiometricSetupResult.success;
}
