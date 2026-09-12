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
  // Replace with your actual GitHub username/org and repo name.
  // The repo must have Releases published with the .apk attached as a
  // release asset (either uploaded manually or via a CI step) for this
  // to find anything.
  static const String _githubOwner = 'YOUR_GITHUB_USERNAME';
  static const String _githubRepo = 'YOUR_REPO_NAME';

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

  /// Whether the user has opted in to receiving pre-release ("beta") builds.
  /// Persisted so the setting survives app restarts.
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

  /// Checks GitHub Releases for a newer version than [currentVersion].
  ///
  /// - Stable channel (`betaEnabled: false`, the default) hits
  ///   `/releases/latest`, which GitHub guarantees excludes pre-releases.
  /// - Beta channel (`betaEnabled: true`) hits `/releases` (all releases,
  ///   newest first) and takes the first usable entry — this includes
  ///   pre-releases, so beta-opted-in users see them as soon as they're
  ///   published, stable users never do.
  ///
  /// Returns a map with `latest_version` and `apk_url` if a newer release
  /// is found, or `null` if already up to date / nothing usable was found.
  /// The return shape matches the previous JSON-manifest version so
  /// existing call sites (e.g. the More screen) don't need to change.
  Future<Map<String, dynamic>?> checkForUpdate(
    String currentVersion, {
    bool? betaEnabled,
  }) async {
    try {
      final useBeta = betaEnabled ?? await isBetaEnabled();
      final url = useBeta ? _allReleasesUrl : _latestReleaseUrl;

      final response = await http.get(
        Uri.parse(url),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        debugPrint('OTA: GitHub API error ${response.statusCode}');
        return null;
      }

      debugPrint('OTA: Raw GitHub Response: ${response.body}');
      final decoded = json.decode(response.body);

      // /releases/latest returns a single object; /releases returns a
      // list ordered newest-first. Normalize to a single "release" map.
      final Map<String, dynamic>? release = useBeta
          ? _firstUsableRelease(decoded as List<dynamic>)
          : decoded as Map<String, dynamic>;

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

      // Strip a leading "v" (GitHub tags are commonly "v1.2.0") and any
      // build metadata suffix ("1.2.0+4") before comparing, same as the
      // JSON-manifest version did.
      final String normalizedLatest = _normalizeVersion(rawTag);
      final String normalizedCurrent = _normalizeVersion(currentVersion);

      debugPrint(
        'OTA: Parsed Latest Version: "$normalizedLatest" | Local Version: "$normalizedCurrent" | beta=$useBeta',
      );

      if (normalizedLatest.isNotEmpty &&
          normalizedLatest != normalizedCurrent) {
        return {
          'latest_version': normalizedLatest,
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

  /// Picks the newest release from `/releases` that actually has a usable
  /// .apk asset attached. Skips draft releases outright (GitHub includes
  /// drafts in this endpoint for repo collaborators, but they're not
  /// meant to be installed by end users) and falls through to older
  /// entries if the newest one has no APK attached yet (e.g. release
  /// notes published before a CI build finished uploading the asset).
  Map<String, dynamic>? _firstUsableRelease(List<dynamic> releases) {
    for (final item in releases) {
      final release = item as Map<String, dynamic>;
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

  String _normalizeVersion(String raw) {
    var value = raw.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    return value.split('+').first.trim();
  }

  // -----------------------------------------------------------------------
  // Download + install (unchanged from the JSON-manifest version)
  // -----------------------------------------------------------------------

  Future<void> startOTAUpdate(
    BuildContext context,
    String apkUrl, {
    bool showNotification = false,
  }) async {
    try {
      _showingNotification = showNotification;
      _cancelToken = CancelToken();

      // External storage, not getTemporaryDirectory() — Android's package
      // installer cannot access internal app cache paths, which caused
      // the install to silently fail after a successful download.
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        debugPrint('OTA: External storage unavailable.');
        _progressController.add(-1);
        showSimpleNotification('Update failed', 'Storage unavailable.');
        return;
      }
      final savePath = '${dir.path}/Nexus_Update.apk';

      // Clean up any old partial downloads
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Start the download with Dio
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

      // Download finished successfully
      debugPrint('OTA: Download complete. Triggering install...');
      _progressController.add(100);
      showSimpleNotification(
        'Update ready',
        'Tap to install the Nexus update.',
      );

      // Open the APK to trigger Android's package installer.
      // Note: on Android 8+ the user must have granted this app the
      // "install unknown apps" permission at least once, or OpenFile.open
      // will surface Android's own permission prompt instead of the
      // installer directly — that's expected OS behaviour, not a bug.
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
