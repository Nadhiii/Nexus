import '../../models/detected_transaction.dart';
import 'bank_statement_parser.dart';

class SbiStatementParseResult {
  final List<DetectedTransaction> transactions;
  final double? openingBalance;
  final double? closingBalance;

  SbiStatementParseResult({
    required this.transactions,
    this.openingBalance,
    this.closingBalance,
  });
}

class SbiStatementParser extends BankStatementParser {
  @override
  String get bankLabel => 'State Bank of India';

  @override
  bool canParse(String rawText) {
    return rawText.contains('SBI') &&
        (rawText.contains('TRANSACTION DETAILS') ||
            rawText.contains('Relationship Summary'));
  }

  static final _dateOnlyPattern = RegExp(r'^\d{2}-\d{2}-\d{2}$');

  SbiStatementParseResult parseStatement(String rawText, String sourceFileName) {
    final results = <DetectedTransaction>[];

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Opening/closing balance sit on the line AFTER the label line, e.g.:
    //   "Your Opening Balance on 01-06-26:"
    //   "22.49"
    // Reading the number off the label line itself is wrong, since the
    // label line contains the statement date (01-06-26), which the old
    // regex was accidentally matching instead of the real balance.
    double? openingBalance;
    double? closingBalance;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (openingBalance == null &&
          line.contains('opening balance') &&
          i + 1 < lines.length &&
          _looksNumeric(lines[i + 1])) {
        openingBalance = parseAmount(lines[i + 1]);
      }
      if (closingBalance == null &&
          line.contains('closing balance') &&
          i + 1 < lines.length &&
          _looksNumeric(lines[i + 1])) {
        closingBalance = parseAmount(lines[i + 1]);
      }
    }

    for (int i = 0; i < lines.length; i++) {
      if (!_dateOnlyPattern.hasMatch(lines[i])) continue;
      if (i + 5 >= lines.length) continue;

      final dateStr = lines[i];
      final desc = lines[i + 1];
      final creditStr = lines[i + 3];
      final debitStr = lines[i + 4];
      final balanceStr = lines[i + 5];

      if (!_looksNumeric(creditStr) ||
          !_looksNumeric(debitStr) ||
          !_looksNumeric(balanceStr)) {
        continue;
      }

      final credit = parseAmount(creditStr);
      final debit = parseAmount(debitStr);
      if (credit == 0 && debit == 0) {
        i += 5;
        continue;
      }

      final date = _parseDate(dateStr);
      final isCredit = credit > 0;
      final amount = isCredit ? credit : debit;
      final balance = parseAmount(balanceStr);

      results.add(DetectedTransaction(
        id: '${sourceFileName}_${date.millisecondsSinceEpoch}_${results.length}',
        fingerprint: makeFingerprint(date, amount, desc),
        amount: amount,
        merchant: _extractMerchant(desc),
        date: date,
        type: isCredit ? 'income' : 'expense',
        source: 'pdf',
        body: desc,
        confidence: 0.80,
        bankName: 'SBI',
        balanceAfter: balance,
      ));

      i += 5;
    }

    return SbiStatementParseResult(
      transactions: results,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
    );
  }

  @override
  List<DetectedTransaction> parse(String rawText, String sourceFileName) {
    return parseStatement(rawText, sourceFileName).transactions;
  }

  bool _looksNumeric(String s) => RegExp(r'^[\d,]+\.?\d*$').hasMatch(s);

  DateTime _parseDate(String ddmmyy) {
    final parts = ddmmyy.split('-');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = 2000 + int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String _extractMerchant(String desc) {
    final parts = desc.split('/');
    if (parts.length >= 4) return parts[3].trim();
    return desc;
  }
}