import 'package:flutter/foundation.dart';

enum ParsedTransactionType { expense, income, unknown }

@immutable
class ParsedIndianTransaction {
  final double amount;
  final ParsedTransactionType type;
  final String? merchantOrPayee;
  final String? accountMask;
  final String? referenceId;
  final String rawMessage;

  const ParsedIndianTransaction({
    required this.amount,
    required this.type,
    required this.rawMessage,
    this.merchantOrPayee,
    this.accountMask,
    this.referenceId,
  });
}

class IndianTransactionParser {
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _debitRegex = RegExp(
    r'\b(debited|spent|paid|purchase|withdrawn)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRegex = RegExp(
    r'\b(credited|received|deposited|refund)\b',
    caseSensitive: false,
  );

  static final RegExp _merchantRegex = RegExp(
    r'\b(?:to|at|for|via)\s+([A-Za-z0-9\.\-&\s]{2,48}?)(?:\s+(?:on|ref|utr|txn)|[.,]|$)',
    caseSensitive: false,
  );

  static final RegExp _accountRegex = RegExp(
    r'(?:a\/c|ac|account)\s*(?:no\.?|ending|xx+)?\s*[:\-]?\s*([Xx\*]*\d{3,6})',
    caseSensitive: false,
  );

  static final RegExp _referenceRegex = RegExp(
    r'\b(?:ref(?:erence)?|utr|txn(?:\s*id)?)\s*[:\-]?\s*([A-Za-z0-9\-]{6,30})\b',
    caseSensitive: false,
  );

  static ParsedIndianTransaction? parse(String message) {
    final normalized = message.replaceAll(RegExp(r'[\n\r]'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    final amountMatch = _amountRegex.firstMatch(normalized);
    if (amountMatch == null) {
      return null;
    }

    final rawAmount = amountMatch.group(1)?.replaceAll(',', '');
    final amount = rawAmount == null ? null : double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      return null;
    }

    final type = _resolveType(normalized);
    final merchantMatch = _merchantRegex.firstMatch(normalized);
    final accountMatch = _accountRegex.firstMatch(normalized);
    final referenceMatch = _referenceRegex.firstMatch(normalized);

    return ParsedIndianTransaction(
      amount: amount,
      type: type,
      rawMessage: message,
      merchantOrPayee: _cleanToken(merchantMatch?.group(1)),
      accountMask: _cleanToken(accountMatch?.group(1)),
      referenceId: _cleanToken(referenceMatch?.group(1)),
    );
  }

  static ParsedTransactionType _resolveType(String text) {
    final hasDebit = _debitRegex.hasMatch(text);
    final hasCredit = _creditRegex.hasMatch(text);
    if (hasDebit && !hasCredit) {
      return ParsedTransactionType.expense;
    }
    if (hasCredit && !hasDebit) {
      return ParsedTransactionType.income;
    }
    return ParsedTransactionType.unknown;
  }

  static String? _cleanToken(String? token) {
    final value = token?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.replaceAll(RegExp(r'\s+'), ' ');
  }
}
