import '../models/detected_transaction.dart';
import '../services/transaction_intelligence_service.dart';
import '../models/knowledge_entry.dart';
import '../models/transaction.dart';

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

    // 8. SLICE (slice small finance bank)
    // Format: "You have received ₹404 via UPI in your slice bank
    // account xx8047. Avl. Bal. ₹405.98 Transaction date 04-Jul-26
    // From NANDINI MILK GALAXY AND CAFE M RRN 618566376353"
    // Covers both incoming ("From") and outgoing ("To") phrasing.
    BankPattern(
      name: 'Slice',
      regex:
          r'you have (?<action>received|paid|sent)\s+(?:₹|Rs\.?|INR)\s*(?<amount>[\d,.]+)\s+via\s+upi'
          r'.*?transaction date\s+(?<date>\d{1,2}-[A-Za-z]{3}-\d{2,4})'
          r'.*?(?:from|to)\s+(?<merchant>.*?)\s+rrn',
    ),

    // 9. CARD PURCHASE ("You have made a purchase for ₹X on <date> at
    // <merchant> using <bank> Debit/Credit Card"). Seen from IDFC FIRST
    // Bank; phrasing doesn't contain debited/credited so it needs its own
    // pattern rather than relying on the action-based ones above.
    BankPattern(
      name: 'Card Purchase',
      regex:
          r'made a purchase for\s+(?:₹|Rs\.?|INR)\s*(?<amount>[\d,.]+)\s+on\s+'
          r'(?<date>[\d/-]+(?:\s+[\d:]+)?)\s+at\s+(?<merchant>.*?)\s+using',
    ),

    // 10. SALARY & GENERAL CREDITS (kept last — broadest pattern, so
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
    'slice': 'Slice',
  };

  static Future<DetectedTransaction?> parse(
    String emailId,
    String body,
    String snippet,
    DateTime emailDate,
  ) async {
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
    );
  }

  // Matches phrasing like "credited to your Loan account no. XX2965" or
  // "credited to your Card account". Banks use "credited" here to mean
  // money went INTO the loan/card account on your behalf — i.e. you made
  // a repayment. That's an expense from the user's perspective, even
  // though the literal word is "credited". Without this guard, every EMI/
  // credit-card repayment confirmation email gets typed as income.
  static final RegExp _loanOrCardAccountCreditPattern = RegExp(
    r'credited\s+(?:to|towards)\s+(?:your\s+)?(?:loan|card)\s+(?:account|a/?c)',
    caseSensitive: false,
  );

  static bool _isLoanOrCardRepayment(String lower) {
    return _loanOrCardAccountCreditPattern.hasMatch(lower);
  }

  static bool _isCredit(String lower) {
    if (lower.contains('refund policy')) {
      return false;
    }
    if (_isLoanOrCardRepayment(lower)) {
      return false;
    }
    return lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('refunded') ||
        lower.contains('salary');
  }

  static bool _isIgnorable(String lower) {
    // Scheduled / future debits — nothing has moved yet, this is a setup
    // confirmation (e.g. "₹1,000 will be debited ... next debit scheduled
    // on 01 Oct" from a slice/UPI auto-save or autopay mandate setup).
    // Without this guard these get recorded as real transactions that
    // haven't actually happened.
    final isFutureScheduled =
        RegExp(r'\bwill be (?:debited|charged|deducted)\b').hasMatch(lower) &&
        (lower.contains('scheduled') ||
            lower.contains('auto save') ||
            lower.contains('autopay') ||
            lower.contains('has been set up'));
    if (isFutureScheduled) return true;

    // These are payment/subscription notices, not evidence that money moved.
    // In particular, Google Play can contain an amount and words like
    // "payment"/"subscription" while explicitly saying no charge happened.
    final noMoneyMovement = [
      'payment due',
      'payment is due',
      'amount due',
      'too low to pay',
      'needs attention',
      'update your payment method',
      'choose how to manage your subscription',
      'cancel subscription',
    ];
    if (noMoneyMovement.any(lower.contains) &&
        !RegExp(
          r'\b(debited|credited|received|spent|withdrawn|purchase of|paid)\b',
        ).hasMatch(lower)) {
      return true;
    }

    // If the email clearly reads like a transaction alert, don't let
    // disclaimer boilerplate (which almost always mentions OTP/CVV as
    // a "never share this" warning) discard it.
    final looksLikeTransaction = RegExp(
      r'\b(debited|credited|received|spent|withdrawn|txn of|transaction of|purchase of|paid)\b',
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
    r'(?:new balance|available balance|avl\.?\s*bal\.?|balance)\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)\s*([\d,.]+)',
    caseSensitive: false,
  );

  static double? _extractBalance(String text) {
    final match = _balancePattern.firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  static const Map<String, int> _monthAbbreviations = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  // Turns a captured date string into a real DateTime, trying each
  // format banks in bankPatterns actually use. Falls back to the
  // email's own timestamp if the string doesn't match anything known
  // or looks implausible (e.g. malformed capture).
  static DateTime _parseCapturedDate(String raw, DateTime fallback) {
    final trimmed = raw.trim();

    // dd/MM/yyyy[ HH:mm]  — IDFC, HDFC, ICICI, Federal Bank
    final slash = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{2,4})(?:\s+(\d{1,2}):(\d{2}))?$',
    ).firstMatch(trimmed);
    if (slash != null) {
      try {
        final day = int.parse(slash.group(1)!);
        final month = int.parse(slash.group(2)!);
        var year = int.parse(slash.group(3)!);
        if (year < 100) year += 2000;
        final hour = slash.group(4) != null ? int.parse(slash.group(4)!) : 0;
        final minute = slash.group(5) != null ? int.parse(slash.group(5)!) : 0;
        return DateTime(year, month, day, hour, minute);
      } catch (_) {
        return fallback;
      }
    }

    // dd-MMM-yy or dd-MMM-yyyy — Slice
    final dashMonth = RegExp(
      r'^(\d{1,2})-([A-Za-z]{3})-(\d{2,4})$',
    ).firstMatch(trimmed);
    if (dashMonth != null) {
      final month = _monthAbbreviations[dashMonth.group(2)!.toLowerCase()];
      if (month != null) {
        try {
          final day = int.parse(dashMonth.group(1)!);
          var year = int.parse(dashMonth.group(3)!);
          if (year < 100) year += 2000;
          return DateTime(year, month, day);
        } catch (_) {
          return fallback;
        }
      }
    }

    return fallback;
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
    String type,
  ) async {
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
    String fallbackType,
  ) async {
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

      // Override: "credited to your Loan/Card account" is a repayment
      // (expense), not income, regardless of which pattern matched or
      // what its action group captured.
      if (_isLoanOrCardRepayment(fullBody.toLowerCase())) {
        type = 'expense';
      }

      // Date: prefer the transaction date captured from the email body
      // over the email's arrival timestamp — these can differ when
      // Gmail sync lags or a bank sends a delayed/batched alert.
      DateTime txnDate = emailDate;
      if (match.groupNames.contains('date')) {
        final capturedDate = match.namedGroup('date')?.trim();
        if (capturedDate != null && capturedDate.isNotEmpty) {
          txnDate = _parseCapturedDate(capturedDate, emailDate);
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
      if (_isLoanOrCardRepayment(fullBody.toLowerCase())) {
        warnings.add('Detected as loan/card repayment, not income');
      }

      return _finalizeTransaction(
        id,
        amount,
        merchant,
        txnDate,
        type,
        fullBody,
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
    String body, {
    double confidence = 0.8,
    List<String> warnings = const [],
    String? bankName,
    double? balanceAfter,
  }) async {
    final detected = DetectedTransaction(
      id: id,
      fingerprint: '',
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'email',
      body: body,
      confidence: confidence,
      warnings: warnings,
      bankName: bankName,
      balanceAfter: balanceAfter,
    );
    final understanding = const TransactionIntelligenceService().analyze(
      detected: detected,
      history: const <Transaction>[],
      knowledge: const <KnowledgeEntry>[],
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
      detectedCategory: understanding.categoryId ?? 'other',
      bankName: bankName,
      balanceAfter: balanceAfter,
    );
  }
}
