import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/detected_transaction.dart';
import '../services/ai_categorization_service.dart';
import '../services/smart_category_resolver.dart';

class NewSmsParser {
  static Future<DetectedTransaction?> parse(
    String id,
    String body,
    String sender,
    DateTime date, {
    AICategorizationService? aiCategorizationService,
  }) async {
    // 1. CLEAN
    final cleanBody = body.replaceAll(RegExp(r'[\n\r]'), ' ').trim();
    final lower = cleanBody.toLowerCase();

    // 2. GUARD: Explicit Non-Transactions
    if (_isIgnorable(lower)) {
      return null;
    }

    // 3. EXTRACT AMOUNT
    final amountPattern = RegExp(
      r'(?:Rs\.?|INR|₹)\s?\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final match = amountPattern.firstMatch(cleanBody);
    if (match == null) {
      return null;
    }

    String rawAmount = match.group(1)!.replaceAll(',', '');
    double? amount = double.tryParse(rawAmount);
    if (amount == null || amount == 0) {
      return null;
    }

    // 4. DETERMINE TYPE
    String type = 'expense';
    if (lower.contains(
      RegExp(r'(credit|credited|received|deposit|added to|refund)'),
    )) {
      type = 'income';
    }

    // 5. EXTRACT MERCHANT
    String merchant = _extractMerchant(cleanBody, sender);

    // 6. CATEGORIZATION
    final detectedCategory = SmartCategoryResolver.resolve(
      merchant: merchant,
      body: body,
      amount: amount,
      transactionType: type,
    );

    // 7. FINGERPRINT — content-based, survives reinstall
    final fingerprint = _generateFingerprint(sender, date, body);

    return DetectedTransaction(
      id: id,
      fingerprint: fingerprint,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'sms',
      body: body,
      detectedCategory: detectedCategory,
    );
  }

  /// Generates a stable MD5 hash from sender + date + body snippet.
  /// This is identical across reinstalls as long as the SMS content is the same.
  static String _generateFingerprint(
    String sender,
    DateTime date,
    String body,
  ) {
    final snippet = body.length > 40 ? body.substring(0, 40) : body;
    final raw = '$sender|${date.millisecondsSinceEpoch}|$snippet';
    return md5.convert(utf8.encode(raw)).toString();
  }

  static bool _isIgnorable(String lower) {
    // --- CATEGORY A: SECURITY / AUTH ---
    if (lower.contains('otp') ||
        lower.contains('code is') ||
        lower.contains('verification')) {
      return true;
    }

    // --- CATEGORY B: FAILURE / DECLINED ---
    if (lower.contains('failed') ||
        lower.contains('declined') ||
        lower.contains('could not')) {
      return true;
    }
    if (lower.contains('reversed')) {
      return true;
    }

    // --- CATEGORY C: FUTURE / REQUESTS ---
    if (lower.contains('request received')) {
      return true;
    }
    if (lower.contains('trying to collect')) {
      return true;
    }
    if (lower.contains('requested for')) {
      return true;
    }
    if (lower.contains('will be debited')) {
      return true;
    }
    if (lower.contains('scheduled for')) {
      return true;
    }
    if (lower.contains('due')) {
      return true;
    }

    // --- CATEGORY D: SETUP / ALERTS ---
    if (lower.contains('created a mandate')) {
      return true;
    }
    if (lower.contains('mandate') && lower.contains('success')) {
      return true;
    }
    if (lower.contains('registered') && lower.contains('auto-payment')) {
      return true;
    }
    if (lower.contains('e-mandate')) {
      return true;
    }
    if (lower.contains('autopay') &&
        (lower.contains('registered') ||
            lower.contains('set') ||
            lower.contains('setup'))) {
      return true;
    }
    if (lower.contains('limit') &&
        (lower.contains('set') || lower.contains('updated'))) {
      return true;
    }

    // --- CATEGORY E: MARKETING ---
    if (lower.contains('offer') ||
        lower.contains('apply now') ||
        lower.contains('eligible')) {
      return true;
    }

    return false;
  }

  static String _extractMerchant(String body, String sender) {
    // 0. Federal Bank UPI format
    final federalUpiPattern = RegExp(
      r'\b(?:sent|paid|debited|transferred)\b.*?\bto\s+([A-Za-z0-9\s&\-\.]{2,50}?)(?:\.Ref|\s+Ref|\.Ref:|\.|\\s+on\b)',
      caseSensitive: false,
    );
    final federalMatch = federalUpiPattern.firstMatch(body);
    if (federalMatch != null) {
      String candidate = federalMatch.group(1) ?? '';
      candidate = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
      candidate = candidate.replaceAll(RegExp(r'[\.,;]+$'), '').trim();
      if (candidate.isNotEmpty) {
        return candidate.toUpperCase();
      }
    }

    // 1. UPI Handles
    final upiPattern = RegExp(
      r'(?:\s|^)([a-zA-Z0-9\.\-_]+@[a-zA-Z]{3,})(?:\s|\.|$)',
      caseSensitive: false,
    );
    final upiMatch = upiPattern.firstMatch(body);
    if (upiMatch != null) {
      return upiMatch.group(1)!.toLowerCase();
    }

    // 2. "At/To/Via" Keywords
    final atPattern = RegExp(
      r'(?:at|to|via)\s+([A-Za-z0-9\s\&\.\-]{2,40})',
      caseSensitive: false,
    );
    final atMatch = atPattern.firstMatch(body);
    if (atMatch != null) {
      String candidate = atMatch.group(1)!.trim();
      candidate = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
      candidate = candidate
          .replaceAll(RegExp(r'\s*\.?Ref.*$', caseSensitive: false), '')
          .trim();
      if (!candidate.toLowerCase().contains('upi') &&
          !candidate.toLowerCase().contains('ref') &&
          !candidate.toLowerCase().contains('txn') &&
          !candidate.toLowerCase().contains('mandate')) {
        return candidate.toUpperCase();
      }
    }

    // 3. Fallback: Clean Sender ID
    return sender
        .replaceAll(RegExp(r'^[A-Z]{2}-'), '')
        .replaceAll(RegExp(r'[0-9]'), '')
        .toUpperCase();
  }
}
