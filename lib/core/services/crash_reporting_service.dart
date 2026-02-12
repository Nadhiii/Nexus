import 'dart:async';
import 'dart:isolate';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for crash reporting and error tracking using Firebase Crashlytics
///
/// This service provides:
/// - Automatic crash reporting
/// - Manual error logging
/// - User identification for better debugging
/// - Custom keys for context
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _isInitialized = false;

  /// Initialize Crashlytics and set up error handlers
  ///
  /// Call this in main() before runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only enable in release mode
    if (kReleaseMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } else {
      // Disable in debug mode to avoid noise
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }

    // Catch Flutter errors
    FlutterError.onError = (errorDetails) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      } else {
        // In debug mode, print to console
        FlutterError.dumpErrorToConsole(errorDetails);
      }
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    // Catch errors from isolates
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        if (kReleaseMode) {
          await FirebaseCrashlytics.instance.recordError(
            errorAndStacktrace.first,
            errorAndStacktrace.last,
            fatal: true,
          );
        }
      }).sendPort,
    );

    _isInitialized = true;
  }

  /// Set the user ID for crash reports
  ///
  /// Call this after user authentication
  Future<void> setUserId(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Clear user ID (e.g., on logout)
  Future<void> clearUserId() async {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  /// Set custom key-value pairs for additional context
  ///
  /// Example: setCustomKey('subscription_type', 'premium')
  Future<void> setCustomKey(String key, dynamic value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Log a message to Crashlytics
  ///
  /// These messages appear in crash reports to help debug
  Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Record a non-fatal error
  ///
  /// Use for caught exceptions that don't crash the app
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object>? information,
  }) async {
    if (!kReleaseMode) {
      // In debug mode, just print
      print('🔴 Error: $exception');
      if (stack != null) print(stack);
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
      information: information ?? [],
    );
  }

  /// Force a test crash (debug only)
  ///
  /// Use to verify Crashlytics is working
  void testCrash() {
    if (kDebugMode) {
      print('⚠️ Test crash - Crashlytics disabled in debug mode');
      return;
    }
    FirebaseCrashlytics.instance.crash();
  }
}

/// Extension to wrap functions with error reporting
extension CrashReportingExtension<T> on Future<T> {
  /// Wrap a future with automatic error reporting
  ///
  /// Usage:
  /// ```dart
  /// await myAsyncFunction().withErrorReporting('Loading user data');
  /// ```
  Future<T> withErrorReporting(String operation) async {
    try {
      return await this;
    } catch (e, stack) {
      await CrashReportingService().recordError(
        e,
        stack,
        reason: 'Error during: $operation',
      );
      rethrow;
    }
  }

  /// Wrap a future with error reporting that returns null on failure
  ///
  /// Usage:
  /// ```dart
  /// final result = await myAsyncFunction().withErrorReportingOrNull('Loading user data');
  /// ```
  Future<T?> withErrorReportingOrNull(String operation) async {
    try {
      return await this;
    } catch (e, stack) {
      await CrashReportingService().recordError(
        e,
        stack,
        reason: 'Error during: $operation',
      );
      return null;
    }
  }
}

/// Mixin for widgets/providers that need error reporting
mixin CrashReportingMixin {
  CrashReportingService get crashReporting => CrashReportingService();

  /// Report an error with context
  Future<void> reportError(
    dynamic error,
    StackTrace? stack, {
    required String context,
  }) async {
    await crashReporting.recordError(error, stack, reason: context);
  }

  /// Log a debug message
  Future<void> logMessage(String message) async {
    await crashReporting.log(message);
  }
}
