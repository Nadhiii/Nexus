import 'dart:async';
import 'package:flutter/services.dart';

/// Listens for platform intents (e.g., widget clicks) and exposes navigation events.
class IntentNavigationService {
  static const MethodChannel _channel = MethodChannel(
    'com.mahanadhi.nexus/intent',
  );

  static final StreamController<int> _tabController =
      StreamController<int>.broadcast();

  static bool _initialized = false;

  static Stream<int> get tabStream => _tabController.stream;

  static void initialize() {
    if (_initialized) { return; }
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateToTab') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final tabIndex = args?['tabIndex'];
        if (tabIndex is int) {
          _tabController.add(tabIndex);
        }
      }
    });
  }
}
