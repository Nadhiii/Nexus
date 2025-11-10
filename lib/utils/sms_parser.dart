import '../models/detected_transaction.dart';

class SmsParser {
  static final RegExp _amountRe = RegExp(
    r'(?:INR|Rs\.?|Rs|₹)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _debitHints = RegExp(
    r'(debited|spent|purchase|pos|upi|withdrawn|payment|paid)',
    caseSensitive: false,
  );

  static final RegExp _creditHints = RegExp(
    r'(credited|received|deposit|refund)',
    caseSensitive: false,
  );

  static DetectedTransaction? parse({
    required String body,
    String? address,
    DateTime? date,
    String idPrefix = 'sms',
  }) {
    final match = _amountRe.firstMatch(body);
    if (match == null) return null;

    final amountStr = match.group(1) ?? '';
    final normalized = amountStr.replaceAll(',', '');
    final amount = double.tryParse(normalized);
    if (amount == null) return null;

    final isCredit = _creditHints.hasMatch(body) && !_debitHints.hasMatch(body);
    final sign = isCredit ? 1.0 : -1.0;
    final when = date ?? DateTime.now();
    final src = address ?? 'SMS';

    final title = isCredit ? 'Money Received' : 'Payment Made';
    final preview = body.length > 60 ? '${body.substring(0, 60)}…' : body;
    
    // Auto-detect category from SMS body
    final category = _detectCategory(body);

    // Create unique ID based on SMS content hash to prevent duplicates
    final contentHash = body.hashCode.abs();
    final timeHash = when.millisecondsSinceEpoch;
    
    return DetectedTransaction(
      id: '$idPrefix-$timeHash-$contentHash',
      title: title,
      subtitle: preview,
      amount: amount * sign,
      date: when,
      source: src,
      smsBody: body,
      category: category,
    );
  }

  static String? _detectCategory(String body) {
    final lowerBody = body.toLowerCase();
    
    if (lowerBody.contains('atm') || lowerBody.contains('withdraw')) {
      return 'Cash Withdrawal';
    }
    if (lowerBody.contains('swiggy') || lowerBody.contains('zomato') || 
        lowerBody.contains('food') || lowerBody.contains('restaurant')) {
      return 'Food & Dining';
    }
    if (lowerBody.contains('uber') || lowerBody.contains('ola') || 
        lowerBody.contains('fuel') || lowerBody.contains('petrol')) {
      return 'Transportation';
    }
    if (lowerBody.contains('amazon') || lowerBody.contains('flipkart') || 
        lowerBody.contains('shopping') || lowerBody.contains('myntra')) {
      return 'Shopping';
    }
    if (lowerBody.contains('electricity') || lowerBody.contains('water') || 
        lowerBody.contains('bill') || lowerBody.contains('recharge')) {
      return 'Bills';
    }
    if (lowerBody.contains('salary') || lowerBody.contains('credited to your account')) {
      return 'Salary';
    }
    
    return null;
  }
}
