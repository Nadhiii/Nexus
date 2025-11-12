import 'package:intl/intl.dart';
import '../models/detected_transaction.dart';

class SmsParser {
  // CORRECTED: All regexes have been fixed with proper escaping.
  static final _amountRegex = RegExp(r'\b(?:inr|rs\.?|₹)\s*([\d,]+\.?\d*)\b', caseSensitive: false);
  static final _debitRegex = RegExp(r'\b(debited|spent|paid|payment|charged|sent|withdrawn)\b', caseSensitive: false);
  static final _creditRegex = RegExp(r'\b(credited|received|deposit|refund)\b', caseSensitive: false);
  static final _definitiveRegex = RegExp(r'\b(sent|debited|credited|confirmed|paid|spent|successful|txnid|trxn|ref)\b', caseSensitive: false);
  static final _requestRegex = RegExp(r'\b(request|requested|approve|approves|pending|waiting|due|bill|invoice)\b', caseSensitive: false);
  static final _accountRegex = RegExp(r'(?:a/c|acct|account)\s\S*(\d{4,})', caseSensitive: false);

  static DetectedTransaction? parse(String body, String? sender, DateTime date) {
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount == 0) return null;

    final type = _determineTransactionType(body);
    final isDefinitive = _definitiveRegex.hasMatch(body) && !_requestRegex.hasMatch(body);

    return DetectedTransaction(
      id: 'sms_${date.millisecondsSinceEpoch}_${body.hashCode}',
      amount: amount,
      title: _extractTitle(body) ?? (type == 'income' ? 'Income' : 'Expense'),
      subtitle: sender ?? 'Unknown Sender',
      date: date,
      type: type,
      category: _autoCategorize(body),
      smsBody: body,
      source: sender ?? 'SMS',
      isDefinitive: isDefinitive,
    );
  }

  static String _determineTransactionType(String body) {
    final lowerBody = body.toLowerCase();
    if (_creditRegex.hasMatch(lowerBody) && !_debitRegex.hasMatch(lowerBody)) return 'income';
    if (_debitRegex.hasMatch(lowerBody) && !_creditRegex.hasMatch(lowerBody)) return 'expense';
    if (lowerBody.contains('request for') || lowerBody.contains('bill generated')) return 'expense';
    return 'expense';
  }

  static String? _extractTitle(String body) {
    final lowerBody = body.toLowerCase();
    // CORRECTED: Regex patterns are now correctly escaped.
    final patterns = {
      'UPI': RegExp(r'to\s([\w\s]+)@', caseSensitive: false),
      'Card': RegExp(r'at\s([\w\s]+)\.', caseSensitive: false),
      'Purchase': RegExp(r'purchase\sof.+at\s(.+?)\.', caseSensitive: false),
      'Paid To': RegExp(r'paid to\s([\w\s]+?)(?:\b|\son|\sfor)', caseSensitive: false),
      'Received From': RegExp(r'received from\s([\w\s]+?)(?:\b|\son|\sfor)', caseSensitive: false),
    };

    for (var entry in patterns.entries) {
      final match = entry.value.firstMatch(lowerBody);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  static String _autoCategorize(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('salary')) return 'Salary';
    if (lowerBody.contains('rent')) return 'Rent';
    if (lowerBody.contains('zomato') || lowerBody.contains('swiggy') || lowerBody.contains('food') || lowerBody.contains('restaurant')) return 'Food & Dining';
    if (lowerBody.contains('ola') || lowerBody.contains('uber') || lowerBody.contains('fuel') || lowerBody.contains('petrol') || lowerBody.contains('travel')) return 'Transportation';
    if (lowerBody.contains('amazon') || lowerBody.contains('flipkart') || lowerBody.contains('shopping') || lowerBody.contains('myntra') || lowerBody.contains('store')) return 'Shopping';
    if (lowerBody.contains('electricity') || lowerBody.contains('water') || lowerBody.contains('bill') || lowerBody.contains('recharge') || lowerBody.contains('utility')) return 'Bills & Utilities';
    if (lowerBody.contains('emi') || lowerBody.contains('loan')) return 'Loan Payment';
    if (lowerBody.contains('withdrawal') || lowerBody.contains('atm')) return 'Cash Withdrawal';
    if (lowerBody.contains('invest') || lowerBody.contains('sip') || lowerBody.contains('mutual fund')) return 'Investments';
    if (lowerBody.contains('insurance')) return 'Insurance';
    if (lowerBody.contains('health') || lowerBody.contains('hospital') || lowerBody.contains('pharmacy')) return 'Healthcare';
    if (lowerBody.contains('education') || lowerBody.contains('school') || lowerBody.contains('college')) return 'Education';
    if (lowerBody.contains('transfer')) return 'Transfer';
    
    return 'Other Expense';
  }
}
