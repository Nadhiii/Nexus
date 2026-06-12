import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../models/detected_transaction.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/top_snackbar.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('📨 FCM background message: ${message.messageId}');
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  NotificationService().handleNotificationPayload(response.payload);
}

class DetectionApprovalRequest {
  final String transactionId;
  final String source;

  const DetectionApprovalRequest({
    required this.transactionId,
    required this.source,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationProvider? _notificationProvider;
  final StreamController<DetectionApprovalRequest> _approvalRequestController =
      StreamController<DetectionApprovalRequest>.broadcast();
  bool _initialized = false;

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        'nexus_default_channel',
        'General Notifications',
        description: 'Budget alerts, reminders, and insights',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _scanStatusChannel =
      AndroidNotificationChannel(
        'nexus_scan_status_channel',
        'Transaction Scan Status',
        description: 'Shows live status while scanning for transactions',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _detectedPromptChannel =
      AndroidNotificationChannel(
        'nexus_detected_transaction_channel',
        'Detected Transaction Prompts',
        description: 'Prompts to review newly detected transactions',
        importance: Importance.high,
      );

  static const int _scanStatusNotificationId = 44001;

  Stream<DetectionApprovalRequest> get approvalRequestStream =>
      _approvalRequestController.stream;

  Future<void> initialize(NotificationProvider notificationProvider) async {
    if (_initialized) { return; }
    _notificationProvider = notificationProvider;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _setupLocalNotifications();
    await _setupMessageHandlers();
    await _syncFcmToken();

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      log('🔔 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting notification permission: $e');
      // Permission request failed, but don't crash - app can work without notifications
    }
  }

  Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      final iosSettings = DarwinInitializationSettings(
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            'detected_tx_prompt',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'log_it',
                'Log It',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          handleNotificationPayload(details.payload);
        },
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundNotificationResponse,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_defaultChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_scanStatusChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_detectedPromptChannel);

      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        handleNotificationPayload(
          launchDetails?.notificationResponse?.payload,
        );
      }
    } catch (e) {
      log('❌ Error setting up local notifications: $e');
      // Non-critical error - app can continue without local notifications
    }
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final appNotification = _mapToAppNotification(message);
    if (appNotification != null) {
      _notificationProvider?.addNotification(appNotification);
      await _showLocalNotification(appNotification);
    }
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final appNotification = _mapToAppNotification(message);
    if (appNotification != null) {
      _notificationProvider?.addNotification(appNotification);
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      _NotificationServiceConstants.channelId,
      _NotificationServiceConstants.channelName,
      channelDescription: _NotificationServiceConstants.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.message,
      notificationDetails: details,
      payload: notification.actionRoute,
    );
  }

  Future<void> sendLocalNotification(AppNotification notification) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      _defaultChannel.id,
      _defaultChannel.name,
      channelDescription: _defaultChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(notification.message),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a stable, collision-resistant ID derived from the notification id
    final localId = notification.id.hashCode & 0x7fffffff;

    await _localNotifications.show(
      localId,
      notification.title,
      notification.message,
      details,
      payload: notification.actionRoute,
    );
  }

  bool _isScanStatusEnabled() {
    return _notificationProvider?.liveScanStatusEnabled ?? true;
  }

  bool _isDetectedPromptEnabled() {
    return _notificationProvider?.detectedTransactionPromptsEnabled ?? true;
  }

  Future<void> showTransactionScanStatus({required String source}) async {
    if (!_initialized || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (!_isScanStatusEnabled()) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nexus_scan_status_channel',
        'Transaction Scan Status',
        channelDescription: 'Shows live status while scanning for transactions',
        importance: Importance.defaultImportance,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: true,
      ),
    );

    await _localNotifications.show(
      id: _scanStatusNotificationId,
      title: 'Scanning transactions',
      body: 'Checking ${source.toUpperCase()} for new transactions...',
      notificationDetails: details,
      payload: 'nbox',
    );
  }

  Future<void> stopTransactionScanStatus() async {
    if (!_initialized || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await _localNotifications.cancel(id: _scanStatusNotificationId);
  }

  Future<void> showDetectedTransactionPrompt(
    DetectedTransaction transaction,
  ) async {
    if (!_initialized || !_isDetectedPromptEnabled()) {
      return;
    }

    final payload =
        'nbox_approve|${transaction.source}|${transaction.id}';
    final localId =
        (transaction.id.hashCode ^ transaction.source.hashCode) & 0x7fffffff;
    final title = 'New transaction detected';
    final body =
        '₹${transaction.amount.toStringAsFixed(0)} at ${transaction.merchant}. Log it?';

    _notificationProvider?.addNotification(
      AppNotification(
        id: 'detected_${transaction.source}_${transaction.id}',
        type: NotificationType.transactionAlert,
        title: title,
        message: body,
        createdAt: DateTime.now(),
        actionText: 'Log It',
        actionRoute: '/nbox',
        data: {
          'source': transaction.source,
          'detectedId': transaction.id,
          'type': 'detected_prompt',
        },
      ),
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nexus_detected_transaction_channel',
        'Detected Transaction Prompts',
        channelDescription: 'Prompts to review newly detected transactions',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('log_it', 'Log It'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'detected_tx_prompt',
      ),
    );

    await _localNotifications.show(
      id: localId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    if (payload.startsWith('nbox_approve|')) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        _approvalRequestController.add(
          DetectionApprovalRequest(
            source: parts,
            transactionId: parts.sublist(2).join('|'),
          ),
        );
      }
    }
  }

  AppNotification? _mapToAppNotification(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? 'Nexus';
    final body = message.notification?.body ?? data['body'] ?? '';
    final typeString = data['type']?.toString().toLowerCase();

    final type = _parseType(typeString);
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: body.isNotEmpty ? body : 'You have a new notification',
      createdAt: DateTime.now(),
      actionRoute: data['actionRoute'],
      data: data.isEmpty ? null : data,
    );
  }

  NotificationType _parseType(String? type) {
    switch (type) {
      case 'budget':
      case 'budgetwarning':
        return NotificationType.budgetWarning;
      case 'subscription':
        return NotificationType.subscriptionReminder;
      case 'transaction':
      case 'transactionalert':
        return NotificationType.transactionAlert;
      case 'goal':
        return NotificationType.goalProgress;
      default:
        return NotificationType.systemUpdate;
    }
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeToken(token);
      }
      _messaging.onTokenRefresh.listen(_storeToken);
    } catch (e) {
      log('⚠️ Error syncing FCM token: $e');
      // Non-critical error
    }
  }

  Future<void> _storeToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { return; }

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token);

      await ref.set({
        'token': token,
        'platform': defaultTargetPlatform.toString(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      log('✅ FCM token stored: $token');
    } catch (e) {
      log('⚠️ Error storing FCM token: $e');
      // Non-critical error
    }
  }

  // ----------------------- Legacy helpers ----------------------- //
  Future<void> checkUpcomingPayments(List<dynamic> debts) async {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        if (daysUntilDue >= 0 && daysUntilDue <= 3) {
          upcoming.add({'debt': debt, 'daysUntilDue': daysUntilDue});
        }
      }
    }

    if (upcoming.isNotEmpty) {
      _showUpcomingPaymentNotifications(upcoming);
    }
  }

  void _showUpcomingPaymentNotifications(List<Map<String, dynamic>> upcoming) {
    for (final item in upcoming) {
      final debt = item['debt'];
      final days = item['daysUntilDue'] as int;

      String message;
      if (days == 0) {
        message =
            'EMI payment for ${debt.name} is due today! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      } else if (days == 1) {
        message =
            'EMI payment for ${debt.name} is due tomorrow! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      } else {
        message =
            'EMI payment for ${debt.name} is due in $days days! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      }

      log('Notification: $message');
    }
  }

  static void showInAppNotification(
    BuildContext context,
    String title,
    String message,
  ) {
    showTopSnackBar(context, '$title: $message', isError: true);
  }

  List<Map<String, dynamic>> getUpcomingPayments(List<dynamic> debts) {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        if (daysUntilDue >= 0 && daysUntilDue <= 7) {
          upcoming.add({
            'debt': debt,
            'daysUntilDue': daysUntilDue,
            'amount': debt.monthlyEMI,
            'dueDate': debt.nextDueDate,
          });
        }
      }
    }

    upcoming.sort((a, b) => a['daysUntilDue'].compareTo(b['daysUntilDue']));

    return upcoming;
  }

  static String formatDueDateMessage(int daysUntilDue) {
    if (daysUntilDue == 0) {
      return 'Due Today';
    } else if (daysUntilDue == 1) {
      return 'Due Tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }
}

class _NotificationServiceConstants {
  static const channelId = 'nexus_default_channel';
  static const channelName = 'General Notifications';
  static const channelDescription = 'Budget alerts, reminders, and insights';
}