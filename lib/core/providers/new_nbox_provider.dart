import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/detected_transaction.dart';
import '../utils/new_sms_parser.dart';
import '../services/categorization_service.dart';
import '../services/notification_service.dart';
import 'category_provider.dart';
import 'gmail_provider.dart';
import '../models/nbox_settings.dart';

// ---------------------------------------------------------------------------
// Isolate helpers — must be top-level (not inside a class) for compute()
// ---------------------------------------------------------------------------

class _SmsBatchPayload {
  final List<Map<String, dynamic>> messages;
  _SmsBatchPayload(this.messages);
}

/// Runs purely in Dart memory. No native platform channels used here.
List<Map<String, dynamic>> _parseSmsInIsolate(_SmsBatchPayload payload) {
  final results = <Map<String, dynamic>>[];
  for (final msg in payload.messages) {
    final parsed = NewSmsParser.parseSync(
      msg['id'] as String,
      msg['body'] as String,
      msg['address'] as String,
      DateTime.parse(msg['date'] as String),
    );
    if (parsed != null) {
      results.add({
        'id': parsed.id,
        'fingerprint': parsed.fingerprint,
        'amount': parsed.amount,
        'merchant': parsed.merchant,
        'date': parsed.date.toIso8601String(),
        'type': parsed.type,
        'source': parsed.source,
        'body': parsed.body,
        'confidence': parsed.confidence,
        'warnings': parsed.warnings,
        'detectedCategory': parsed.detectedCategory,
      });
    }
  }
  return results;
}

// ---------------------------------------------------------------------------

class NewNboxProvider extends ChangeNotifier {
  static const String _processedIdsStorageKey = 'nbox_processed_ids';
  static const String _notifiedDetectionsStorageKey =
      'nbox_notified_detection_ids';
  static const int _maxPromptsPerScan = 3;

  GmailProvider? _gmailProvider;
  NboxSettings _settings = const NboxSettings();
  NboxSettings get settings => _settings;

  final CategoryProvider? _categoryProvider;
  final Telephony _telephony = Telephony.instance;

  bool _isLoading = false;
  bool _isScanning = false;
  List<DetectedTransaction> _pendingSms = [];
  List<DetectedTransaction> _pendingEmails = [];
  final List<DetectedTransaction> _rejected = [];

  Set<String> _processedIds = {};
  Set<String> _notifiedDetectionIds = {};
  String? _pendingApprovalSource;
  String? _pendingApprovalId;

  bool get isLoading => _isLoading;
  bool get isGmailLinked => _gmailProvider?.isLinked ?? false;
  bool get smsReadingEnabled => _settings.smsReadingEnabled;

  List<DetectedTransaction> get pendingSms => List.unmodifiable(_pendingSms);
  List<DetectedTransaction> get pendingEmails =>
      List.unmodifiable(_pendingEmails);
  List<DetectedTransaction> get rejected => List.unmodifiable(_rejected);

  bool get hasPendingApprovalRequest =>
      _pendingApprovalSource != null && _pendingApprovalId != null;

  bool _isInitialized = false;

  NewNboxProvider({
    GmailProvider? gmailProvider,
    CategoryProvider? categoryProvider,
  }) : _categoryProvider = categoryProvider {
    update(gmailProvider);
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadSettings();
    await _loadNotifiedDetectionIds();
    await _loadProcessedIds();
    _isInitialized = true;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('nbox_settings');
    if (json != null) {
      _settings = NboxSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(json)),
      );
      notifyListeners();
    }
  }

  Future<void> updateSettings(NboxSettings newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nbox_settings', jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  void update(GmailProvider? gmailProvider) {
    if (_gmailProvider != gmailProvider) {
      _gmailProvider?.removeListener(_onGmailProviderChanged);
      _gmailProvider = gmailProvider;
      _gmailProvider?.addListener(_onGmailProviderChanged);
      if (_gmailProvider != null) {
        _onGmailProviderChanged();
      }
    }
  }

  @override
  void dispose() {
    _gmailProvider?.removeListener(_onGmailProviderChanged);
    super.dispose();
  }

  void _onGmailProviderChanged() {
    if (_gmailProvider != null) {
      final transactions = _gmailProvider!.detectedTransactions;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        _processTransactions(transactions, 'email');
        notifyListeners();
      });
    }
  }

  Future<void> scanAll() async {
    _setLoading(true);
    await scanSmsInbox();
    if (isGmailLinked) {
      await scanEmails();
    }
    _setLoading(false);
  }

  Future<void> scanEmails() async {
    if (!isGmailLinked) return;
    _setLoading(true);
    await NotificationService().showTransactionScanStatus(source: 'email');
    try {
      debugPrint('=== [NBOX DEBUG] Triggering Gmail Scan ===');
      await _gmailProvider!.scanEmails();
    } catch (e) {
      debugPrint('=== [NBOX DEBUG] Error scanning emails: $e ===');
    } finally {
      await NotificationService().stopTransactionScanStatus();
      _setLoading(false);
    }
  }

  Future<void> scanSmsInbox() async {
    if (!smsReadingEnabled) return;
    if (_isScanning) return;

    _isScanning = true;

    // 1. Show UI Spinner immediately
    _setLoading(true);
    await NotificationService().showTransactionScanStatus(source: 'sms');

    // 2. 🛑 IPC COLLISION SHIELD
    // Wait a full 3 seconds before querying the Android ContentResolver.
    // This allows Firebase, Google Play Services, and Auto-Backup to finish
    // their native Android background handshakes. Without this shield, the Binder
    // drops the package ID and throws a fatal SecurityException.
    await Future.delayed(const Duration(milliseconds: 3000));

    try {
      if (!await _checkSmsPermission()) {
        debugPrint('=== [NBOX DEBUG] SMS permission denied ===');
        return;
      }

      debugPrint('=== [NBOX DEBUG] Starting Native SMS Fetch ===');
      final List<SmsMessage> messages = [];
      final DateTime now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final startMillis = now
            .subtract(Duration(days: i + 1))
            .millisecondsSinceEpoch
            .toString();
        final endMillis = now
            .subtract(Duration(days: i))
            .millisecondsSinceEpoch
            .toString();

        try {
          debugPrint('=== [NBOX DEBUG] Fetching Day $i ===');
          final chunk = await _telephony
              .getInboxSms(
                columns: [
                  SmsColumn.ID,
                  SmsColumn.ADDRESS,
                  SmsColumn.BODY,
                  SmsColumn.DATE,
                ],
                filter: SmsFilter.where(SmsColumn.DATE)
                    .greaterThanOrEqualTo(startMillis)
                    .and(SmsColumn.DATE)
                    .lessThan(endMillis),
              )
              .timeout(const Duration(seconds: 4));

          messages.addAll(chunk);
          debugPrint(
            '=== [NBOX DEBUG] Day $i fetched ${chunk.length} msgs ===',
          );
        } catch (e) {
          debugPrint('=== [NBOX DEBUG] SMS chunk $i failed: $e ===');
        }

        // Give the UI thread time to render frames AND let other IPC traffic pass
        await Future.delayed(const Duration(milliseconds: 350));
      }

      debugPrint('=== [NBOX DEBUG] Total SMS Fetched: ${messages.length} ===');

      final txHint = RegExp(
        r'(rs\.?|inr|debited|credited|spent|received|payment|ac |a/c)',
        caseSensitive: false,
      );
      final rawMessages = <Map<String, dynamic>>[];

      for (var s in messages) {
        if (s.id == null || s.date == null || s.body == null) continue;
        if (txHint.hasMatch(s.body!)) {
          rawMessages.add({
            'id': s.id.toString(),
            'body': s.body!,
            'address': s.address ?? 'Unknown',
            'date': DateTime.fromMillisecondsSinceEpoch(
              s.date!,
              isUtc: true,
            ).toLocal().toIso8601String(),
          });
        }
      }

      debugPrint(
        '=== [NBOX DEBUG] Filtered down to ${rawMessages.length} potential transactions ===',
      );

      if (rawMessages.isEmpty) {
        debugPrint('=== [NBOX DEBUG] No relevant SMS found. Exiting scan. ===');
        _processTransactions([], 'sms');
        notifyListeners();
        return;
      }

      debugPrint('=== [NBOX DEBUG] Offloading parsing to Dart Isolate ===');

      // Send ONLY pure dart data to the isolate
      final parsedRaw = await Isolate.run(() {
        return _parseSmsInIsolate(_SmsBatchPayload(rawMessages));
      });

      debugPrint('=== [NBOX DEBUG] Isolate completed. Mapping objects... ===');

      final allSmsTransactions = parsedRaw
          .map(
            (m) => DetectedTransaction(
              id: m['id'] as String,
              fingerprint: m['fingerprint'] as String,
              amount: (m['amount'] as num).toDouble(),
              merchant: m['merchant'] as String,
              date: DateTime.parse(m['date'] as String),
              type: m['type'] as String,
              source: m['source'] as String,
              body: m['body'] as String?,
              confidence: (m['confidence'] as num).toDouble(),
              warnings: List<String>.from(m['warnings'] as List),
              detectedCategory: m['detectedCategory'] as String?,
            ),
          )
          .toList();

      debugPrint(
        '=== [NBOX DEBUG] Successfully mapped ${allSmsTransactions.length} transactions ===',
      );

      _processTransactions(allSmsTransactions, 'sms');
      notifyListeners();
    } finally {
      _isScanning = false;
      await NotificationService().stopTransactionScanStatus();
      _setLoading(false);
      debugPrint('=== [NBOX DEBUG] Scan Lifecycle Complete ===');
    }
  }

  void _processTransactions(
    List<DetectedTransaction> transactions,
    String source,
  ) {
    final freshPending = <DetectedTransaction>[];
    final freshRejected = <DetectedTransaction>[];

    for (final transaction in transactions) {
      final approvedKey = '${transaction.source}:${transaction.fingerprint}';
      final rejectedKey =
          '${transaction.source}:${transaction.fingerprint}:rejected';

      if (_processedIds.contains(approvedKey)) {
        continue;
      } else if (_processedIds.contains(rejectedKey)) {
        freshRejected.add(transaction);
      } else {
        freshPending.add(transaction);
      }
    }

    if (source == 'sms') {
      _pendingSms = freshPending;
    } else if (source == 'email') {
      _pendingEmails = freshPending;
    }

    _rejected.removeWhere((t) => t.source == source);
    _rejected.addAll(freshRejected);

    _sortLists();
    unawaited(_notifyFreshDetections(freshPending));
  }

  Future<void> _notifyFreshDetections(
    List<DetectedTransaction> freshPending,
  ) async {
    final candidates = freshPending
        .where((t) => t.isHighConfidence)
        .where((t) => !_processedIds.contains('${t.source}:${t.fingerprint}'))
        .where(
          (t) =>
              !_notifiedDetectionIds.contains('${t.source}:${t.fingerprint}'),
        )
        .toList();

    if (candidates.isEmpty) {
      return;
    }

    final toNotify = candidates.take(_maxPromptsPerScan).toList();
    for (final transaction in toNotify) {
      final detectionKey = '${transaction.source}:${transaction.fingerprint}';
      _notifiedDetectionIds.add(detectionKey);
      await NotificationService().showDetectedTransactionPrompt(transaction);
    }
    await _persistNotifiedDetectionIds();
  }

  void queueApprovalRequestFromNotification({
    required String transactionId,
    required String source,
  }) {
    _pendingApprovalSource = source;
    _pendingApprovalId = transactionId;
    unawaited(scanAll());
    notifyListeners();
  }

  DetectedTransaction? takePendingApprovalRequest() {
    if (_pendingApprovalSource == null || _pendingApprovalId == null) {
      return null;
    }

    final source = _pendingApprovalSource!;
    final id = _pendingApprovalId!;
    final pool = source == 'sms' ? _pendingSms : _pendingEmails;
    final index = pool.indexWhere((t) => t.id == id && t.source == source);
    if (index == -1) {
      return null;
    }

    final transaction = pool[index];
    _pendingApprovalSource = null;
    _pendingApprovalId = null;
    return transaction;
  }

  Future<void> markAsApproved(String id, String source) async {
    final transaction = [..._pendingSms, ..._pendingEmails, ..._rejected]
        .firstWhere(
          (t) => t.id == id && t.source == source,
          orElse: () => throw StateError('Transaction not found'),
        );

    _pendingSms.removeWhere((t) => t.id == id && t.source == source);
    _pendingEmails.removeWhere((t) => t.id == id && t.source == source);
    _rejected.removeWhere((t) => t.id == id && t.source == source);

    final approvedKey = '$source:${transaction.fingerprint}';
    _processedIds.add(approvedKey);
    _processedIds.remove('$source:${transaction.fingerprint}:rejected');
    _notifiedDetectionIds.remove(approvedKey);

    notifyListeners();
    await _persistIds();
    await _persistNotifiedDetectionIds();
  }

  Future<void> rejectTransaction(
    String id,
    String source, {
    bool silent = false,
  }) async {
    DetectedTransaction? transactionToMove;

    _pendingSms.removeWhere((t) {
      if (t.id == id && t.source == source) {
        transactionToMove = t;
        return true;
      }
      return false;
    });

    _pendingEmails.removeWhere((t) {
      if (t.id == id && t.source == source) {
        transactionToMove = t;
        return true;
      }
      return false;
    });

    if (transactionToMove != null) {
      if (!_rejected.any((t) => t.id == id && t.source == source)) {
        _rejected.add(transactionToMove!);
      }

      final rejectedKey = '$source:${transactionToMove!.fingerprint}:rejected';
      final approvedKey = '$source:${transactionToMove!.fingerprint}';
      _processedIds.add(rejectedKey);
      _processedIds.remove(approvedKey);
      _notifiedDetectionIds.remove(approvedKey);

      _sortLists();
      notifyListeners();
      await _persistIds();
      await _persistNotifiedDetectionIds();
    }
  }

  Future<void> restoreTransaction(String id, String source) async {
    DetectedTransaction? transactionToMove;
    _rejected.removeWhere((t) {
      if (t.id == id && t.source == source) {
        transactionToMove = t;
        return true;
      }
      return false;
    });

    if (transactionToMove != null) {
      if (source == 'sms') {
        _pendingSms.add(transactionToMove!);
      } else {
        _pendingEmails.add(transactionToMove!);
      }

      _processedIds.remove(
        '$source:${transactionToMove!.fingerprint}:rejected',
      );

      _sortLists();
      notifyListeners();
      await _persistIds();
    }
  }

  void _sortLists() {
    _pendingSms.sort((a, b) => b.date.compareTo(a.date));
    _pendingEmails.sort((a, b) => b.date.compareTo(a.date));
    _rejected.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _persistIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_processedIdsStorageKey, _processedIds.toList());
  }

  Future<void> _loadProcessedIds() async {
    final prefs = await SharedPreferences.getInstance();
    _processedIds = (prefs.getStringList(_processedIdsStorageKey) ?? [])
        .toSet();
  }

  Future<void> _persistNotifiedDetectionIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notifiedDetectionsStorageKey,
      _notifiedDetectionIds.toList(),
    );
  }

  Future<void> _loadNotifiedDetectionIds() async {
    final prefs = await SharedPreferences.getInstance();
    _notifiedDetectionIds =
        (prefs.getStringList(_notifiedDetectionsStorageKey) ?? []).toSet();
  }

  Future<bool> _checkSmsPermission() async {
    final status = await Permission.sms.request();
    if (kDebugMode) debugPrint('[NewNboxProvider] SMS permission: $status');
    return status.isGranted;
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}
