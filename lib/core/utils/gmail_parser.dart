import '../models/detected_transaction.dart';
import '../services/ai_categorization_service.dart';
import '../services/smart_category_resolver.dart';

class BankPattern {
  final String name;
  final String regex;

  const BankPattern({required this.name, required this.regex});
}

class GmailParser {
  static const List<BankPattern> bankPatterns = [
    // 1. SALARY & GENERAL CREDITS (Highest Priority)
    BankPattern(
      name: 'Salary/Credit Alert',
      regex:
          r'(?:salary|credited|remittance|received).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:from|by|at)\s+(?<merchant>[\w\s\-\.]+)',
    ),
    // 2. AXIS BANK
    BankPattern(
      name: 'Axis Bank',
      regex:
          r'Transaction Amount:\s*(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?Merchant Name:\s*(?<merchant>.*?)\s+(?:Axis|Date|on)',
    ),
    // 3. IDFC FIRST BANK
    BankPattern(
      name: 'IDFC FIRST Bank',
      regex:
          r'(?:debited|credited)\s+(?:by|with)\s+(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+)(?:\s+(?:to|from)\s+(?<merchant>.*?))?\s+on\s+(?<date>[\d/-]+\s+[\d:]+)',
    ),
    // 4. HDFC BANK
    BankPattern(
      name: 'HDFC Bank',
      regex:
          r'(?:credited|debited).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)\s+(?:on|at|HDFC)',
    ),
    // 5. SBI CARD
    BankPattern(
      name: 'SBI Card',
      regex:
          r'(?:Rs\.?|INR|₹)\s*(?<amount>[\d,.]+)\s+spent\s+on\s+.*?at\s+(?<merchant>.*?)\s+on\s+(?<date>\d{2}/\d{2}/\d{2})',
    ),
    // 6. UPI/DIGITAL WALLETS (PhonePe, PayTM, GPay)
    BankPattern(
      name: 'UPI Transaction',
      regex:
          r'(?:PhonePe|PayTM|Google Pay).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?:to|at|from)\s+(?<merchant>.*?)(?:\s+on|\s+at|$)',
    ),
  ];

  static Future<DetectedTransaction?> parse(
    String emailId,
    String body,
    String snippet,
    DateTime emailDate, {
    AICategorizationService? aiCategorizationService,
  }) async {
    // 1. CLEANING - Softened to preserve more context
    String combined = "$snippet $body";
    String cleanBody = combined
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\n\r]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = cleanBody.toLowerCase();

    // 2. BALANCED GUARD LAYER
    if (_isIgnorable(lower)) { return null; }

    String type = 'expense';
    if (_isCredit(lower)) {
      type = 'income';
    }

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
          type,
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
      type,
      aiCategorizationService: aiCategorizationService,
    );
  }

  static bool _isCredit(String lower) {
    // Ignore "refund policy" mentions, but catch real credits
    if (lower.contains('refund policy')) { return false; }
    return lower.contains('received from') ||
        lower.contains('credited') ||
        lower.contains('refunded') ||
        lower.contains('salary');
  }

  static bool _isIgnorable(String lower) {
    // Only block actual non-financial spam/security
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

  static Future<DetectedTransaction?> _parseGeneric(
    String id,
    String text,
    String lower,
    DateTime date,
    String type, {
    AICategorizationService? aiCategorizationService,
  }) async {
    // Amount extraction logic
    final amountPattern = RegExp(
      r'(?:(?:Rs\.?|INR|₹|Total)\s?\.?\s*)([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final match = amountPattern.firstMatch(text);
    if (match == null) { return null; }

    double amount = double.parse(match.group(1)!.replaceAll(',', ''));
    if (amount == 0) { return null; }

    // AI or Keyword Merchant detection
    String merchant = _scanForBrands(lower) ?? "General Transaction";

    return _finalizeTransaction(
      id,
      amount,
      merchant,
      date,
      type,
      text,
      aiCategorizationService,
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
      'axis': 'Axis Bank',
    };
    for (var entry in brands.entries) {
      if (lower.contains(entry.key)) { return entry.value; }
    }
    return null;
  }

  static Future<DetectedTransaction?> _buildTransaction(
    String id,
    RegExpMatch match,
    String fullBody,
    String bankName,
    DateTime emailDate,
    String type, {
    AICategorizationService? aiCategorizationService,
  }) async {
    try {
      double amount = double.parse(
        match.namedGroup('amount')!.replaceAll(',', ''),
      );
      String merchant = match.groupNames.contains('merchant')
          ? (match.namedGroup('merchant')?.trim() ?? bankName)
          : bankName;

      return _finalizeTransaction(
        id,
        amount,
        merchant,
        emailDate,
        type,
        fullBody,
        aiCategorizationService,
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
    AICategorizationService? aiService,
  ) async {
    final category = SmartCategoryResolver.resolve(
      merchant: merchant,
      body: body,
      amount: amount,
      transactionType: type,
    );

    return DetectedTransaction(
      id: id,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'email',
      body: body,
      detectedCategory: category,
    );
  }
}
