import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detected_transaction.dart';
import '../models/gmail_sync_settings.dart';
import '../utils/gmail_parser.dart';
import '../services/ai_categorization_service.dart';
import '../../modules/Nex/providers/Nex_assistant_provider.dart';
import 'category_provider.dart';

class GmailProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gmail.GmailApi.gmailReadonlyScope],
  );

  // Optional AI dependencies for smart categorization
  final CategoryProvider? _categoryProvider;

  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<DetectedTransaction> _detectedTransactions = [];
  DateTime? _lastSyncTime;
  GmailSyncSettings _settings = const GmailSyncSettings();
  Timer? _syncTimer;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLinked => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DetectedTransaction> get detectedTransactions =>
      List.unmodifiable(_detectedTransactions);
  DateTime? get lastSyncTime => _lastSyncTime;
  GmailSyncSettings get settings => _settings;

  bool _isInitialized = false;

  GmailProvider({
    AIAssistantProvider? aiAssistantProvider,
    CategoryProvider? categoryProvider,
  }) : _categoryProvider = categoryProvider {
    // Initialize asynchronously - don't block constructor
    initialize();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      if (_currentUser == null) {
        _detectedTransactions.clear();
        _lastSyncTime = null;
        _stopAutoSync();
      } else {
        Future.microtask(() {
          scanEmails();
          _startAutoSync();
        });
      }
      notifyListeners();
    });
    _googleSignIn.signInSilently();
  }

  /// Initialize the provider - loads settings
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initializeSettings();
    _isInitialized = true;
  }

  Future<void> _initializeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('gmail_sync_settings');
      if (settingsJson != null) {
        _settings = GmailSyncSettings.fromJson(jsonDecode(settingsJson));
      }
    } catch (e) {
      if (kDebugMode) print('[GmailProvider] Failed to load settings: $e');
    }
  }

  Future<void> updateSettings(GmailSyncSettings newSettings) async {
    try {
      _settings = newSettings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'gmail_sync_settings',
        jsonEncode(_settings.toJson()),
      );

      // Restart sync timer if auto-sync is enabled
      _stopAutoSync();
      if (_settings.autoSyncEnabled && isLinked) {
        _startAutoSync();
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to save settings: $e';
      notifyListeners();
    }
  }

  void _startAutoSync() {
    if (!_settings.autoSyncEnabled || _syncTimer != null) return;

    if (kDebugMode) {
      print(
        '[GmailProvider] Starting auto-sync with interval: ${_settings.syncFrequency.displayName}',
      );
    }

    _syncTimer = Timer.periodic(_settings.syncFrequency.interval, (_) {
      scanEmails();
    });
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (kDebugMode) print('[GmailProvider] Auto-sync stopped');
  }

  Future<void> linkAccount() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      _error = 'Failed to link Gmail account: $e';
      notifyListeners();
    }
  }

  Future<void> unlinkAccount() async {
    try {
      _stopAutoSync();
      await _googleSignIn.disconnect();
    } catch (e) {
      _error = 'Failed to unlink Gmail account: $e';
      notifyListeners();
    }
  }

  Future<void> scanEmails() async {
    if (_currentUser == null) return;

    if (kDebugMode) print('[GmailProvider] Starting email scan...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create AI categorization service if dependencies available
      AICategorizationService? aiService;
      if (_categoryProvider != null) {
        aiService = AICategorizationService(
          categoryProvider: _categoryProvider,
        );
        if (kDebugMode) {
          print('[GmailProvider] AI categorization enabled');
        }
      } else {
        if (kDebugMode) {
          print(
            '[GmailProvider] Using fallback categorization (no CategoryProvider)',
          );
        }
      }

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception('Authenticated client not available.');
      }

      final gmailApi = gmail.GmailApi(client);

      // Incremental sync: Only fetch emails since last sync
      final startDate =
          _lastSyncTime ??
          DateTime.now().subtract(Duration(days: _settings.daysToScan));

      final formattedDate = startDate.toIso8601String().split('T').first;

      // Build query with filters - made less restrictive to catch more transaction emails
      // Look for common transaction indicators in subject OR body
      final baseQuery =
          '(subject:(receipt OR transaction OR payment OR spent OR debited OR credited OR "sent you" OR "paid" OR alert OR notification) OR body:(debited OR credited OR "account balance" OR "available balance")) -subject:("OTP" OR "One Time Password" OR "statement" OR "bill due" OR "payment due" OR "reminder" OR verification OR "verify your")';

      String finalQuery = '$baseQuery after:$formattedDate';

      // Add category filters if enabled
      if (!_settings.scanPromotions) {
        finalQuery += ' -category:promotions';
      }
      if (!_settings.scanSocial) {
        finalQuery += ' -category:social';
      }

      // Add excluded senders
      for (var sender in _settings.excludedSenders) {
        finalQuery += ' -from:$sender';
      }

      if (kDebugMode) print('[GmailProvider] Query: $finalQuery');

      final listResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: 150,
        q: finalQuery,
      );

      final List<DetectedTransaction> freshTransactions = [];

      if (listResponse.messages != null) {
        if (kDebugMode) {
          print(
            '[GmailProvider] Found ${listResponse.messages!.length} emails.',
          );
        }

        for (var message in listResponse.messages!) {
          try {
            if (message.id == null) continue;

            final msg = await gmailApi.users.messages.get(
              'me',
              message.id!,
              format: 'full',
            );
            final body = _extractBody(msg);

            // Get actual email date
            DateTime emailDate = DateTime.now();
            if (msg.internalDate != null) {
              emailDate = DateTime.fromMillisecondsSinceEpoch(
                int.parse(msg.internalDate!),
              );
            }

            if (body != null) {
              final transaction = await GmailParser.parse(
                message.id!,
                body,
                msg.snippet ?? '',
                emailDate,
                aiCategorizationService: aiService,
              );

              if (transaction != null) {
                freshTransactions.add(transaction);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print("[GmailProvider] Error processing email ${message.id}: $e");
            }
          }
        }
      }

      // --- DEDUPLICATION & FILTERING ---
      final Set<String> uniqueSignatures = {};
      final List<DetectedTransaction> finalTransactions = [];

      for (final tx in freshTransactions) {
        final signature =
            "${tx.merchant.toLowerCase()}:${tx.amount}:${tx.date.year}-${tx.date.month}-${tx.date.day}";

        if (!uniqueSignatures.contains(signature)) {
          finalTransactions.add(tx);
          uniqueSignatures.add(signature);
        }
      }

      _detectedTransactions = finalTransactions;
      _lastSyncTime = DateTime.now();

      if (kDebugMode) {
        print(
          '[GmailProvider] Scan complete. Found ${_detectedTransactions.length} unique transactions.',
        );
      }
    } catch (e) {
      _error = 'Failed to scan emails: $e';
      if (kDebugMode) print('[GmailProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _extractBody(gmail.Message message) {
    final payload = message.payload;
    if (payload == null) return message.snippet;

    String? body = _getPartBody(payload.parts ?? []);

    if (body == null && payload.body?.data != null) {
      try {
        body = utf8.decode(
          base64Url.decode(payload.body!.data!),
          allowMalformed: true,
        );
      } catch (e) {
        if (kDebugMode) print('[GmailProvider] Error decoding body: $e');
      }
    }

    return body ?? message.snippet;
  }

  String? _getPartBody(List<gmail.MessagePart> parts) {
    String? plainTextBody;
    String? htmlBody;

    List<gmail.MessagePart> partsToSearch = List.from(parts);

    while (partsToSearch.isNotEmpty) {
      final part = partsToSearch.removeAt(0);

      if (part.mimeType == 'text/plain' && part.body?.data != null) {
        try {
          plainTextBody = utf8.decode(
            base64Url.decode(part.body!.data!),
            allowMalformed: true,
          );
          return plainTextBody;
        } catch (e) {}
      }

      if (part.mimeType == 'text/html' &&
          part.body?.data != null &&
          htmlBody == null) {
        try {
          htmlBody = utf8.decode(
            base64Url.decode(part.body!.data!),
            allowMalformed: true,
          );
        } catch (e) {}
      }

      if (part.parts != null) {
        partsToSearch.addAll(part.parts!);
      }
    }

    return htmlBody;
  }
}
