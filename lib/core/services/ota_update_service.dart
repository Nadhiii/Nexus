import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OTAUpdateService {
  static const String updateUrl =
      'https://mahanadhi.space/update.json'; // TODO: Replace with endpoint
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
    final response = await http.get(Uri.parse(updateUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['latest_version'] != currentVersion) {
        return data;
      }
    }
    return null;
  }

  Future<void> startOTAUpdate(BuildContext context, String apkUrl) async {
    try {
      OtaUpdate().execute(apkUrl, destinationFilename: 'app-latest.apk').listen(
        (event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            _showProgressNotification(event.value ?? '0');
          } else if (event.status == OtaStatus.INSTALLING) {
            showSimpleNotification(
              'Update ready',
              'Tap to install the update.',
            );
          } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
            showSimpleNotification(
              'Permission denied',
              'Storage permission required for update.',
            );
          }
        },
      );
    } catch (e) {
      showSimpleNotification('Update failed', 'Could not download update.');
    }
  }

  Future<void> _showProgressNotification(String progress) async {
    final android = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Shows OTA update progress',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: int.tryParse(progress) ?? 0,
      onlyAlertOnce: true,
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
}
