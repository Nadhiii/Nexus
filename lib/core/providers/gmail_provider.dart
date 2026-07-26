// ignore_for_file: empty_catches
import 'dart:async';
import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detected_transaction.dart';
import '../models/gmail_sync_settings.dart';
import '../utils/gmail_parser.dart';
import '../services/categorization_service.dart';
import 'category_provider.dart';
import '../services/auth_service.dart';

class GmailProvider extends ChangeNotifier {
  static const List<String> _gmailScopes = [gmail.GmailApi.gmailReadonlyScope];

  final CategoryProvider? _categoryProvider;

  GoogleSignInAccount? _currentUser;
  bool _hasGmailAccess = false;
  bool _isLoading = false;
  String? _error;
  List<DetectedTransaction> _detectedTransactions = [];
  DateTime? _lastSyncTime;
  GmailSyncSettings _settings = const GmailSyncSettings();
  Timer? _syncTimer;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLinked => _currentUser != null && _hasGmailAccess;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DetectedTransaction> get detectedTransactions =>
      List.unmodifiable(_detectedTransactions);
  DateTime? get lastSyncTime => _lastSyncTime;
  GmailSyncSettings get settings => _settings;

  bool _isInitialized = false;

  GmailProvider({CategoryProvider? categoryProvider})
    : _categoryProvider = categoryProvider {
    // FIX: Removed initialize() from constructor.
    // It will now be called explicitly by AuthGate.
  }

  Future<void> initialize() async {
  if (_isInitialized) return;
  await AuthService.ensureGoogleSignInInitialized();
  await _initializeSettings();
  _isInitialized = true;

    _authSubscription = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          Future.microtask(() async {
            final existing = await event.user.authorizationClient
                .authorizationForScopes(_gmailScopes);
            _hasGmailAccess = existing != null;
            if (_hasGmailAccess) {
              scanEmails();
              _startAutoSync();
            }
            notifyListeners();
          });
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _hasGmailAccess = false;
          _detectedTransactions.clear();
          _lastSyncTime = null;
          _stopAutoSync();
        }
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('[GmailProvider] Auth stream error: $e');
      },
    );

    try {
      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      if (kDebugMode) debugPrint('[GmailProvider] Auth init failed: $e');
    }
  }

  Future<void> _initializeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('gmail_sync_settings');
      if (settingsJson != null) {
        _settings = GmailSyncSettings.fromJson(jsonDecode(settingsJson));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GmailProvider] Failed to load settings: $e');
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
      _stopAutoSync();
      if (_settings.autoSyncEnabled && isLinked) _startAutoSync();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save settings: $e';
      notifyListeners();
    }
  }

  void _startAutoSync() {
    if (!_settings.autoSyncEnabled || _syncTimer != null) return;
    if (kDebugMode) {
      debugPrint(
        '[GmailProvider] Starting auto-sync: ${_settings.syncFrequency.displayName}',
      );
    }
    _syncTimer = Timer.periodic(
      _settings.syncFrequency.interval,
      (_) => scanEmails(),
    );
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (kDebugMode) debugPrint('[GmailProvider] Auto-sync stopped');
  }

  Future<void> linkAccount() async {
    try {
      _currentUser ??= await GoogleSignIn.instance.authenticate();
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_gmailScopes);
      _hasGmailAccess = authorization.accessToken.isNotEmpty;
      _error = null;
      if (_hasGmailAccess) {
        Future.microtask(() {
          scanEmails();
          _startAutoSync();
        });
      }
    } catch (e) {
      _error = 'Failed to link Gmail account: $e';
      _hasGmailAccess = false;
    }
    notifyListeners();
  }

  Future<void> unlinkAccount() async {
    try {
      _stopAutoSync();
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      _error = 'Failed to unlink Gmail account: $e';
      notifyListeners();
    }
  }

  Future<gapis.AuthClient?> _getAuthenticatedClient() async {
    if (_currentUser == null) return null;
    try {
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_gmailScopes);
      return authorization.authClient(scopes: _gmailScopes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GmailProvider] Failed to get authenticated client: $e');
      }
      return null;
    }
  }

  Future<void> scanEmails() async {
    if (_isLoading) return;
    if (_currentUser == null) return;

    if (kDebugMode) debugPrint('[GmailProvider] Starting email scan...');
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    gapis.AuthClient? client;
    try {
      AICategorizationService? aiService;
      if (_categoryProvider != null) {
        aiService = AICategorizationService(
          categoryProvider: _categoryProvider,
        );
      }

      client = await _getAuthenticatedClient();
      if (client == null) {
        _hasGmailAccess = false;
        throw Exception(
          'Gmail session expired. Please reconnect your account.',
        );
      }

      final gmailApi = gmail.GmailApi(client);

      final startDate =
          _lastSyncTime ??
          DateTime.now().subtract(Duration(days: _settings.daysToScan));
      // Gmail's after: filter excludes the given day itself, so subtract
      // one extra day to make sure we don't lose today's/this sync
      // window's emails when startDate is "now" from a prior sync.
      final queryDate = startDate.subtract(const Duration(days: 1));
      final formattedDate = queryDate.toIso8601String().split('T').first;

      if (kDebugMode) {
        debugPrint(
          '[GmailProvider] lastSyncTime: $_lastSyncTime, daysToScan: ${_settings.daysToScan}, startDate: $startDate, formattedDate: $formattedDate',
        );
      }

      final baseQuery =
          '(subject:(receipt OR transaction OR payment OR spent OR debited OR credited OR "sent you" OR "paid" OR alert OR notification) OR body:(debited OR credited OR "account balance" OR "available balance")) -subject:("OTP" OR "One Time Password" OR "statement" OR "bill due" OR "payment due" OR "reminder" OR verification OR "verify your")';

      String finalQuery = '$baseQuery after:$formattedDate';

      if (!_settings.scanPromotions) finalQuery += ' -category:promotions';
      if (!_settings.scanSocial) finalQuery += ' -category:social';
      for (var sender in _settings.excludedSenders) {
        finalQuery += ' -from:$sender';
      }

      if (kDebugMode) debugPrint('[GmailProvider] Query: $finalQuery');

      final listResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: 40,
        q: finalQuery,
      );

      if (kDebugMode) {
        debugPrint(
          '[GmailProvider] resultSizeEstimate: ${listResponse.resultSizeEstimate}, messages: ${listResponse.messages?.length}',
        );
      }

      final List<DetectedTransaction> freshTransactions = [];

      if (listResponse.messages != null) {
        if (kDebugMode) {
          debugPrint(
            '[GmailProvider] Found ${listResponse.messages!.length} emails.',
          );
        }

        for (var message in listResponse.messages!) {
          await Future.delayed(const Duration(milliseconds: 50));

          try {
            if (message.id == null) continue;

            final msg = await gmailApi.users.messages.get(
              'me',
              message.id!,
              format: 'full',
            );
            final body = _extractBody(msg);

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
              if (transaction != null) freshTransactions.add(transaction);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '[GmailProvider] Error processing email ${message.id}: $e',
              );
            }
          }
        }
      }

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
        debugPrint(
          '[GmailProvider] Scan complete. ${_detectedTransactions.length} unique transactions.',
        );
      }
    } catch (e) {
      _error = 'Failed to scan emails: $e';
      if (kDebugMode) debugPrint('[GmailProvider] Error: $e');
    } finally {
      client?.close();
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
        if (kDebugMode) debugPrint('[GmailProvider] Error decoding body: $e');
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

      if (part.parts != null) partsToSearch.addAll(part.parts!);
    }

    return htmlBody;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _stopAutoSync();
    super.dispose();
  }
}
