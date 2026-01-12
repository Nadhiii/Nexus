import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../models/detected_transaction.dart';
import '../utils/gmail_parser.dart';

class GmailProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gmail.GmailApi.gmailReadonlyScope],
  );

  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<DetectedTransaction> _detectedTransactions = [];
  DateTime? _lastSyncTime;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLinked => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DetectedTransaction> get detectedTransactions =>
      List.unmodifiable(_detectedTransactions);
  DateTime? get lastSyncTime => _lastSyncTime;

  GmailProvider() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      if (_currentUser == null) {
        _detectedTransactions.clear();
        _lastSyncTime = null;
      } else {
        Future.microtask(() => scanEmails());
      }
      notifyListeners();
    });
    _googleSignIn.signInSilently();
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
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception('Authenticated client not available.');
      }

      final gmailApi = gmail.GmailApi(client);

      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String()
          .split('T')
          .first;

      // FIX: Aggressive filtering in the query itself.
      // We explicitly block "OTP", "Reminder", "Statement", "Due".
      final query =
          'subject:(receipt OR "transaction" OR "payment" OR "spent" OR "debited" OR "credited") -subject:("OTP" OR "One Time Password" OR "statement" OR "bill due" OR "payment due" OR "reminder")';

      final listResponse = await gmailApi.users.messages.list(
        'me',
        maxResults: 150,
        q: '$query after:$thirtyDaysAgo',
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
              final transaction = GmailParser.parse(
                message.id!,
                body,
                msg.snippet ?? '',
                emailDate,
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

      // --- DEDUPLICATION ---
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
