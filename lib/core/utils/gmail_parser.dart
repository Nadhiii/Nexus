import '../models/detected_transaction.dart';
import '../services/categorization_service.dart';
import '../services/smart_category_resolver.dart';

class BankPattern {
  final String name;
  final String regex;

  const BankPattern({required this.name, required this.regex});
}

class GmailParser {
  static const List<BankPattern> bankPatterns = [
    // 1. IDFC FIRST BANK
    // Captures action (debited/credited) directly so type detection
    // no longer depends on scanning the whole email body.
    BankPattern(
      name: 'IDFC FIRST Bank',
      regex:
          r'(?<action>debited|credited)\s+(?:by|with|for)\s+(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+)'
          r'(?:\s+(?:to|from)\s+(?<merchant>.*?))?\s+on\s+(?<date>[\d/-]+\s+[\d:]+)',
    ),

    // 2. HDFC BANK
    BankPattern(
      name: 'HDFC Bank',
      regex:
          r'(?<action>credited|debited).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)\s+(?:on|at|HDFC)',
    ),

    // 3. AXIS BANK
    BankPattern(
      name: 'Axis Bank',
      regex:
          r'Transaction Amount:\s*(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?Merchant Name:\s*(?<merchant>.*?)\s+(?:Axis|Date|on)',
    ),

    // 4. SBI CARD
    BankPattern(
      name: 'SBI Card',
      regex:
          r'(?:Rs\.?|INR|₹)\s*(?<amount>[\d,.]+)\s+spent\s+on\s+.*?at\s+(?<merchant>.*?)\s+on\s+(?<date>\d{2}/\d{2}/\d{2})',
    ),

    // 5. FEDERAL BANK
    BankPattern(
      name: 'Federal Bank',
      regex:
          r'(?<action>debited|credited).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:to|from)?\s*(?<merchant>.*?)\s+(?:on|dated)',
    ),

    // 6. ICICI BANK
    BankPattern(
      name: 'ICICI Bank',
      regex:
          r'(?<action>debited|credited).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:to|from|towards)\s+(?<merchant>.*?)\s+on',
    ),

    // 7. UPI/DIGITAL WALLETS (PhonePe, PayTM, GPay)
    BankPattern(
      name: 'UPI Transaction',
      regex:
          r'(?:PhonePe|PayTM|Google Pay).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:to|at|from)\s+(?<merchant>.*?)(?:\s+on|\s+at|$)',
    ),

    // 8. SALARY & GENERAL CREDITS (kept last — broadest pattern, so
    // specific bank formats above get first shot at matching).
    BankPattern(
      name: 'Salary/Credit Alert',
      regex:
          r'(?:salary|credited|remittance|received).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:from|by|at)\s+(?<merchant>[\w\s\-\.]+)',
    ),
  ];

  // Known bank identifiers used purely to tag the source bank when a
  // specific regex above doesn't fire and we fall back to the generic
  // parser. This is what lets "any bank" show up with a sensible name
  // on the review card instead of "General Transaction".
  static const Map<String, String> _bankKeywords = {
    'idfc': 'IDFC FIRST Bank',
    'hdfc': 'HDFC Bank',
    'axis': 'Axis Bank',
    'sbi': 'SBI',
    'icici': 'ICICI Bank',
    'kotak': 'Kotak Mahindra Bank',
    'federal bank': 'Federal Bank',
  };

  static Future<DetectedTransaction?> parse(
    String emailId,
    String body,
    String snippet,
    DateTime emailDate, {
    AICategorizationService? aiCategorizationService,
  }) async {
    // 1. CLEANING
    String combined = "$snippet $body";
    String cleanBody = combined
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\n\r]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = cleanBody.toLowerCase();

    // 2. GUARD LAYER — now transaction-aware, see _isIgnorable below.
    if (_isIgnorable(lower)) {
      return null;
    }

    // Fallback type guess, only used when a matched pattern doesn't
    // carry its own (?<action>...) group.
    String fallbackType = _isCredit(lower) ? 'income' : 'expense';

    // 3. PATTERN MATCHING
    for (var pattern in bankPatterns) {
      final regex = RegExp(pattern.regex, caseSensitive: false);
      final match = regex.firstMatch(cleanBody);
      if (match != null) {
        return await _buildTransaction(
          emailId,
          match,
          cleanBody,
          pattern.name,
          emailDate,
          fallbackType,
          aiCategorizationService: aiCategorizationService,
        );
      }
    }

    // 4. GENERIC FALLBACK
    return await _parseGeneric(
      emailId,
      cleanBody,
      lower,
      emailDate,
      fallbackType,
      aiCategorizationService: aiCategorizationService,
    );
  }

  static bool _isCredit(String lower) {
    if (lower.contains('refund policy')) {
      return false;
    }
    return lower.contains('received from') ||
        lower.contains('credited') ||
        lower.contains('refunded') ||
        lower.contains('salary');
  }

  static bool _isIgnorable(String lower) {
    // If the email clearly reads like a transaction alert, don't let
    // disclaimer boilerplate (which almost always mentions OTP/CVV as
    // a "never share this" warning) discard it.
    final looksLikeTransaction = RegExp(
      r'\b(debited|credited|spent|withdrawn|txn of|transaction of|purchase of|paid)\b',
    ).hasMatch(lower);

    if (looksLikeTransaction) {
      // Only block if it's actually delivering an OTP alongside the
      // transaction text (rare, but be safe), not just mentioning it.
      if (RegExp(r'\botp\s*(is|:)\s*\d').hasMatch(lower)) return true;
      if (lower.contains('payment failed') ||
          lower.contains('transaction declined')) {
        return true;
      }
      if (lower.contains('bill generated') && !lower.contains('paid')) {
        return true;
      }
      return false;
    }

    // Not transaction-shaped at all — apply the stricter guard.
    if (lower.contains('otp') || lower.contains('verification code')) {
      return true;
    }
    if (lower.contains('payment failed') ||
        lower.contains('transaction declined')) {
      return true;
    }
    if (lower.contains('bill generated') && !lower.contains('paid')) {
      return true;
    }
    return false;
  }

  // Grabs "New balance is INR 26.29CR" / "Available balance: Rs 1,200"
  // style phrases. Optional — most SMS alerts won't have this, most
  // bank emails will.
  static final RegExp _balancePattern = RegExp(
    r'(?:new balance|available balance|avl bal|balance)\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)\s*([\d,.]+)',
    caseSensitive: false,
  );

  static double? _extractBalance(String text) {
    final match = _balancePattern.firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  static String? _detectBankName(String lower) {
    for (var entry in _bankKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static Future<DetectedTransaction?> _parseGeneric(
    String id,
    String text,
    String lower,
    DateTime date,
    String type, {
    AICategorizationService? aiCategorizationService,
  }) async {
    final amountPattern = RegExp(
      r'(?:(?:Rs\.?|INR|₹|Total)\s?\.?\s*)([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final match = amountPattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    double amount = double.parse(match.group(1)!.replaceAll(',', ''));
    if (amount == 0) {
      return null;
    }

    // Try a known brand first, then fall back to the detected bank
    // name, then finally a generic label.
    final detectedBank = _detectBankName(lower);
    final brand = _scanForBrands(lower);
    String merchant = brand ?? detectedBank ?? "General Transaction";

    // Generic-parser matches are guesses by construction (no bank
    // format was recognized), so confidence stays modest and we flag
    // it for review rather than silently trusting it.
    final warnings = <String>[];
    if (brand == null) warnings.add('Merchant unclear');
    if (detectedBank == null) warnings.add('Bank not identified');

    return _finalizeTransaction(
      id,
      amount,
      merchant,
      date,
      type,
      text,
      aiCategorizationService,
      confidence: 0.55,
      warnings: warnings,
      bankName: detectedBank,
      balanceAfter: _extractBalance(text),
    );
  }

  static String? _scanForBrands(String lower) {
    final brands = {
      'jio': 'Jio',
      'airtel': 'Airtel',
      'swiggy': 'Swiggy',
      'zomato': 'Zomato',
      'uber': 'Uber',
      'ola': 'Ola',
      'amazon': 'Amazon',
      'flipkart': 'Flipkart',
      'netflix': 'Netflix',
      'spotify': 'Spotify',
      'google play': 'Google Play',
      'bescom': 'BESCOM',
      'razorpay': 'Razorpay',
    };
    for (var entry in brands.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static Future<DetectedTransaction?> _buildTransaction(
    String id,
    RegExpMatch match,
    String fullBody,
    String bankName,
    DateTime emailDate,
    String fallbackType, {
    AICategorizationService? aiCategorizationService,
  }) async {
    try {
      double amount = double.parse(
        match.namedGroup('amount')!.replaceAll(',', ''),
      );

      // Merchant: prefer the captured group, but fall back to the bank
      // name if it's missing or came back empty (e.g. plain "A/C
      // debited" alerts with no counterparty in the message).
      String merchant = bankName;
      bool merchantWasCaptured = false;
      if (match.groupNames.contains('merchant')) {
        final captured = match.namedGroup('merchant')?.trim();
        if (captured != null && captured.isNotEmpty) {
          merchant = captured;
          merchantWasCaptured = true;
        }
      }

      // Type: prefer the action captured right next to the amount.
      // Only fall back to the whole-body guess if this pattern didn't
      // capture an action group (e.g. Axis, SBI Card, UPI patterns).
      String type = fallbackType;
      bool actionWasCaptured = false;
      if (match.groupNames.contains('action')) {
        final action = match.namedGroup('action')?.toLowerCase();
        if (action != null) {
          type = action.contains('credit') ? 'income' : 'expense';
          actionWasCaptured = true;
        }
      }

      // Confidence reflects how much of the match came from a
      // structured bank-specific pattern vs. an assumption:
      // - action captured directly next to amount: type is certain
      // - merchant captured directly: counterparty is certain
      // Missing either drops confidence and adds a review flag,
      // rather than presenting a guess as a sure thing.
      double confidence = 0.95;
      final warnings = <String>[];
      if (!actionWasCaptured) {
        confidence -= 0.15;
        warnings.add('Transaction type inferred, not confirmed');
      }
      if (!merchantWasCaptured) {
        confidence -= 0.10;
        warnings.add('Merchant unclear - using bank name');
      }

      return _finalizeTransaction(
        id,
        amount,
        merchant,
        emailDate,
        type,
        fullBody,
        aiCategorizationService,
        confidence: confidence.clamp(0.0, 1.0),
        warnings: warnings,
        bankName: bankName,
        balanceAfter: _extractBalance(fullBody),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<DetectedTransaction> _finalizeTransaction(
    String id,
    double amount,
    String merchant,
    DateTime date,
    String type,
    String body,
    AICategorizationService? aiService, {
    double confidence = 0.8,
    List<String> warnings = const [],
    String? bankName,
    double? balanceAfter,
  }) async {
    final category = SmartCategoryResolver.resolve(
      merchant: merchant,
      body: body,
      amount: amount,
      transactionType: type,
    );

    final fingerprint = '${amount}_${merchant}_${date.toIso8601String()}_$type'
        .hashCode
        .toRadixString(16);

    return DetectedTransaction(
      id: id,
      fingerprint: fingerprint,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'email',
      body: body,
      confidence: confidence,
      warnings: warnings,
      detectedCategory: category,
      bankName: bankName,
      balanceAfter: balanceAfter,
    );
  }
}
