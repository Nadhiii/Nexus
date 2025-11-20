import '../models/detected_transaction.dart';

class NewSmsParser {
  static DetectedTransaction? parse(String id, String body, String sender, DateTime date) {
    return _parseSms(id, body, sender, date);
  }

  static DetectedTransaction? _parseSms(String id, String body, String sender, DateTime date) {
    final cleanBody = body.replaceAll(RegExp(r'[\n\r]'), ' ').trim();

    final patterns = [
      RegExp(r'^(?:Rs\.?|INR)\.?\s*([\d,]+(?:\.\d{1,2})?)\s*(?:sent|debited|spent)', caseSensitive: false),

      RegExp(r'Spent\s+(?:Rs\.?|INR)\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),

      RegExp(r'for\s+(?:Rs\.?|INR)\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),

      RegExp(r'debited\s+by\s+(?:Rs\.?|INR)\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),

      RegExp(r'(?:Rs\.?|INR)\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    double? amount;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanBody);
      if (match != null) {
        final amountString = match.group(1)?.replaceAll(',', '');
        amount = double.tryParse(amountString ?? '');
        if (amount != null && amount > 0) break;
      }
    }

    if (amount == null || amount == 0) return null;

    final type = _getTransactionType(cleanBody);

    final isFinancial = cleanBody.toLowerCase().contains(RegExp(r'(sent|paid|spent|debit|credit|purchase|txn|transfer|upi|a\/c|card|bank)'));
    if (!isFinancial) return null;

    final merchant = _getMerchant(sender, cleanBody);

    return DetectedTransaction(
      id: id,
      amount: amount,
      merchant: merchant,
      date: date,
      type: type,
      source: 'sms',
      body: cleanBody,
    );
  }

  static String _getTransactionType(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('credited') ||
        lowerBody.contains('deposit') ||
        lowerBody.contains('received') ||
        lowerBody.contains('refund') ||
        lowerBody.contains('added to')) {
      return 'income';
    }
    return 'expense';
  }

  static String _getMerchant(String sender, String body) {
    final cleanBody = body.replaceAll(RegExp(r'[\n\r]'), ' ');

    final idfcMatch = RegExp(r'Info:.*?\/.*?\/(.*?)(?:\.|$)', caseSensitive: false).firstMatch(cleanBody);
    if (idfcMatch != null) return idfcMatch.group(1)!.trim();

    final upiMatch = RegExp(r'to\s+([A-Za-z0-9\s\.]+?)\s?\.?Ref', caseSensitive: false).firstMatch(cleanBody);
    if (upiMatch != null) return upiMatch.group(1)!.trim();

    final atMatch = RegExp(r'done\s+at\s+(.*?)\s+on', caseSensitive: false).firstMatch(cleanBody);
    if (atMatch != null) return atMatch.group(1)!.trim();

    final generalMatch = RegExp(r'(?:at|to)\s+([A-Za-z0-9\s]+?)(?:\s+(?:on|for|via)|$)', caseSensitive: false).firstMatch(cleanBody);
    if (generalMatch != null) {
      final m = generalMatch.group(1)!.trim();
      if (m.length < 25 && !m.toLowerCase().contains('upi')) return m;
    }

    return sender.replaceAll(RegExp(r'^[A-Z]{2}-'), '').replaceAll(RegExp(r'[-_]'), ' ').trim();
  }
}