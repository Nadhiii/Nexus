import 'package:intl/intl.dart';
import '../../models/detected_transaction.dart';

class GmailParser {
  static DetectedTransaction? parse(
    String emailId,
    String body,
    String snippet,
    DateTime emailDate,
  ) {
    String combined = "$snippet $body";
    String cleanBody = combined
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\n\r]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = cleanBody.toLowerCase();

    // 1. GUARD GATE
    if (_isJunk(lower)) {
      return null;
    }

    // 2. IGNORE LIST
    if (lower.contains('credited to your loan') ||
        lower.contains('credited to loan')) {
      return null;
    }
    if (lower.contains('beneficiary') && lower.contains('has received')) {
      return null;
    }

    String type = 'expense';
    if (lower.contains('refund') ||
        lower.contains('received from') ||
        lower.contains('credited')) {
      type = 'income';
    }

    // --- PATTERN A: SBI Card ---
    // Captures date like 17/11/25 (No time info)
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

    // --- PATTERN B: Axis Bank ---
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

    // --- PATTERN C: IDFC (Detailed) ---
    // Captures date AND time
    final idfcDetailed = RegExp(
      r'(?:debited|credited)\s+(?:by|with)\s+(?:INR|Rs\.?)\s*(?<amount>[\d,.]+)\s+(?:on|to)\s+(?<date>[\d/-]+\s+[\d:]+).*?(?:received\s+from|paid\s+to)\s+(?<merchant>.*?)(?:\.|$)',
      caseSensitive: false,
    ).firstMatch(cleanBody);

    if (idfcDetailed != null) {
      return _buildTransaction(
        emailId,
        idfcDetailed,
        cleanBody,
        'IDFC FIRST Bank',
        emailDate,
        type,
      );
    }

    // --- PATTERN D: IDFC (Fallback) ---
    final idfcFallback = RegExp(
      r'(?:debited|credited)\s+(?:by|with)\s+(?:INR|Rs\.?)\s*(?<amount>[\d,.]+)\s+(?:on|to)\s+(?<date>[\d/-]+\s+[\d:]+)',
      caseSensitive: false,
    ).firstMatch(cleanBody);

    if (idfcFallback != null) {
      return _buildTransaction(
        emailId,
        idfcFallback,
        cleanBody,
        'IDFC FIRST Bank',
        emailDate,
        type,
      );
    }

    // Fallback
    return _parseGeneric(emailId, cleanBody, emailDate, type);
  }

  static bool _isJunk(String lower) {
    if (lower.contains('is your otp') ||
        lower.contains('otp for transaction') ||
        lower.contains('verification code') ||
        lower.contains('one time password')) {
      return true;
    }

    if (lower.contains('trial subscription') || lower.contains('free trial')) {
      return true;
    }

    if (lower.contains('payment failed') ||
        lower.contains('transaction failed') ||
        lower.contains('declined')) {
      return true;
    }

    if (lower.contains('total outstanding') ||
        lower.contains('minimum amount due') ||
        lower.contains('immediate amount due') ||
        lower.contains('payment due date') ||
        lower.contains('reminder for payment') ||
        lower.contains('overdue') ||
        lower.contains('not received the payment') ||
        lower.contains('statement generated')) {
      if (!lower.contains('payment received') &&
          !lower.contains('thank you for')) {
        return true;
      }
    }

    return false;
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

      // FIX: Intelligent Date Merging
      DateTime date = emailDate;
      if (match.groupNames.contains('date')) {
        final parsedDate = _parseDate(match.namedGroup('date')!);
        if (parsedDate != null) {
          // If the parsed date is exactly midnight (00:00:00), it likely had no time info (like SBI).
          // So we take the Date from the body, but the Time from the email.
          if (parsedDate.hour == 0 &&
              parsedDate.minute == 0 &&
              parsedDate.second == 0) {
            date = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              emailDate.hour,
              emailDate.minute,
              emailDate.second,
            );
          } else {
            // If it has time (like IDFC), use it.
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

  static DetectedTransaction? _parseGeneric(
    String id,
    String body,
    DateTime emailDate,
    String type,
  ) {
    if (body.contains(
      RegExp(
        r'(?:Rs\.?|INR|₹)\.?\s*[\d,.]+\s*/\s*(?:month|year|mo|yr)',
        caseSensitive: false,
      ),
    )) {
      return null;
    }

    final amountPattern = RegExp(
      r'(?:paid|sent|spent|purchase|debited|credited|refund)\s.*?(?:Rs\.?|INR|₹)\.?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final match = amountPattern.firstMatch(body);

    final strictAmount = RegExp(
      r'(?:Rs\.?|INR|₹)\.?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(body);

    String? amountStr = match?.group(1) ?? strictAmount?.group(1);
    if (amountStr == null) return null;

    double? amount = double.tryParse(amountStr.replaceAll(',', ''));
    if (amount == null || amount == 0) return null;

    String merchant = "Unknown Merchant";
    final merchantMatch = RegExp(
      r'(?:to|at)\s+([A-Za-z0-9\s\.]+)(?:\s+(?:on|for)|$)',
      caseSensitive: false,
    ).firstMatch(body);

    if (merchantMatch != null) {
      String m = merchantMatch.group(1)!.trim();
      if (_isValidMerchant(m)) merchant = m;
    } else {
      return null;
    }

    return DetectedTransaction(
      id: id,
      amount: amount,
      merchant: merchant,
      date: emailDate,
      type: type,
      source: 'email',
      body: body,
    );
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
      'unknown',
      'view',
      'click',
      'policy',
      'safe banking',
      'report',
      'call',
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
