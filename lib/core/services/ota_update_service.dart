import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OTAUpdateService {
  static const String updateUrl = 'https://mahanadhi.space/update.json';
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  Stream<int> get progressStream => _progressController.stream;

  bool _showingNotification = false;

  // Dio instances for managing the download
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

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

  Future<Map<String, dynamic>?> checkForUpdate(String currentVersion) async {
    try {
      final response = await http.get(Uri.parse(updateUrl));

      if (response.statusCode == 200) {
        debugPrint('OTA: Raw Server Response: ${response.body}');
        final data = json.decode(response.body);

        final String latestVersion =
            (data['version'] ?? data['latest_version'] ?? '').toString().trim();
        final String apkUrl = (data['url'] ?? data['apk_url'] ?? '')
            .toString()
            .trim();

        // FIX 1: Strip build metadata (e.g. "1.0.0+4" -> "1.0.0") before
        // comparing so PackageInfo build numbers don't cause false positives.
        final String normalizedLatest = latestVersion.split('+').first.trim();
        final String normalizedCurrent = currentVersion.split('+').first.trim();

        debugPrint(
          'OTA: Parsed Server Version: "$normalizedLatest" | Local Version: "$normalizedCurrent"',
        );

        if (normalizedLatest.isNotEmpty &&
            normalizedLatest != normalizedCurrent) {
          return {'latest_version': normalizedLatest, 'apk_url': apkUrl};
        }
      } else {
        debugPrint('OTA: Server Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OTA Check Error: $e');
      rethrow;
    }
    return null;
  }

  Future<void> startOTAUpdate(
    BuildContext context,
    String apkUrl, {
    bool showNotification = false,
  }) async {
    try {
      _showingNotification = showNotification;
      _cancelToken = CancelToken();

      // FIX 2: Use external storage instead of getTemporaryDirectory().
      // Android's package installer cannot access internal app cache paths,
      // which caused the install to silently fail after a successful download.
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

      // Open the APK to trigger Android's package installer
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
