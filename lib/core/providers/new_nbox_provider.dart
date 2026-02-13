import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/detected_transaction.dart';
import '../utils/new_sms_parser.dart';
import '../services/ai_categorization_service.dart';
import '../../modules/ai_assistant/providers/ai_assistant_provider.dart';
import 'category_provider.dart';
import 'gmail_provider.dart';

class NewNboxProvider extends ChangeNotifier {
  GmailProvider? _gmailProvider;

  // Optional AI dependencies for smart categorization
  final AIAssistantProvider? _aiAssistantProvider;
  final CategoryProvider? _categoryProvider;

  final Telephony _telephony = Telephony.instance;

  bool _isLoading = false;
  List<DetectedTransaction> _pendingSms = [];
  List<DetectedTransaction> _pendingEmails = [];
  final List<DetectedTransaction> _rejected = [];

  Set<String> _processedIds = {};

  bool get isLoading => _isLoading;
  bool get isGmailLinked => _gmailProvider?.isLinked ?? false;

  List<DetectedTransaction> get pendingSms => List.unmodifiable(_pendingSms);
  List<DetectedTransaction> get pendingEmails =>
      List.unmodifiable(_pendingEmails);
  List<DetectedTransaction> get rejected => List.unmodifiable(_rejected);

  bool _isInitialized = false;

  NewNboxProvider({
    GmailProvider? gmailProvider,
    AIAssistantProvider? aiAssistantProvider,
    CategoryProvider? categoryProvider,
  }) : _aiAssistantProvider = aiAssistantProvider,
       _categoryProvider = categoryProvider {
    update(gmailProvider);
    // Initialize asynchronously - don't block constructor
    initialize();
  }

  /// Initialize the provider - loads processed IDs and scans for transactions
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadProcessedIds();
    _isInitialized = true;
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
    await Future.wait([scanSmsInbox(), if (isGmailLinked) scanEmails()]);
    _setLoading(false);
  }

  Future<void> scanEmails() async {
    if (!isGmailLinked) return;
    _setLoading(true);
    await _gmailProvider!.scanEmails();
    _setLoading(false);
  }

  // --- FIXED SCAN FUNCTION ---
  Future<void> scanSmsInbox() async {
    if (kDebugMode) print('[NewNboxProvider] Starting SMS scan...');
    _setLoading(true);

    if (!await _checkSmsPermission()) {
      if (kDebugMode) {
        print('[NewNboxProvider] SMS permission denied. Aborting scan.');
      }
      _setLoading(false);
      return;
    }

    // FIX 1: Always look back 30 days.
    // This ensures the list is repopulated on app restart and doesn't disappear.
    // We use UTC for the query because Android stores SMS in UTC.
    final DateTime nowUtc = DateTime.now().toUtc();
    final DateTime minDate = nowUtc.subtract(const Duration(days: 30));

    if (kDebugMode) {
      print(
        '[NewNboxProvider] Fetching SMS from last 30 days (since $minDate UTC).',
      );
    }

    // Create AI categorization service if dependencies available
    AICategorizationService? aiService;
    if (_categoryProvider != null) {
      aiService = AICategorizationService(
        aiProvider: _aiAssistantProvider,
        categoryProvider: _categoryProvider,
      );
      if (kDebugMode) {
        print('[NewNboxProvider] AI categorization enabled for SMS');
      }
    }

    List<SmsMessage> messages;
    try {
      messages = await _telephony.getInboxSms(
        // FIX 2: Robust native query
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThan(minDate.millisecondsSinceEpoch.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
    } catch (e) {
      if (kDebugMode) print('[NewNboxProvider] Error fetching SMS: $e');
      _setLoading(false);
      return;
    }

    if (kDebugMode) {
      print(
        '[NewNboxProvider] Found ${messages.length} SMS messages in window.',
      );
    }

    final allSmsTransactions = <DetectedTransaction>[];
    for (final sms in messages) {
      if (sms.id == null || sms.date == null) continue;

      // FIX 3: Convert the UTC SMS timestamp to Local time so the user sees correct hours
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

    // This will completely refresh the list based on the last 30 days
    _processTransactions(allSmsTransactions, 'sms');

    notifyListeners();
    if (kDebugMode) print('[NewNboxProvider] SMS scan complete.');
    _setLoading(false);
  }

  void _processTransactions(
    List<DetectedTransaction> transactions,
    String source,
  ) {
    final freshPending = <DetectedTransaction>[];
    final freshRejected = <DetectedTransaction>[];

    for (final transaction in transactions) {
      final approvedId = '${transaction.source}:${transaction.id}';
      final rejectedId = '${transaction.source}:${transaction.id}:rejected';

      if (_processedIds.contains(approvedId)) {
        continue; // Already approved, so skip.
      } else if (_processedIds.contains(rejectedId)) {
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
  }

  Future<void> markAsApproved(String id, String source) async {
    _pendingSms.removeWhere((t) => t.id == id && t.source == source);
    _pendingEmails.removeWhere((t) => t.id == id && t.source == source);
    _rejected.removeWhere((t) => t.id == id && t.source == source);

    final approvedId = '$source:$id';
    _processedIds.add(approvedId);
    _processedIds.remove('$source:$id:rejected');

    notifyListeners();
    await _persistIds();
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

      final rejectedId = '$source:$id:rejected';
      _processedIds.add(rejectedId);
      _processedIds.remove('$source:$id');

      _sortLists();
      notifyListeners();
      await _persistIds();
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

      final rejectedId = '$source:$id:rejected';
      _processedIds.remove(rejectedId);

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
    await prefs.setStringList('nbox_processed_ids', _processedIds.toList());
  }

  Future<void> _loadProcessedIds() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _processedIds = (prefs.getStringList('nbox_processed_ids') ?? []).toSet();
    await scanAll();
    _setLoading(false);
  }

  Future<bool> _checkSmsPermission() async {
    final status = await Permission.sms.request();
    if (kDebugMode) print('[NewNboxProvider] SMS permission status: $status');
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
