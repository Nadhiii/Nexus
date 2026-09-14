import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTAUpdateService {
  // ---------------------------------------------------------------------
  // GitHub Releases configuration
  // ---------------------------------------------------------------------
  static const String _githubOwner = 'Nadhiii';
  static const String _githubRepo = 'Nexus-APK';

  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  static const String _allReleasesUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases';

  static const String _betaPrefKey = 'ota_beta_updates_enabled';

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  Stream<int> get progressStream => _progressController.stream;

  bool _showingNotification = false;

  // Dio instance for managing the download
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  // -----------------------------------------------------------------------
  // Beta channel preference
  // -----------------------------------------------------------------------

  Future<bool> isBetaEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_betaPrefKey) ?? false;
  }

  Future<void> setBetaEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaPrefKey, value);
  }

  // -----------------------------------------------------------------------
  // Update check
  // -----------------------------------------------------------------------

  Future<int?> fetchApkFileSize(String apkUrl) async {
    try {
      final response = await http.head(Uri.parse(apkUrl));
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          return int.tryParse(contentLength);
        }
      }
    } catch (e) {
      debugPrint('OTA: Failed to fetch APK file size: $e');
    }
    return null;
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  /// Runs [checkForUpdate] and, if a newer release exists, shows a
  /// notification via [showSimpleNotification]. Never throws — safe to call
  /// from app startup or from a background isolate (e.g. workmanager), where
  /// an uncaught exception would otherwise crash the task silently.
  Future<void> checkAndNotifyOnStartup(String currentVersion) async {
    try {
      final result = await checkForUpdate(currentVersion);
      if (result != null) {
        final version = result['latest_version'];
        await showSimpleNotification(
          'Update available',
          'Nexus $version is ready to download.',
        );
      }
    } catch (e) {
      debugPrint('OTA: checkAndNotifyOnStartup failed silently — $e');
    }
  }

  /// Checks GitHub Releases for a newer version than [currentVersion].
  ///
  /// - Stable channel (`betaEnabled: false`, the default) hits `/releases/latest`.
  ///   If that 404s (e.g. a transient GitHub propagation gap, or a moment
  ///   where only pre-releases exist), it falls back to scanning the full
  ///   `/releases` list for the newest non-draft, non-prerelease entry.
  /// - Beta channel (`betaEnabled: true`) hits `/releases` and takes the
  ///   first usable entry (draft-excluded, must have an .apk asset).
  ///
  /// Returns a map with `latest_version` and `apk_url` if a newer release
  /// is found, or `null` if already up to date / nothing usable was found.
  Future<Map<String, dynamic>?> checkForUpdate(
    String currentVersion, {
    bool? betaEnabled,
  }) async {
    try {
      final useBeta = betaEnabled ?? await isBetaEnabled();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic>? release;

      if (!useBeta) {
        release = await _fetchLatestStableRelease(timestamp);
      } else {
        release = await _fetchLatestBetaRelease(timestamp);
      }

      if (release == null) {
        debugPrint('OTA: No usable release found.');
        return null;
      }

      final String rawTag = (release['tag_name'] ?? '').toString().trim();
      final String apkUrl = _findApkAssetUrl(release) ?? '';

      if (rawTag.isEmpty || apkUrl.isEmpty) {
        debugPrint('OTA: Release missing tag_name or a .apk asset — skipping.');
        return null;
      }

      final bool updateAvailable = _isNewerVersion(rawTag, currentVersion);

      debugPrint(
        'OTA: Latest Tag: "$rawTag" | Current Version: "$currentVersion" | Update Available: $updateAvailable | beta=$useBeta',
      );

      if (updateAvailable) {
        return {
          'latest_version': rawTag,
          'apk_url': apkUrl,
          'is_prerelease': release['prerelease'] == true,
          'release_notes': release['body'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('OTA Check Error: $e');
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchLatestStableRelease(int timestamp) async {
    final latestResponse = await http.get(
      Uri.parse('$_latestReleaseUrl?t=$timestamp'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (latestResponse.statusCode == 200) {
      debugPrint('OTA: Raw GitHub Response: ${latestResponse.body}');
      return json.decode(latestResponse.body) as Map<String, dynamic>;
    }

    if (latestResponse.statusCode == 404) {
      debugPrint(
        'OTA: /releases/latest returned 404, falling back to /releases list.',
      );

      final allResponse = await http.get(
        Uri.parse('$_allReleasesUrl?t=$timestamp'),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (allResponse.statusCode != 200) {
        debugPrint(
          'OTA: GitHub API error ${allResponse.statusCode} on fallback list.',
        );
        return null;
      }

      debugPrint(
        'OTA: Raw GitHub Response (fallback list): ${allResponse.body}',
      );
      final list = json.decode(allResponse.body) as List<dynamic>;
      final stableOnly = list
          .cast<Map<String, dynamic>>()
          .where((r) => r['prerelease'] != true)
          .toList();

      return _firstUsableRelease(stableOnly);
    }

    debugPrint('OTA: GitHub API error ${latestResponse.statusCode}');
    return null;
  }

  Future<Map<String, dynamic>?> _fetchLatestBetaRelease(int timestamp) async {
    final response = await http.get(
      Uri.parse('$_allReleasesUrl?t=$timestamp'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      debugPrint('OTA: GitHub API error ${response.statusCode}');
      return null;
    }

    debugPrint('OTA: Raw GitHub Response: ${response.body}');
    final decoded = json.decode(response.body) as List<dynamic>;
    return _firstUsableRelease(decoded.cast<Map<String, dynamic>>());
  }

  Map<String, dynamic>? _firstUsableRelease(
    List<Map<String, dynamic>> releases,
  ) {
    for (final release in releases) {
      if (release['draft'] == true) continue;
      if (_findApkAssetUrl(release) != null) return release;
    }
    return null;
  }

  String? _findApkAssetUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List<dynamic>? ?? const [];
    for (final item in assets) {
      final asset = item as Map<String, dynamic>;
      final name = (asset['name'] ?? '').toString();
      if (name.toLowerCase().endsWith('.apk')) {
        return (asset['browser_download_url'] ?? '').toString();
      }
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Version comparison helpers
  // -----------------------------------------------------------------------

  String _extractBaseVersion(String raw) {
    var value = raw.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    return value.split('+').first.trim();
  }

  int _extractBuildNumber(String raw) {
    if (!raw.contains('+')) return 0;
    return int.tryParse(raw.split('+').last.trim()) ?? 0;
  }

  bool _isNewerVersion(String remoteTag, String localVersion) {
    final remoteBase = _extractBaseVersion(remoteTag);
    final localBase = _extractBaseVersion(localVersion);

    final remoteParts = remoteBase
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final localParts = localBase
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    while (remoteParts.length < 3) remoteParts.add(0);
    while (localParts.length < 3) localParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }

    final remoteBuild = _extractBuildNumber(remoteTag);
    final localBuild = _extractBuildNumber(localVersion);

    return remoteBuild > localBuild;
  }

  // -----------------------------------------------------------------------
  // Download + install
  // -----------------------------------------------------------------------

  Future<void> startOTAUpdate(
    BuildContext context,
    String apkUrl, {
    bool showNotification = false,
  }) async {
    try {
      _showingNotification = showNotification;
      _cancelToken = CancelToken();

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        debugPrint('OTA: External storage unavailable.');
        _progressController.add(-1);
        showSimpleNotification('Update failed', 'Storage unavailable.');
        return;
      }
      final savePath = '${dir.path}/Nexus_Update.apk';

      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        apkUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = ((received / total) * 100).toInt();
            _progressController.add(progress);

            if (_showingNotification) {
              _showProgressNotification(progress);
            }
            debugPrint('OTA: Downloading... $progress%');
          }
        },
      );

      debugPrint('OTA: Download complete. Triggering install...');
      _progressController.add(100);
      showSimpleNotification(
        'Update ready',
        'Tap to install the Nexus update.',
      );

      final result = await OpenFile.open(savePath);
      debugPrint('OTA Install Result: ${result.message}');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('OTA: Download securely destroyed by user.');
      } else {
        debugPrint('OTA Start Error: $e');
        _progressController.add(-1);
        showSimpleNotification('Update failed', 'Could not download update.');
      }
    }
  }

  void cancelOTA() {
    _cancelToken?.cancel('Cancelled by user');
    _progressController.add(-1);
    debugPrint('OTA: Cancellation signal sent');
  }

  void setShowNotification(bool value) {
    _showingNotification = value;
  }

  Future<void> _showProgressNotification(int progress) async {
    final android = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Shows OTA update progress',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: true,
    );
    final notification = NotificationDetails(android: android);
    await notificationsPlugin.show(
      id: 0,
      title: 'Downloading update',
      body: '$progress%',
      notificationDetails: notification,
    );
  }

  Future<void> showSimpleNotification(String title, String body) async {
    final android = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Shows OTA update status',
      importance: Importance.max,
      priority: Priority.high,
    );
    final notification = NotificationDetails(android: android);
    await notificationsPlugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: notification,
    );
  }

  void dispose() {
    _cancelToken?.cancel();
    _progressController.close();
  }
}
