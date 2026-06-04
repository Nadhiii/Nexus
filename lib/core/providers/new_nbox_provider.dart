import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/detected_transaction.dart';
import '../utils/new_sms_parser.dart';
import '../services/ai_categorization_service.dart';
import '../services/notification_service.dart';
import '../../modules/Nex/providers/Nex_assistant_provider.dart';
import 'category_provider.dart';
import 'gmail_provider.dart';
import '../models/nbox_settings.dart';

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
    AIAssistantProvider? aiAssistantProvider,
    CategoryProvider? categoryProvider,
  }) : _categoryProvider = categoryProvider {
    update(gmailProvider);
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
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
        Map<String, dynamic>.from(await compute(_decodeJson, json)),
      );
      notifyListeners();
    }
  }

  static Map<String, dynamic> _decodeJson(String json) =>
      Map<String, dynamic>.from(jsonDecode(json));

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
      _processTransactions(_gmailProvider!.detectedTransactions, 'email');
      notifyListeners();
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
    if (!isGmailLinked) {
      return;
    }
    _setLoading(true);
    await NotificationService().showTransactionScanStatus(source: 'email');
    try {
      await _gmailProvider!.scanEmails();
    } finally {
      await NotificationService().stopTransactionScanStatus();
      _setLoading(false);
    }
  }

  Future<void> scanSmsInbox() async {
    if (!smsReadingEnabled) {
      if (kDebugMode) debugPrint('[NewNboxProvider] SMS reading disabled.');
      return;
    }
    if (kDebugMode) debugPrint('[NewNboxProvider] Starting SMS scan...');
    _setLoading(true);
    await NotificationService().showTransactionScanStatus(source: 'sms');

    try {
      if (!await _checkSmsPermission()) {
        if (kDebugMode) debugPrint('[NewNboxProvider] SMS permission denied.');
        return;
      }

      final DateTime nowUtc = DateTime.now().toUtc();
      final DateTime minDate = nowUtc.subtract(const Duration(days: 30));

      AICategorizationService? aiService;
      if (_categoryProvider != null) {
        aiService = AICategorizationService(
          categoryProvider: _categoryProvider,
        );
      }

      List<SmsMessage> messages;
      try {
        messages = await _telephony.getInboxSms(
          filter: SmsFilter.where(
            SmsColumn.DATE,
          ).greaterThan(minDate.millisecondsSinceEpoch.toString()),
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[NewNboxProvider] Error fetching SMS: $e');
        return;
      }

      final allSmsTransactions = <DetectedTransaction>[];
      for (final sms in messages) {
        if (sms.id == null || sms.date == null) {
          continue;
        }

        final localSmsDate = DateTime.fromMillisecondsSinceEpoch(
          sms.date!,
          isUtc: true,
        ).toLocal();

        final transaction = await NewSmsParser.parse(
          sms.id.toString(),
          sms.body ?? '',
          sms.address ?? 'Unknown',
          localSmsDate,
          aiCategorizationService: aiService,
        );
        if (transaction != null) {
          allSmsTransactions.add(transaction);
        }
      }

      _processTransactions(allSmsTransactions, 'sms');
      notifyListeners();
      if (kDebugMode) debugPrint('[NewNboxProvider] SMS scan complete.');
    } finally {
      await NotificationService().stopTransactionScanStatus();
      _setLoading(false);
    }
  }

  void _processTransactions(
    List<DetectedTransaction> transactions,
    String source,
  ) {
    final freshPending = <DetectedTransaction>[];
    final freshRejected = <DetectedTransaction>[];

    for (final transaction in transactions) {
      // Use fingerprint as the stable key for persistence checks
      final approvedKey = '${transaction.source}:${transaction.fingerprint}';
      final rejectedKey =
          '${transaction.source}:${transaction.fingerprint}:rejected';

      if (_processedIds.contains(approvedKey)) {
        continue; // Already approved, skip.
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
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _processedIds = (prefs.getStringList(_processedIdsStorageKey) ?? [])
        .toSet();
    await scanAll();
    _setLoading(false);
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
    if (_isLoading != loading) {
      _isLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          _isLoading = loading;
          notifyListeners();
        }
      });
    }
  }
}
