import '../../models/detected_transaction.dart';
import 'bank_statement_parser.dart';

/// IDFC First Bank issues (at least) two structurally different PDF layouts
/// that both self-identify as "IDFC FIRST":
///
///  - "CONSOLIDATED STATEMENT"  -> dates include a time,
///        e.g. "01 Jun 26 13:40"   and balances end with "CR"/"DR",
///        e.g. "1,000.00 1,220.12 CR"
///
///  - "STATEMENT OF ACCOUNT"    -> dates have no time and use a 4-digit
///        year with dashes, e.g. "01-Jun-2026", and balances have NO
///        CR/DR suffix at all, e.g. "1,000.00 1,220.12"
///
/// Previously only the first layout was handled: the entry-boundary regex
/// only matched the "with time" date format, so on a "STATEMENT OF ACCOUNT"
/// PDF it matched nothing at all and parse() silently returned an empty
/// list (no thrown error, so the failure was invisible).
class IdfcStatementParser extends BankStatementParser {
  @override
  String get bankLabel => 'IDFC First Bank';

  @override
  bool canParse(String rawText) => rawText.contains('IDFC FIRST');

  // Format A ("Consolidated Statement"): date+time header, e.g. "01 Jun 26 13:40"
  static final _entryStartA = RegExp(r'\d{2} \w{3} \d{2} \d{2}:\d{2}');

  // Format B ("Statement of Account"): dash date, 4-digit year, no time,
  // e.g. "01-Jun-2026". IMPORTANT: Transaction Date and Value Date columns
  // use the IDENTICAL format, so a regex matching a single date matches
  // TWICE per row (once per column) and corrupts block-splitting. This
  // regex requires the pair together, anchored to line start, to get
  // exactly one match per transaction row.
  static final _entryStartB = RegExp(
    r'^(\d{2}-\w{3}-\d{4})\s+(\d{2}-\w{3}-\d{4})\s*(.*)$',
    multiLine: true,
  );

  // Lines that start a new transaction's description in Format B. The PDF
  // extractor wraps description text across 3+ lines with the date/amount
  // row in the middle, so we need to know where one description ends and
  // the next begins.
  static final _txnStartKeyword = RegExp(
    r'^(UPI|NEFT|IMPS|RTGS|MONTHLY|ATM|CHEQUE|CASH|POS|SI|CHG|NACH|ECS)\b',
    caseSensitive: false,
  );

  // Footer/header noise that repeats on every page and can bleed into the
  // gap between two transactions (page breaks). Filtered out before
  // reconstructing descriptions.
  static final _junkLineB = RegExp(
    r'REGISTERED OFFICE|^Page \d+ of \d+|STATEMENT OF ACCOUNT|CUSTOMER ID|'
    r'ACCOUNT NO|STATEMENT PERIOD|^Transaction$|Value Date|Particulars|'
    r'ChequeNo|^Cheque$|^No\.?$|Opening Balance|'
    r'^[\d,]+\.\d{2}(\s+[\d,]+\.\d{2}){2,}$',
    caseSensitive: false,
  );

  // Format A trailing amount + balance + CR|DR marker, e.g.
  // "1,000.00 1,220.12 CR". NOT anchored with `$` — the block for the last
  // transaction on a page also picks up trailing page-footer/header text,
  // which never carries a CR/DR suffix, so it's safe (and necessary) to take
  // the LAST such match in the block.
  static final _amountTailA = RegExp(
    r'([\d,]+\.\d{2})?\s*([\d,]+\.\d{2})\s*(CR|DR)',
  );

  // Format B trailing amount + balance, e.g. "1,000.00 1,220.12" — no CR/DR
  // suffix exists in this layout at all, so we can't use that to distinguish
  // the real transaction data from page-footer/header noise (the repeated
  // "Opening Balance / Total Debit / Total Credit / Closing Balance" summary
  // block, which is also made of decimal numbers). Instead we take the
  // FIRST match in the block: the real amount/balance always sits
  // immediately after the description, while footer/header noise only ever
  // bleeds in AFTER that, from the following page.
  static final _amountTailB = RegExp(
    r'([\d,]+\.\d{2})?\s*([\d,]+\.\d{2})',
  );

  static final _descA = RegExp(
    r'\d{2} \w{3} \d{2} \d{2}:\d{2}\s+\d{2} \w{3} \d{2}\s+(.+?)\s+[\d,]',
  );
  static final _descB = RegExp(
    r'\d{2}-\w{3}-\d{4}\s+\d{2}-\w{3}-\d{4}\s+(.+?)\s+[\d,]',
  );

  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  @override
  List<DetectedTransaction> parse(String rawText, String sourceFileName) {
    final bool isFormatA = _entryStartA.hasMatch(rawText);
    final entryStart = isFormatA ? _entryStartA : _entryStartB;

    final results = <DetectedTransaction>[];

    // Split the text into per-transaction blocks using the date header as
    // the boundary. This handles descriptions that wrap across lines.
    final matches = entryStart.allMatches(rawText).toList();

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end =
          i + 1 < matches.length ? matches[i + 1].start : rawText.length;
      final rawBlock =
          rawText.substring(start, end).replaceAll('\n', ' ').trim();

      String block;
      String? singleAmount;
      String balanceStr;

      if (isFormatA) {
        final tailMatches = _amountTailA.allMatches(rawBlock).toList();
        if (tailMatches.isEmpty) continue;
        final tailMatch = tailMatches.last;
        block = rawBlock.substring(0, tailMatch.end);
        singleAmount = tailMatch.group(1);
        balanceStr = tailMatch.group(2)!;
      } else {
        final tailMatches = _amountTailB.allMatches(rawBlock).toList();
        if (tailMatches.isEmpty) continue;
        final tailMatch = tailMatches.first;
        block = rawBlock.substring(0, tailMatch.end);
        singleAmount = tailMatch.group(1);
        balanceStr = tailMatch.group(2)!;
      }

      final dateMatch = entryStart.firstMatch(block);
      if (dateMatch == null) continue;
      final date = isFormatA
          ? _parseDateA(dateMatch.group(0)!)
          : _parseDateB(dateMatch.group(0)!);

      final balance = parseAmount(balanceStr);

      // If only one number before the balance, it's the transaction amount.
      // IDFC's table has separate Withdrawal/Deposit columns, but since
      // it's a single amount per row we treat the lone captured number as
      // the transaction amount.
      final amount = singleAmount != null ? parseAmount(singleAmount) : 0.0;
      if (amount == 0.0) continue;

      // Description is everything between the two dates and the amount tail.
      final descMatch = (isFormatA ? _descA : _descB).firstMatch(block);
      final desc = descMatch?.group(1)?.trim() ?? block;

      final isCredit = desc.contains('/CR/') ||
          block.toLowerCase().contains('credit') ||
          desc.toUpperCase().contains('NEFT/CHASH');
      // IDFC withdrawal rows have "/DR/" markers; use that as primary signal.
      final isDebit = desc.contains('/DR/');

      results.add(DetectedTransaction(
        id: '${sourceFileName}_${date.millisecondsSinceEpoch}_${results.length}',
        fingerprint: makeFingerprint(date, amount, desc),
        amount: amount,
        merchant: _extractMerchant(desc),
        date: date,
        type: isDebit ? 'expense' : 'income',
        source: 'pdf',
        body: desc,
        confidence: 0.7, // lower — line-wrap parsing is less reliable
        bankName: 'IDFC First Bank',
        balanceAfter: balance,
        warnings: isCredit == isDebit ? ['Could not confirm credit/debit'] : [],
      ));
    }

    return results;
  }

  // "01 Jun 26" -> 2-digit year
  DateTime _parseDateA(String ddMonYy) {
    final parts = ddMonYy.split(' ');
    final day = int.parse(parts[0]);
    final month = _months[parts[1]] ?? 1;
    final year = 2000 + int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  // "01-Jun-2026" -> 4-digit year
  DateTime _parseDateB(String ddMonYyyy) {
    final parts = ddMonYyyy.split('-');
    final day = int.parse(parts[0]);
    final month = _months[parts[1]] ?? 1;
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String _extractMerchant(String desc) {
    final parts = desc.split('/');
    if (parts.length >= 4) return parts[3].trim();
    return desc;
  }
}