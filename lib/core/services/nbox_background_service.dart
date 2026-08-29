import 'dart:convert';
import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detected_transaction.dart';
import '../models/nbox_settings.dart';
import '../utils/sms_parser.dart';
import 'notification_service.dart';

/// Handles a newly received SMS without relying on a Provider or widget tree.
///
/// SharedPreferences is deliberately the durable hand-off between Android's
/// background isolate and [NewNboxProvider] in the normal application isolate.
class NboxBackgroundService {
  static const processedIdsStorageKey = 'nbox_processed_ids';
  static const notifiedDetectionsStorageKey = 'nbox_notified_detection_ids';
  static const pendingTransactionsStorageKey = 'nbox_pending_transactions';
  static const pendingApprovalStorageKey = 'nbox_pending_approval_request';
  static const settingsStorageKey = 'nbox_settings';
  static final StreamController<DetectedTransaction> _detectionController =
      StreamController<DetectedTransaction>.broadcast();

  /// Emits only within the foreground application isolate. The provider uses
  /// this to update an already-open NBox without re-scanning the inbox.
  static Stream<DetectedTransaction> get detectionStream =>
      _detectionController.stream;

  static final RegExp _transactionHint = RegExp(
    r'(rs\.?|inr|₹|debited|credited|spent|received|payment|ac |a/c)',
    caseSensitive: false,
  );

  /// Saves [transaction] before displaying a prompt. Returns `true` only for
  /// a new, actionable detection; this makes repeated SMS broadcasts harmless.
  static Future<bool> persistIncomingTransaction(
    DetectedTransaction transaction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _detectionKey(transaction);
    final processed =
        (prefs.getStringList(processedIdsStorageKey) ?? const <String>[])
            .toSet();

    if (processed.contains(key) || processed.contains('$key:rejected')) {
      return false;
    }

    final pending = await loadPendingTransactions(prefs: prefs);
    if (pending.any((item) => _detectionKey(item) == key)) {
      return false;
    }

    pending.add(transaction);
    await savePendingTransactions(pending, prefs: prefs);

    if (!transaction.isHighConfidence) {
      return true;
    }

    final notified =
        (prefs.getStringList(notifiedDetectionsStorageKey) ?? const <String>[])
            .toSet();
    if (notified.contains(key)) {
      return true;
    }

    // Record the notification only after its plugin call succeeds so a later
    // foreground scan can retry if Android killed this isolate mid-delivery.
    final shown = await NotificationService()
        .showDetectedTransactionPromptFromBackground(transaction);
    if (shown) {
      notified.add(key);
      await prefs.setStringList(
        notifiedDetectionsStorageKey,
        notified.toList(),
      );
    }
    return true;
  }

  static Future<List<DetectedTransaction>> loadPendingTransactions({
    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final raw = storage.getString(pendingTransactionsStorageKey);
    if (raw == null || raw.isEmpty) return <DetectedTransaction>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => DetectedTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      // A malformed local cache must not block future SMS processing.
      await storage.remove(pendingTransactionsStorageKey);
      return <DetectedTransaction>[];
    }
  }

  static Future<void> savePendingTransactions(
    List<DetectedTransaction> transactions, {
    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    await storage.setString(
      pendingTransactionsStorageKey,
      jsonEncode(
        transactions.map((transaction) => transaction.toJson()).toList(),
      ),
    );
  }

  static Future<void> removePendingTransaction(
    DetectedTransaction transaction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await loadPendingTransactions(prefs: prefs);
    pending.removeWhere(
      (item) => _detectionKey(item) == _detectionKey(transaction),
    );
    await savePendingTransactions(pending, prefs: prefs);
  }

  static String detectionKey(DetectedTransaction transaction) =>
      _detectionKey(transaction);

  static String _detectionKey(DetectedTransaction transaction) =>
      '${transaction.source}:${transaction.fingerprint}';

  static Future<void> handleIncomingSms(SmsMessage message) async {
    final body = message.body;
    if (body == null || body.isEmpty || !_transactionHint.hasMatch(body)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(settingsStorageKey);
    if (rawSettings != null) {
      try {
        final settings = NboxSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawSettings) as Map),
        );
        if (!settings.smsReadingEnabled) return;
      } catch (_) {
        // Keep the default enabled behaviour if an old setting cannot be read.
      }
    }

    final timestamp = message.date ?? DateTime.now().millisecondsSinceEpoch;
    final transaction = NewSmsParser.parseSync(
      message.id?.toString() ?? '${message.address ?? 'unknown'}-$timestamp',
      body,
      message.address ?? 'Unknown',
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal(),
    );
    if (transaction != null) {
      if (await persistIncomingTransaction(transaction)) {
        _detectionController.add(transaction);
      }
    }
  }
}

/// Must remain a top-level entry point for another_telephony to invoke after
/// Android has started a background Flutter isolate.
@pragma('vm:entry-point')
Future<void> nboxBackgroundSmsHandler(SmsMessage message) async {
  await NboxBackgroundService.handleIncomingSms(message);
}

Future<void> nboxForegroundSmsHandler(SmsMessage message) async {
  await NboxBackgroundService.handleIncomingSms(message);
}
