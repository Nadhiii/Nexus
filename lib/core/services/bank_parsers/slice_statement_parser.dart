import '../../models/detected_transaction.dart';
import 'bank_statement_parser.dart';

class SliceStatementParser extends BankStatementParser {
  @override
  String get bankLabel => 'Slice';

  @override
  bool canParse(String rawText) {
    return rawText.toUpperCase().contains('NESF');
  }

  static final _dateStart = RegExp(r"\d{2} \w{3} '\d{2}");

  static final _rowPattern = RegExp(
    r"(\d{2} \w{3} '\d{2})\s+(.+?)\s+(\d{10,})\s+-?₹?([\d,]+\.?\d*)\s+₹?([\d,]+\.?\d*)",
  );

  static final _junkLine = RegExp(
    r'Need help\?|grievance|customergrievance|'
    r'^\d{1,2}\s*/\s*\d{1,2}$|'
    r"^\d{1,2}\s*Aug\s*'\d{2}\s*-\s*\d{1,2}\s*Aug\s*'\d{2}$|"
    r'^DATE\s+DETAILS|^slice$',
    caseSensitive: false,
  );

  @override
  List<DetectedTransaction> parse(String rawText, String sourceFileName) {
    final results = <DetectedTransaction>[];

    final atomIndex = rawText.indexOf('Daily saver atom');
    final mainSection = atomIndex == -1
        ? rawText
        : rawText.substring(0, atomIndex);

    final cleaned = mainSection
        .split('\n')
        .where((l) => !_junkLine.hasMatch(l.trim()))
        .join('\n');

    final dateMatches = _dateStart.allMatches(cleaned).toList();

    for (int i = 0; i < dateMatches.length; i++) {
      final start = dateMatches[i].start;
      final end = i + 1 < dateMatches.length
          ? dateMatches[i + 1].start
          : cleaned.length;
      final block = cleaned.substring(start, end).replaceAll('\n', ' ').trim();

      if (block.startsWith('Interest Cr.')) continue;

      final match = _rowPattern.firstMatch(block);
      if (match == null) continue;

      final dateStr = match.group(1)!;
      final desc = match.group(2)!.trim();
      final amount = parseAmount(match.group(4)!);
      final balance = parseAmount(match.group(5)!);
      final isDebit = block.contains('-₹') || desc.contains('Debit');

      if (amount == 0.0) continue;

      final date = _parseDate(dateStr);

      results.add(
        DetectedTransaction(
          id: '${sourceFileName}_${date.millisecondsSinceEpoch}_${results.length}',
          fingerprint: makeFingerprint(date, amount, desc),
          amount: amount,
          merchant: _extractMerchant(desc),
          date: date,
          type: isDebit ? 'expense' : 'income',
          source: 'pdf',
          body: desc,
          confidence: 0.8,
          bankName: 'Slice',
          balanceAfter: balance,
        ),
      );
    }

    return results;
  }

  DateTime _parseDate(String ddMonYy) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final cleanedStr = ddMonYy.replaceAll("'", '');
    final parts = cleanedStr.split(' ');
    final day = int.parse(parts[0]);
    final month = months[parts[1]] ?? 1;
    final year = 2000 + int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String _extractMerchant(String desc) {
    final parts = desc.split('-');
    if (parts.length >= 4) return parts[3].trim();
    return desc;
  }
}
