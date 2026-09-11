import '../models/detected_transaction.dart';

class NewSmsParser {
  static Future<DetectedTransaction?> parse(
    String id,
    String body,
    String sender,
    DateTime date, {
    Object? aiCategorizationService,
  }) async {
    // 1. CLEAN
    final cleanBody = body.replaceAll(RegExp(r'[\n\r]'), ' ').trim();
    final lower = cleanBody.toLowerCase();

    // 2. GUARD: Explicit Non-Transactions
    if (_isIgnorable(lower)) return null;

    // 3. EXTRACT AMOUNT
    // Robust match for: Rs. 1,200 | INR 1200.50 | Rs 1200
    final amountPattern = RegExp(
      r'(?:Rs\.?|INR|₹)\s?\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final match = amountPattern.firstMatch(cleanBody);
    if (match == null) return null;

    String rawAmount = match.group(1)!.replaceAll(',', '');
    double? amount = double.tryParse(rawAmount);
    if (amount == null || amount == 0) return null;

    // 4. DETERMINE TYPE
    String type = 'expense';
    if (lower.contains(
      RegExp(r'(credit|credited|received|deposit|added to|refund)'),
    )) {
      type = 'income';
    }

    // 5. EXTRACT MERCHANT
    String merchant = _extractMerchant(cleanBody, sender);

    // 6. AI CATEGORIZATION
    String? detectedCategory;
    return DetectedTransaction(
      fingerprint: id,
      id: id,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'sms',
      body: body,
      detectedCategory: detectedCategory,
    );
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
    if (lower.contains('reversed')) return true;

    // --- CATEGORY C: FUTURE / REQUESTS (The "Autopay" Problem) ---
    // Example: "UPI auto-payment request received"
    if (lower.contains('request received')) return true;
    if (lower.contains('trying to collect')) return true;
    if (lower.contains('requested for')) return true;
    if (lower.contains('will be debited')) return true;
    if (lower.contains('scheduled for')) return true;
    if (lower.contains('due')) return true;

    // --- CATEGORY D: SETUP / ALERTS (Your specific examples) ---
    // Example: "You have successfully created a mandate"
    if (lower.contains('created a mandate')) return true;
    if (lower.contains('mandate') && lower.contains('success')) return true;

    // Example: "We've registered a as requested auto-payment"
    if (lower.contains('registered') && lower.contains('auto-payment')) {
      return true;
    }

    // Example: "e-mandate declined" (Caught by 'declined' above, but good to be specific)
    if (lower.contains('e-mandate')) return true;

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
    // 0. Federal Bank UPI format: "to MERCHANT.Ref:"
    final federalUpiPattern = RegExp(
      r'\b(?:sent|paid|debited|transferred)\b.*?\bto\s+([A-Za-z0-9\s&\-\.]{2,50}?)(?:\.Ref|\s+Ref|\.Ref:|\.|\s+on\b)',
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

    // 1. UPI Handles (Very Reliable)
    final upiPattern = RegExp(
      r'(?:\s|^)([a-zA-Z0-9\.\-_]+@[a-zA-Z]{3,})(?:\s|\.|$)',
      caseSensitive: false,
    );
    final upiMatch = upiPattern.firstMatch(body);
    if (upiMatch != null) return upiMatch.group(1)!.toLowerCase();

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
      // Filter out boring words that accidentally match
      if (!candidate.toLowerCase().contains('upi') &&
          !candidate.toLowerCase().contains('ref') &&
          !candidate.toLowerCase().contains('txn') &&
          !candidate.toLowerCase().contains('mandate')) {
        // Added 'mandate' to block list
        return candidate.toUpperCase();
      }
    }

    // 3. Fallback: Clean Sender ID (AX-HDFCBK -> HDFC)
    return sender
        .replaceAll(RegExp(r'^[A-Z]{2}-'), '')
        .replaceAll(RegExp(r'[0-9]'), '')
        .toUpperCase();
  }
}
