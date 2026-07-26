import '../../models/detected_transaction.dart';
import 'bank_statement_parser.dart';

class SliceStatementParser extends BankStatementParser {
  @override
  String get bankLabel => 'Slice';

  @override
  bool canParse(String rawText) {
    // NOTE: Syncfusion's PdfTextExtractor drops/garbles characters on this
    // statement's font (subsetted font, incomplete ToUnicode CMap) — words
    // like "MAHANADI" come out as "HNDI" and "slice" itself doesn't survive
    // intact. Don't rely on brand text. NESF is Slice Small Finance Bank's
    // IFSC prefix, is not used by SBI or IDFC First, and has survived
    // extraction reliably in testing, so it's used as the sole signal.
    return rawText.toUpperCase().contains('NESF');
  }

  // e.g. 02 Jun '26 UPI-Credit-651956158088-Mahanadi P J-... 20260602383408901 ₹170 ₹202.64
  static final _rowPattern = RegExp(
    r"(\d{2} \w{3} '\d{2})\s+(.+?)\s+(\d{10,})\s+-?₹?([\d,]+\.?\d*)\s+₹?([\d,]+\.?\d*)",
  );

  @override
  List<DetectedTransaction> parse(String rawText, String sourceFileName) {
    final results = <DetectedTransaction>[];

    // Only parse the main "Savings account" ledger — stop before the
    // "Daily saver atom" / "Round ups atom" sub-ledgers, which are
    // internal transfers, not real income/expense.
    final atomIndex = rawText.indexOf('Daily saver atom');
    final mainSection =
        atomIndex == -1 ? rawText : rawText.substring(0, atomIndex);

    for (final line in mainSection.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('Interest Cr.')) continue; // skip daily interest noise

      final match = _rowPattern.firstMatch(trimmed);
      if (match == null) continue;

      final dateStr = match.group(1)!; // "02 Jun '26"
      final desc = match.group(2)!.trim();
      final amount = parseAmount(match.group(4)!);
      final balance = parseAmount(match.group(5)!);
      final isDebit = trimmed.contains('-₹') || desc.contains('Debit');

      if (amount == 0.0) continue;

      final date = _parseDate(dateStr);

      results.add(DetectedTransaction(
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
      ));
    }

    return results;
  }

  DateTime _parseDate(String ddMonYy) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final cleaned = ddMonYy.replaceAll("'", '');
    final parts = cleaned.split(' ');
    final day = int.parse(parts[0]);
    final month = months[parts[1]] ?? 1;
    final year = 2000 + int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String _extractMerchant(String desc) {
    // e.g. "UPI-Debit-615386000500-Swiggy Limited-UTIB-..." -> "Swiggy Limited"
    final parts = desc.split('-');
    if (parts.length >= 4) return parts[3].trim();
    return desc;
  }
}