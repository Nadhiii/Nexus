import '../models/detected_sms_transaction.dart';

class NewSmsParser {
  static final _amountRegex = RegExp(r'\b(?:inr|rs\.?|₹)\s*([\d,]+\.?\d*)\b', caseSensitive: false);
  static final _debitRegex = RegExp(r'\b(debited|spent|paid|sent|withdrawn|charged)\b', caseSensitive: false);
  static final _creditRegex = RegExp(r'\b(credited|received|deposit|refund)\b', caseSensitive: false);
  static final _requestRegex = RegExp(r'\b(request|due|pending|approve|invoice)\b', caseSensitive: false);

  // CORRECTED & IMPROVED: More robust regex for merchant detection.
  static final _merchantRegex = [
    RegExp(r"(?:to|from|by)\s+([\w\s.&\-',]+?)(?:\s+on|\s+for|\s+@|\s+with|\s+is|'s|\.)", caseSensitive: false),
    RegExp(r"at\s+([\w\s.&\-',]+?)(?:\.)", caseSensitive: false),
    RegExp(r'to\s+([\w\s]+)@', caseSensitive: false),
    RegExp(r"\b(on|via)\s+([\w\s.&\-',]+?)(?:\sfor|\son|\.)", caseSensitive: false),
  ];

  static DetectedSmsTransaction? parse(String smsId, String smsBody, String sender, DateTime date) {
    final amount = _extractAmount(smsBody);
    if (amount == null) {
      return null;
    }

    final type = _determineType(smsBody);
    final merchant = _extractMerchant(smsBody, sender);
    final isDefinitive = _isDefinitive(smsBody);

    return DetectedSmsTransaction(
      smsId: smsId,
      amount: amount,
      type: type,
      date: date,
      merchant: merchant,
      isDefinitive: isDefinitive,
      smsBody: smsBody,
      sender: sender,
    );
  }

  static double? _extractAmount(String body) {
    final match = _amountRegex.firstMatch(body);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  static String _determineType(String body) {
    final lowerBody = body.toLowerCase();
    if (_creditRegex.hasMatch(lowerBody) && !_debitRegex.hasMatch(lowerBody)) return 'income';
    if (_debitRegex.hasMatch(lowerBody)) return 'expense';
    return 'expense';
  }

  static String _extractMerchant(String body, String sender) {
    for (final regex in _merchantRegex) {
      final match = regex.firstMatch(body);
      if (match != null && match.group(1) != null) {
        final merchantCandidate = match.group(1)!.trim();
        // Avoid matching generic words like "you"
        if (merchantCandidate.isNotEmpty && merchantCandidate.toLowerCase() != 'you') {
          return merchantCandidate;
        }
      }
    }
    // Fallback to the sender, which is much more useful than "Unknown".
    return sender;
  }

  static bool _isDefinitive(String body) {
    final lowerBody = body.toLowerCase();
    if (_requestRegex.hasMatch(lowerBody)) {
      return false;
    }
    return _debitRegex.hasMatch(lowerBody) || _creditRegex.hasMatch(lowerBody);
  }
}
