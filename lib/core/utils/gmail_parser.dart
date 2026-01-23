import 'package:intl/intl.dart';
import '../models/detected_transaction.dart';

class GmailParser {
  static DetectedTransaction? parse(
    String emailId,
    String body,
    String snippet,
    DateTime emailDate,
  ) {
    // 1. CLEANING
    String combined = "$snippet $body";
    String cleanBody = combined
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\n\r]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = cleanBody.toLowerCase();

    // 2. STRICT GUARD (The New "Anti-Spam" Layer)
    if (_isIgnorable(lower)) {
      return null;
    }

    String type = 'expense';
    if (lower.contains('refund') ||
        lower.contains('received from') ||
        lower.contains('credited')) {
      type = 'income';
    }

    // --- BANK SPECIFIC PATTERNS (High Precision) ---

    // PATTERN A: SBI Card
    final sbiMatch = RegExp(
      r'(?:Rs\.?|INR)\s*(?<amount>[\d,.]+)\s+spent\s+on\s+.*?at\s+(?<merchant>.*?)\s+on\s+(?<date>\d{2}/\d{2}/\d{2})',
      caseSensitive: false,
    ).firstMatch(cleanBody);
    if (sbiMatch != null) {
      return _buildTransaction(
        emailId,
        sbiMatch,
        cleanBody,
        'SBI Card',
        emailDate,
        type,
      );
    }

    // PATTERN B: Axis Bank
    final axisMatch = RegExp(
      r'Transaction Amount:\s*(?:INR|Rs\.?)\s*(?<amount>[\d,.]+).*?Merchant Name:\s*(?<merchant>.*?)\s+(?:Axis|Date)',
      caseSensitive: false,
    ).firstMatch(cleanBody);
    if (axisMatch != null) {
      return _buildTransaction(
        emailId,
        axisMatch,
        cleanBody,
        'Axis Bank',
        emailDate,
        type,
      );
    }

    // PATTERN C: IDFC
    final idfcMatch = RegExp(
      r'(?:debited|credited)\s+(?:by|with)\s+(?:INR|Rs\.?)\s*(?<amount>[\d,.]+)\s+(?:on|to)\s+(?<date>[\d/-]+\s+[\d:]+)',
      caseSensitive: false,
    ).firstMatch(cleanBody);
    if (idfcMatch != null) {
      return _buildTransaction(
        emailId,
        idfcMatch,
        cleanBody,
        'IDFC FIRST Bank',
        emailDate,
        type,
      );
    }

    // --- GENERIC FALLBACK (Context Aware) ---
    return _parseGeneric(emailId, cleanBody, lower, emailDate, type);
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
  static DetectedTransaction? _parseGeneric(
    String id,
    String text,
    String lower,
    DateTime date,
    String type,
  ) {
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

    return DetectedTransaction(
      id: id,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'email',
      body: text,
    );
  }

  // --- HELPERS ---

  static String? _scanForBrands(String lower) {
    // Add common Indian services here
    final brands = {
      'jio': 'Jio',
      'airtel': 'Airtel',
      'vi ': 'Vodafone',
      'act fibernet': 'ACT',
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
    };

    for (var key in brands.keys) {
      if (lower.contains(key)) return brands[key];
    }
    return null;
  }

  static DetectedTransaction? _buildTransaction(
    String id,
    RegExpMatch match,
    String fullBody,
    String bankName,
    DateTime emailDate,
    String type,
  ) {
    try {
      String amountStr = match.namedGroup('amount')!.replaceAll(',', '');
      double amount = double.parse(amountStr);
      if (amount == 0) return null;

      String merchant = bankName;
      if (match.groupNames.contains('merchant')) {
        String? m = match.namedGroup('merchant')?.trim();
        if (m != null && _isValidMerchant(m)) {
          merchant = m;
        }
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

      return DetectedTransaction(
        id: id,
        amount: amount,
        merchant: merchant,
        date: date,
        type: type,
        source: 'email',
        body: fullBody,
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
