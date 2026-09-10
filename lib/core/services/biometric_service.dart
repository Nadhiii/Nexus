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

  Future<bool> isBiometricAvailable() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final biometrics = await _localAuth.getAvailableBiometrics();
          if (biometrics.isNotEmpty) {
            debugPrint('Found available biometrics: $biometrics');
            return true;
          }
        } catch (e) {
          debugPrint('getAvailableBiometrics failed: $e');
        }

        try {
          final canCheck = await _localAuth.canCheckBiometrics;
          final supported = await _localAuth.isDeviceSupported();
          debugPrint(
            'Biometric availability - canCheckBiometrics: $canCheck, '
            'isDeviceSupported: $supported',
          );
          return canCheck || supported;
        } catch (e) {
          debugPrint('Standard biometric checks failed: $e');
        }

        return defaultTargetPlatform == TargetPlatform.android;
      }

      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return kDebugMode;
      }

      return false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException checking biometric availability: $e');
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      debugPrint('Unexpected error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return await _localAuth.getAvailableBiometrics();
      }

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
      return defaultTargetPlatform == TargetPlatform.android
          ? [BiometricType.fingerprint]
          : [];
    } catch (e) {
      debugPrint('Unexpected error getting available biometrics: $e');
      return defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS
          ? [BiometricType.fingerprint]
          : [];
    }
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to access this feature',
    bool biometricOnly = false,
  }) async {
    try {
      if (kDebugMode &&
          (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        return false;
      }

      debugPrint('Attempting biometric authentication: $reason');

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      debugPrint('Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('PlatformException during authentication: $e');
      switch (e.code) {
        case 'NotAvailable':
          debugPrint('Biometric authentication is not available.');
          break;
        case 'NotEnrolled':
          debugPrint('No biometric credentials are enrolled.');
          break;
        case 'LockedOut':
          debugPrint('Biometric authentication is temporarily locked out.');
          break;
        case 'channel-error':
          debugPrint('Channel communication error.');
          break;
        case 'no_fragment_activity':
          debugPrint(
            'MainActivity must extend FlutterFragmentActivity for local_auth.',
          );
          break;
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error during authentication: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  Future<bool> isSensitiveOperationsBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sensitiveOperationsKey) ?? false;
  }

  Future<void> setSensitiveOperationsBiometricEnabled(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_sensitiveOperationsKey, enabled);
}

  String getBiometricTypeDescription(List<BiometricType> types) {
    if (types.isEmpty) return 'No biometric authentication available';
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris scan';
    return 'Biometric authentication';
  }

  String getBiometricIcon(List<BiometricType> types) {
    if (types.isEmpty) return '🔒';
    if (types.contains(BiometricType.face)) return '👤';
    if (types.contains(BiometricType.fingerprint)) return '👆';
    if (types.contains(BiometricType.iris)) return '👁️';
    return '🔐';
  }

  Future<bool> authenticateForSensitiveOperation({
    String operation = 'sensitive operation',
  }) async {
    if (!await isSensitiveOperationsBiometricEnabled()) {
      return true;
    }

    return authenticate(
      reason: 'Please authenticate to proceed with $operation',
    );
  }

  /// Performs the actual app-unlock authentication.
  ///
  /// The caller decides whether app lock is enabled. This method must never
  /// silently bypass authentication because a second preference flag is false.
  Future<bool> authenticateForAppAccess() {
    return authenticate(reason: 'Please authenticate to access Nexus');
  }

  Future<BiometricSetupResult> setupBiometric() async {
    try {
      if (!await isBiometricAvailable()) {
        return BiometricSetupResult.notAvailable;
      }

      final available = await getAvailableBiometrics();
      if (available.isEmpty) {
        return BiometricSetupResult.notEnrolled;
      }

      final authenticated = await authenticate(
        reason: 'Please authenticate to enable biometric security for Nexus',
      );

      if (!authenticated) {
        return BiometricSetupResult.authenticationFailed;
      }

      await setBiometricEnabled(true);
      await setAppLockEnabled(true);
      await setSensitiveOperationsBiometricEnabled(true);

      return BiometricSetupResult.success;
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
        return 'Biometric authentication failed.';
      case BiometricSetupResult.error:
        return 'Unable to configure biometric authentication.';
    }
  }
}
