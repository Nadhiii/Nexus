import 'package:intl/intl.dart';
import '../models/detected_transaction.dart';
import '../services/ai_categorization_service.dart';

class BankPattern {
  final String name;
  final String regex;

  const BankPattern({required this.name, required this.regex});
}

class GmailParser {
  // Bank pattern definitions for easy maintenance
  static const List<BankPattern> bankPatterns = [
    // SBI Card
    BankPattern(
      name: 'SBI Card',
      regex:
          r'(?:Rs\.?|INR)\s*(?<amount>[\d,.]+)\s+spent\s+on\s+.*?at\s+(?<merchant>.*?)\s+on\s+(?<date>\d{2}/\d{2}/\d{2})',
    ),
    // Axis Bank
    BankPattern(
      name: 'Axis Bank',
      regex:
          r'Transaction Amount:\s*(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?Merchant Name:\s*(?<merchant>.*?)\s+(?:Axis|Date)',
    ),
    // IDFC Bank
    BankPattern(
      name: 'IDFC FIRST Bank',
      regex:
          r'(?:debited|credited)\s+(?:by|with)\s+(?:INR|Rs\.?)\s*(?<amount>[\d,.]+)(?:\s+to\s+(?<merchant>.*?))?\s+on\s+(?<date>[\d/-]+\s+[\d:]+)',
    ),
    // HDFC Bank
    BankPattern(
      name: 'HDFC Bank',
      regex:
          r'(?:credited|debited).*?(?:INR|Rs\.?|₹)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)\s+(?:on|at|HDFC)',
    ),
    // ICICI Bank
    BankPattern(
      name: 'ICICI Bank',
      regex:
          r'amount\s+(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)\s+(?:via|through|ICICI)',
    ),
    // Kotak Mahindra
    BankPattern(
      name: 'Kotak Mahindra Bank',
      regex:
          r'(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)\s+(?:on|debited|credited)',
    ),
    // PayTM
    BankPattern(
      name: 'PayTM',
      regex:
          r'PayTM.*?(?:amount|INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)(?:\s+to|\s+on|$)',
    ),
    // Google Pay
    BankPattern(
      name: 'Google Pay',
      regex:
          r'Google Pay.*?(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)(?:\s+to|\s+received|$)',
    ),
    // PhonePe
    BankPattern(
      name: 'PhonePe',
      regex:
          r'PhonePe.*?(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)(?:\s+to|\s+on|$)',
    ),
    // Amazon Pay
    BankPattern(
      name: 'Amazon Pay',
      regex:
          r'Amazon Pay.*?(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?(?<merchant>.*?)(?:\s+on|\s+for|$)',
    ),
  ];

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

    // 2. STRICT GUARD (The "Anti-Spam" Layer)
    if (_isIgnorable(lower)) {
      return null;
    }

    String type = 'expense';
    if (lower.contains('refund') ||
        lower.contains('received from') ||
        lower.contains('credited')) {
      type = 'income';
    }

    // --- BANK-SPECIFIC PATTERNS (High Precision) ---
    for (var pattern in bankPatterns) {
      final regex = RegExp(pattern.regex, caseSensitive: false);
      final match = regex.firstMatch(cleanBody);
      if (match != null) {
        final transaction = await _buildTransaction(
          emailId,
          match,
          cleanBody,
          pattern.name,
          emailDate,
          type,
          aiCategorizationService: aiCategorizationService,
        );
        if (transaction != null) return transaction;
      }
    }

    // --- GENERIC FALLBACK (Context Aware) ---
    return await _parseGeneric(
      emailId,
      cleanBody,
      lower,
      emailDate,
      type,
      aiCategorizationService: aiCategorizationService,
    );
  }

  // --- STRICT FILTERING ---
  static bool _isIgnorable(String lower) {
    // 1. Security / OTPs
    if (lower.contains('otp') || lower.contains('verification code')) {
      return true;
    }

    // 2. Debt / Missed Payments (Flipkart Example)
    if (lower.contains('not made your payment')) return true;
    if (lower.contains('overdue')) return true;

    // 3. Low Balance (Surfshark Example)
    if (lower.contains('balance is too low') || lower.contains('add credit')) {
      return true;
    }

    // 4. Future / Requests / Setup
    if (lower.contains('autopay') &&
        (lower.contains('registered') ||
            lower.contains('request') ||
            lower.contains('setup'))) {
      return true;
    }
    if (lower.contains('mandate') && lower.contains('success')) return true;
    if (lower.contains('request received') ||
        lower.contains('will be debited')) {
      return true;
    }

    // 5. Failures
    if (lower.contains('payment failed') ||
        lower.contains('transaction declined')) {
      return true;
    }

    // 6. Not a Transaction
    if (lower.contains('statement generated') ||
        lower.contains('total outstanding')) {
      return true;
    }
    if (lower.contains('payment due') || lower.contains('bill generated')) {
      return true;
    }

    return false;
  }

  // --- GENERIC PARSER ---
  static Future<DetectedTransaction?> _parseGeneric(
    String id,
    String text,
    String lower,
    DateTime date,
    String type, {
    AICategorizationService? aiCategorizationService,
  }) async {
    // 1. Find Amount
    final amountPattern = RegExp(
      r'(?:Rs\.?|INR|₹)\s?\.?\s*([0-9,]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final amountMatch = amountPattern.firstMatch(text);

    if (amountMatch == null) return null;

    double amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == 0) return null;

    // 2. Find Merchant (Smart Strategies)
    String merchant = "Unknown (Email)";

    // Strategy A: "Subscription from [Merchant]" (Google Play Example)
    final subMatch = RegExp(
      r'subscription from\s+(.*?)\s+(?:on|for)',
      caseSensitive: false,
    ).firstMatch(text);

    // Strategy B: "Payment for your [Merchant]" (Jio Example)
    final forMatch = RegExp(
      r'payment.*?for your\s+(.*?)\s+(?:connection|bill|subscription|order)',
      caseSensitive: false,
    ).firstMatch(text);

    // Strategy C: Standard "Paid to/at"
    final atMatch = RegExp(
      r'(?:paid|spent|purchase).*?(?:at|to)\s+([A-Za-z0-9\s]+?)(?:\s+on|\.|$)',
      caseSensitive: false,
    ).firstMatch(text);

    if (subMatch != null) {
      merchant = subMatch.group(1)!.trim();
    } else if (forMatch != null) {
      merchant = forMatch.group(1)!.trim();
    } else if (atMatch != null) {
      merchant = atMatch.group(1)!.trim();
    }

    // Strategy D: Keyword Scanner (The Safety Net)
    // If regex failed or gave us a long sentence, check for known brands
    if (merchant.contains('Unknown') || merchant.length > 25) {
      final knownBrand = _scanForBrands(lower);
      if (knownBrand != null) merchant = knownBrand;
    }

    // AI categorization or fallback
    String? detectedCategory;
    if (aiCategorizationService != null) {
      try {
        final categorySuggestion =
            await aiCategorizationService.suggestCategory(
          merchantName: merchant,
          description: null,
          amount: amount,
          transactionType: type,
          fullMessageBody: text.length > 500 ? text.substring(0, 500) : text,
        );
        detectedCategory = categorySuggestion.category;
      } catch (e) {
        // Fallback to old method if AI fails
        detectedCategory = _detectCategory(merchant);
      }
    } else {
      detectedCategory = _detectCategory(merchant);
    }

    return DetectedTransaction(
      id: id,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'email',
      body: text,
      detectedCategory: detectedCategory,
    );
  }

  // --- HELPERS ---

  static String? _scanForBrands(String lower) {
    // Expanded list of common Indian services and merchants
    final brands = {
      'jio': 'Jio',
      'airtel': 'Airtel',
      'vi ': 'Vodafone',
      'act fibernet': 'ACT Fibernet',
      'bescom': 'BESCOM',
      'flipkart': 'Flipkart',
      'amazon': 'Amazon',
      'swiggy': 'Swiggy',
      'zomato': 'Zomato',
      'uber': 'Uber',
      'ola': 'Ola',
      'netflix': 'Netflix',
      'spotify': 'Spotify',
      'google play': 'Google Play',
      'google ireland': 'Google',
      'surfshark': 'Surfshark',
      'apple': 'Apple',
      'gym': 'Gym Membership',
      'hospital': 'Hospital',
      'pharmacy': 'Pharmacy',
      'fuel': 'Fuel Station',
      'petrol': 'Fuel Station',
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'mall': 'Shopping',
      'groceries': 'Groceries',
      'supermarket': 'Supermarket',
      'cinema': 'Entertainment',
      'movie': 'Entertainment',
      'hotel': 'Hotel',
      'flights': 'Travel',
      'train': 'Travel',
      'bus': 'Travel',
      'insurance': 'Insurance',
      'electricity': 'Utilities',
      'water': 'Utilities',
      'internet': 'Utilities',
      'mobile': 'Mobile Recharge',
    };

    for (var key in brands.keys) {
      if (lower.contains(key)) return brands[key];
    }
    return null;
  }

  // Category detection based on merchant name
  static String? _detectCategory(String merchant) {
    final lower = merchant.toLowerCase();

    final categoryMap = {
      'food': [
        'zomato',
        'swiggy',
        'restaurant',
        'cafe',
        'pizza',
        'burger',
        'bakery',
      ],
      'transportation': [
        'uber',
        'ola',
        'uber eats',
        'fuel',
        'petrol',
        'parking',
        'taxi',
      ],
      'groceries': ['supermarket', 'grocery', 'dm', 'lulu', 'reliance fresh'],
      'entertainment': [
        'netflix',
        'spotify',
        'amazon prime',
        'cinema',
        'movie',
      ],
      'utilities': ['jio', 'airtel', 'vi', 'water', 'electricity', 'internet'],
      'shopping': ['flipkart', 'amazon', 'mall', 'store', 'retail'],
      'health': ['pharmacy', 'hospital', 'clinic', 'gym', 'meditation'],
      'travel': ['hotel', 'flights', 'train', 'bus', 'booking'],
      'subscriptions': ['subscription', 'membership', 'premium'],
    };

    for (var category in categoryMap.entries) {
      for (var keyword in category.value) {
        if (lower.contains(keyword)) {
          return category.key;
        }
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
    String type, {
    AICategorizationService? aiCategorizationService,
  }) async {
    try {
      String amountStr = match.namedGroup('amount')!.replaceAll(',', '');
      double amount = double.parse(amountStr);
      if (amount == 0) return null;

      String merchant = bankName;
      List<String> warnings = [];
      double confidence = 0.8; // Base confidence for bank-detected patterns

      if (match.groupNames.contains('merchant')) {
        String? m = match.namedGroup('merchant')?.trim();
        if (m != null && _isValidMerchant(m)) {
          merchant = m;
          confidence = 0.95; // High confidence when merchant name extracted
        } else if (m != null) {
          warnings.add('Merchant name unclear');
          confidence = 0.65;
        }
      }

      if (merchant == bankName && bankName.contains('IDFC')) {
        warnings.add('Merchant not provided in email');
        merchant = 'IDFC FIRST Bank';
        confidence = 0.7;
      }

      // Intelligent Date Merging
      DateTime date = emailDate;
      if (match.groupNames.contains('date')) {
        final parsedDate = _parseDate(match.namedGroup('date')!);
        if (parsedDate != null) {
          if (parsedDate.hour == 0 && parsedDate.minute == 0) {
            date = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              emailDate.hour,
              emailDate.minute,
              emailDate.second,
            );
          } else {
            date = parsedDate;
          }
        }
      }

      // AI categorization or fallback
      String? detectedCategory;
      if (aiCategorizationService != null) {
        try {
          final categorySuggestion =
              await aiCategorizationService.suggestCategory(
            merchantName: merchant,
            description: null,
            amount: amount,
            transactionType: type,
            fullMessageBody:
                fullBody.length > 500 ? fullBody.substring(0, 500) : fullBody,
          );
          detectedCategory = categorySuggestion.category;
        } catch (e) {
          // Fallback to old method if AI fails
          detectedCategory = _detectCategory(merchant);
        }
      } else {
        detectedCategory = _detectCategory(merchant);
      }

      return DetectedTransaction(
        id: id,
        amount: amount,
        merchant: merchant,
        date: date,
        type: type,
        source: 'email',
        body: fullBody,
        confidence: confidence,
        warnings: warnings,
        detectedCategory: detectedCategory,
      );
    } catch (e) {
      return null;
    }
  }

  static bool _isValidMerchant(String m) {
    if (m.length < 2 || m.length > 60) return false;
    final lower = m.toLowerCase();
    final junk = [
      'unsubscribe',
      'register',
      'login',
      'verify',
      'sincerely',
      'team',
      'view',
      'click',
      'policy',
      'report',
      'your',
      'the',
      'loan',
      'payment',
    ];

    for (var word in junk) {
      if (lower.startsWith(word)) return false;
      if (lower.contains('http') || lower.contains('www')) return false;
    }
    return true;
  }

  static DateTime? _parseDate(String dateStr) {
    String clean = dateStr
        .replaceAll('IST', '')
        .replaceAll(',', '')
        .replaceAll('at', '')
        .trim();
    final formats = [
      'dd/MM/yy',
      'dd-MM-yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'd MMM yyyy',
    ];

    for (var fmt in formats) {
      try {
        return DateFormat(fmt).parse(clean);
      } catch (e) {}
    }
    return null;
  }
}
