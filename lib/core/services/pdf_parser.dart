import 'dart:developer' as dev;
import '../models/pdf_statement.dart';

class GenericPDFParser {
  // Enable debug logging
  static final bool _debug = true;
  static void _log(String message) {
    if (_debug) dev.log('[PDFParser] $message');
  }

  // --- 1. DETECT BANK ---
  static String? detectBank(String pdfText) {
    final text = pdfText.toUpperCase();

    // 1. SBI (Check First to avoid Federal false positives)
    if (text.contains('SBIN') ||
        text.contains('STATE BANK OF INDIA') ||
        text.contains('SBI ') ||
        text.contains('STATE BANK')) {
      _log('Detected Bank: SBI');
      return 'SBI';
    }

    // 2. FEDERAL BANK
    if (text.contains('FDRL') ||
        text.contains('FEDERAL BANK') ||
        text.contains('FI MONEY')) {
      _log('Detected Bank: FEDERAL');
      return 'FEDERAL';
    }

    // 3. IDFC FIRST BANK
    if (text.contains('IDFC FIRST') ||
        text.contains('IDFB') ||
        text.contains('ALWAYS YOU FIRST')) {
      _log('Detected Bank: IDFC');
      return 'IDFC';
    }

    // Fallbacks
    if (text.contains('HDFC')) return 'HDFC';
    if (text.contains('ICIC')) return 'ICICI';
    if (text.contains('UTIB') || text.contains('AXIS BANK')) return 'AXIS';

    _log('Could not detect bank');
    return null;
  }

  // --- 2. EXTRACT METADATA ---
  static PDFStatementMetadata extractMetadata(
    String pdfText,
    String? detectedBank,
  ) {
    final accountRegex = RegExp(
      r'(?:Account\s*N[o0][\.:\s]*|A/C\s*N[o0]\.?\s*|ACCOUNT\s*NO\.?\s*:?\s*|No\s*:)\s*["\s]*(\d{10,18})',
      caseSensitive: false,
    );
    final accountMatch = accountRegex.firstMatch(pdfText);
    _log('Account Number: ${accountMatch?.group(1)}');

    final periodRegex = RegExp(
      r'(\d{1,2}[\s-][A-Za-z0-9]+[\s-]\d{4})\s*(?:TO|-|–|to)\s*(\d{1,2}[\s-][A-Za-z0-9]+[\s-]\d{4})',
      caseSensitive: false,
    );
    final periodMatch = periodRegex.firstMatch(pdfText);

    DateTime? start, end;
    if (periodMatch != null) {
      start = _parseDate(periodMatch.group(1)!);
      end = _parseDate(periodMatch.group(2)!);
      _log('Period: $start to $end');
    }

    return PDFStatementMetadata(
      bankName: detectedBank ?? 'Unknown Bank',
      accountNumber: accountMatch?.group(1),
      accountHolder: 'Account Holder',
      accountType: 'Savings',
      statementPeriodStart: start,
      statementPeriodEnd: end,
    );
  }

  // --- 3. ROUTER ---
  static List<ExtractedTransaction> extractTransactions(String pdfText) {
    final bank = detectBank(pdfText);

    // Normalize newlines and clean text
    final cleanText = pdfText
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\r'), '\n');

    _log('=== RAW TEXT PREVIEW (first 2000 chars) ===');
    _log(
      cleanText.substring(0, cleanText.length > 2000 ? 2000 : cleanText.length),
    );
    _log('===========================================');

    List<ExtractedTransaction> transactions = [];

    if (bank == 'FEDERAL') {
      transactions = _extractFederalTransactions(cleanText);
    } else if (bank == 'IDFC') {
      transactions = _extractIDFCTransactions(cleanText);
    } else if (bank == 'SBI') {
      transactions = _extractSBITransactions(cleanText);
    }

    _log('Total transactions extracted: ${transactions.length}');
    return transactions;
  }

  // ==============================================================================
  // FEDERAL BANK PARSER
  // From screenshot - table format with:
  // Date (grouped) | Transaction Details | Amount | Balance
  // Example: "01 Oct" then "UPI/OUT/527489346913/bajajpay.6879729.soz7097/5812" "40.00" "221.28"
  // UPI IN = credit, UPI/OUT = debit
  // Amount has ⊕ (credit) or ⊖ (debit) indicator in PDF
  // ==============================================================================
  static List<ExtractedTransaction> _extractFederalTransactions(
    String pdfText,
  ) {
    final transactions = <ExtractedTransaction>[];
    final lines = pdfText.split('\n');

    DateTime? currentDate;
    int currentYear = DateTime.now().year;

    // Extract year from header "1 October 2025 to 31 December 2025"
    final yearMatch = RegExp(
      r'(\d{1,2}\s+[A-Za-z]+\s+(\d{4}))\s+to',
      caseSensitive: false,
    ).firstMatch(pdfText);
    if (yearMatch != null) {
      currentYear = int.parse(yearMatch.group(2)!);
      _log('Federal Bank: Extracted year $currentYear');
    }

    // Pattern for amount with optional balance: "40.00" "221.28" or "40.00 ⊖" "221.28"
    final amountPattern = RegExp(r'([\d,]+\.\d{2})\s*[⊕⊖]?\s*([\d,]+\.\d{2})?');

    // Date pattern for Federal: "01 Oct", "02 Oct" etc
    final datePattern = RegExp(
      r'^(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if line is a date header
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final monthStr = dateMatch.group(2)!.toLowerCase();
        final month = _monthToInt(monthStr);
        if (month != null) {
          currentDate = DateTime(currentYear, month, day);
          _log('Federal: New date section: $currentDate');
        }
        continue;
      }

      // Look for UPI transactions
      if (line.toUpperCase().contains('UPI')) {
        String type = 'expense';
        String description = line;
        double? amount;

        // Determine type from transaction code
        final lineUpper = line.toUpperCase();
        if (lineUpper.contains('UPI IN') || lineUpper.contains('UPI/IN')) {
          type = 'income';
        } else if (lineUpper.contains('UPIOUT') ||
            lineUpper.contains('UPI/OUT') ||
            lineUpper.contains('UPI OUT')) {
          type = 'expense';
        }

        // Extract merchant/description
        // Federal format: "UPI/OUT/527489346913/bajajpay.6879729.soz7097/5812"
        // Or: "UPI IN/527547992375/parisaramahanadhi-4@okax/0000"
        final parts = line.split('/');
        if (parts.length >= 3) {
          // Find the merchant name (usually after ref number)
          for (int p = 2; p < parts.length; p++) {
            final part = parts[p].trim();
            // Skip if it's just numbers
            if (!RegExp(r'^\d+$').hasMatch(part) && part.length > 2) {
              description = _cleanMerchantName(part);
              break;
            }
          }
        }

        // Look for amount on this line or next lines
        final amountMatch = amountPattern.firstMatch(line);
        if (amountMatch != null) {
          amount = _parseDouble(amountMatch.group(1)!);
        } else {
          // Check next few lines for amounts
          for (int j = i + 1; j < lines.length && j < i + 3; j++) {
            final nextAmountMatch = amountPattern.firstMatch(lines[j]);
            if (nextAmountMatch != null) {
              amount = _parseDouble(nextAmountMatch.group(1)!);
              break;
            }
          }
        }

        // If still no amount, try to find standalone numbers
        if (amount == null) {
          final standaloneAmount = RegExp(
            r'\b([\d,]+\.\d{2})\b',
          ).firstMatch(line);
          if (standaloneAmount != null) {
            amount = _parseDouble(standaloneAmount.group(1)!);
          }
        }

        if (amount != null && amount > 0 && currentDate != null) {
          _log('Federal TX: $description | $amount | $type | $currentDate');
          transactions.add(
            ExtractedTransaction(
              date: currentDate.toIso8601String().split('T')[0],
              description: description.isNotEmpty
                  ? description
                  : 'UPI Transaction',
              amount: amount,
              type: type,
              lineNumber: i,
            ),
          );
        }
      }
    }

    // If line-by-line didn't work well, try regex on full text
    if (transactions.isEmpty) {
      _log('Federal: Line-by-line failed, trying full-text regex');
      transactions.addAll(_extractFederalWithRegex(pdfText, currentYear));
    }

    return transactions;
  }

  /// Fallback Federal extraction using regex on full text
  static List<ExtractedTransaction> _extractFederalWithRegex(
    String pdfText,
    int year,
  ) {
    final transactions = <ExtractedTransaction>[];

    // Match pattern: date followed by UPI transaction
    // Looking for: "01 Oct" ... "UPI/OUT/..." ... "40.00" ... "221.28"
    final pattern = RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s\S]*?(UPI\s*(?:IN|OUT|\/OUT|\/IN)?[\/\s]*\d+[\/\s]*[^\n]+?)[\s\S]*?([\d,]+\.\d{2})',
      caseSensitive: false,
      multiLine: true,
    );

    for (final match in pattern.allMatches(pdfText)) {
      try {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!.toLowerCase();
        final month = _monthToInt(monthStr);
        final txnLine = match.group(3)!;
        final amount = _parseDouble(match.group(4)!);

        if (month == null || amount <= 0) continue;

        final date = DateTime(year, month, day);
        String type = txnLine.toUpperCase().contains('UPI IN')
            ? 'income'
            : 'expense';

        // Extract merchant
        String merchant = 'UPI Transaction';
        final parts = txnLine.split('/');
        for (int p = 2; p < parts.length; p++) {
          final part = parts[p].trim();
          if (!RegExp(r'^\d+$').hasMatch(part) && part.length > 2) {
            merchant = _cleanMerchantName(part);
            break;
          }
        }

        _log('Federal Regex TX: $merchant | $amount | $type | $date');
        transactions.add(
          ExtractedTransaction(
            date: date.toIso8601String().split('T')[0],
            description: merchant,
            amount: amount,
            type: type,
            lineNumber: 0,
          ),
        );
      } catch (e) {
        _log('Federal regex match failed: $e');
      }
    }

    return transactions;
  }

  // ==============================================================================
  // IDFC FIRST BANK PARSER
  // From screenshot - table format with:
  // Transaction Date | Value Date | Particulars | Cheque No | Debit | Credit | Balance
  // Example: "01-Oct-2025" "01-Oct-2025" "UPI/DR/626637396979/9MTC BUS/CNB9/na01/1a1/Pay to" "" "50.00" "" "1.22"
  // UPI/DR = debit, UPI/CR = credit, NEFT/CR = credit
  // ==============================================================================
  static List<ExtractedTransaction> _extractIDFCTransactions(String pdfText) {
    final transactions = <ExtractedTransaction>[];
    final lines = pdfText.split('\n');

    _log('IDFC: Processing ${lines.length} lines');

    // Pattern to find IDFC transactions in text
    // Looking for date followed by transaction type and amounts
    final datePattern = RegExp(
      r'(\d{1,2}[-/][A-Za-z]{3}[-/]\d{4})',
      caseSensitive: false,
    );
    final amountPattern = RegExp(r'([\d,]+\.\d{2})');

    // Track current transaction being built
    DateTime? currentDate;
    String currentDesc = '';
    List<double> currentAmounts = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip header lines
      if (line.toLowerCase().contains('opening balance') ||
          line.toLowerCase().contains('transaction date') ||
          line.toLowerCase().contains('particulars')) {
        continue;
      }

      // Check for date
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch != null) {
        // If we have a pending transaction, save it first
        if (currentDate != null &&
            currentDesc.isNotEmpty &&
            currentAmounts.isNotEmpty) {
          final txn = _buildIDFCTransaction(
            currentDate,
            currentDesc,
            currentAmounts,
          );
          if (txn != null) transactions.add(txn);
        }

        // Start new transaction
        currentDate = _parseDate(dateMatch.group(1)!);
        currentDesc = line.substring(dateMatch.end).trim();
        currentAmounts = amountPattern
            .allMatches(line)
            .map((m) => _parseDouble(m.group(1)!))
            .toList();
        continue;
      }

      // If we're building a transaction, accumulate description and amounts
      if (currentDate != null) {
        // Check if this line has UPI/transaction info
        if (line.toUpperCase().contains('UPI') ||
            line.toUpperCase().contains('NEFT') ||
            line.toUpperCase().contains('IMPS')) {
          currentDesc += ' $line';
        }

        // Collect any amounts on this line
        final amounts = amountPattern
            .allMatches(line)
            .map((m) => _parseDouble(m.group(1)!))
            .toList();
        currentAmounts.addAll(amounts);
      }
    }

    // Don't forget last transaction
    if (currentDate != null &&
        currentDesc.isNotEmpty &&
        currentAmounts.isNotEmpty) {
      final txn = _buildIDFCTransaction(
        currentDate,
        currentDesc,
        currentAmounts,
      );
      if (txn != null) transactions.add(txn);
    }

    // If line-by-line didn't work well, try full text approach
    if (transactions.isEmpty) {
      _log('IDFC: Line-by-line failed, trying full-text approach');
      transactions.addAll(_extractIDFCWithRegex(pdfText));
    }

    return transactions;
  }

  /// Build IDFC transaction from collected data
  static ExtractedTransaction? _buildIDFCTransaction(
    DateTime date,
    String desc,
    List<double> amounts,
  ) {
    if (amounts.isEmpty) return null;

    // Determine type from description
    final descUpper = desc.toUpperCase();
    String type = 'expense';
    if (descUpper.contains('UPI/CR') ||
        descUpper.contains('NEFT/CR') ||
        descUpper.contains('IMPS/CR') ||
        descUpper.contains('CREDIT')) {
      type = 'income';
    } else if (descUpper.contains('UPI/DR') ||
        descUpper.contains('NEFT/DR') ||
        descUpper.contains('DEBIT')) {
      type = 'expense';
    }

    // Get amount (first non-balance amount, typically)
    // In IDFC, format is: Debit | Credit | Balance
    // So if we have 2+ amounts, first could be the transaction amount
    double amount = amounts.first;

    // Extract merchant name
    String merchant = _extractMerchantFromIDFC(desc);

    _log('IDFC TX: $merchant | $amount | $type | $date');
    return ExtractedTransaction(
      date: date.toIso8601String().split('T')[0],
      description: merchant,
      amount: amount,
      type: type,
      lineNumber: 0,
    );
  }

  /// Extract merchant from IDFC description
  static String _extractMerchantFromIDFC(String desc) {
    // IDFC format: "UPI/DR/626637396979/9MTC BUS/CNB9/na01/1a1/Pay to"
    // Or: "NEFT/IDFB527449156718/MEENA R/MOHITH GUMMARAJ KISH/O"
    final parts = desc.split('/');
    if (parts.length >= 4) {
      // Try to find meaningful merchant name
      for (int i = 3; i < parts.length; i++) {
        final part = parts[i].trim();
        // Skip if just numbers or too short
        if (!RegExp(r'^\d+$').hasMatch(part) &&
            part.length > 2 &&
            !part.toUpperCase().startsWith('PAY TO') &&
            !RegExp(r'^[A-Z0-9]{4,}$').hasMatch(part)) {
          // Skip codes like CNB9
          return _cleanMerchantName(part);
        }
      }
    }
    return 'IDFC Transaction';
  }

  /// Fallback IDFC extraction using regex
  static List<ExtractedTransaction> _extractIDFCWithRegex(String pdfText) {
    final transactions = <ExtractedTransaction>[];

    // Pattern: date, transaction type, amounts
    final pattern = RegExp(
      r'(\d{1,2}[-/][A-Za-z]{3}[-/]\d{4})\s+\d{1,2}[-/][A-Za-z]{3}[-/]\d{4}\s+((?:UPI|NEFT|IMPS)[^\n]+?)\s+([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(pdfText)) {
      try {
        final dateStr = match.group(1)!;
        final desc = match.group(2)!;
        final amountStr = match.group(3)!;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final amount = _parseDouble(amountStr);
        if (amount <= 0) continue;

        String type = desc.toUpperCase().contains('/CR') ? 'income' : 'expense';
        String merchant = _extractMerchantFromIDFC(desc);

        _log('IDFC Regex TX: $merchant | $amount | $type | $date');
        transactions.add(
          ExtractedTransaction(
            date: date.toIso8601String().split('T')[0],
            description: merchant,
            amount: amount,
            type: type,
            lineNumber: 0,
          ),
        );
      } catch (e) {
        _log('IDFC regex match failed: $e');
      }
    }

    return transactions;
  }

  // ==============================================================================
  // SBI PARSER
  // From screenshot - table format with:
  // Value Date | Post Date | Details | Ref No/Cheque No | ₹ Debit | ₹ Credit | Balance
  // Example: "01/10/2025" "01/10/2025" "UPI/CR/554059003452/Mahanadi/IDFB/parisamana/UPI" "" "" "12,000.00" "14,152.31"
  // UPI/CR = credit, UPI/DR = debit, DEP TFR = credit, WDL TFR = debit
  // ==============================================================================
  static List<ExtractedTransaction> _extractSBITransactions(String pdfText) {
    final transactions = <ExtractedTransaction>[];
    final lines = pdfText.split('\n');

    _log('SBI: Processing ${lines.length} lines');

    // Pattern for SBI date: "01/10/2025" or "01-10-2025"
    final datePattern = RegExp(r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{4})');
    final amountPattern = RegExp(r'([\d,]+\.\d{2})');

    // Track multiline transactions
    DateTime? currentDate;
    String currentDesc = '';
    List<double> currentAmounts = [];
    String? currentType;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip headers
      if (line.toLowerCase().contains('value date') ||
          line.toLowerCase().contains('opening balance') ||
          line.toLowerCase().contains('₹ debit')) {
        continue;
      }

      // Check for date at start of line
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch != null && dateMatch.start < 3) {
        // Save pending transaction
        if (currentDate != null &&
            currentDesc.isNotEmpty &&
            currentAmounts.isNotEmpty) {
          final txn = _buildSBITransaction(
            currentDate,
            currentDesc,
            currentAmounts,
            currentType,
          );
          if (txn != null) transactions.add(txn);
        }

        // Start new transaction
        currentDate = _parseDate(dateMatch.group(1)!);
        currentDesc = line.substring(dateMatch.end).trim();
        currentAmounts = [];
        currentType = null;

        // Check transaction type from line
        final lineUpper = line.toUpperCase();
        if (lineUpper.contains('UPI/CR') ||
            lineUpper.contains('DEP TFR') ||
            lineUpper.contains('NEFT/CR')) {
          currentType = 'income';
        } else if (lineUpper.contains('UPI/DR') ||
            lineUpper.contains('WDL TFR') ||
            lineUpper.contains('NEFT/DR')) {
          currentType = 'expense';
        }

        // Collect amounts from this line
        currentAmounts = amountPattern
            .allMatches(line)
            .map((m) => _parseDouble(m.group(1)!))
            .toList();
        continue;
      }

      // Continue building current transaction
      if (currentDate != null) {
        // Add to description if it contains transaction info
        if (line.toUpperCase().contains('UPI') ||
            line.toUpperCase().contains('TFR') ||
            line.toUpperCase().contains('NEFT') ||
            line.toUpperCase().contains('IMPS') ||
            line.contains('@') ||
            line.contains('ROAD') || // Location info
            line.contains('PERIYAPATNA')) {
          currentDesc += ' $line';
        }

        // Determine type if not set
        if (currentType == null) {
          final lineUpper = line.toUpperCase();
          if (lineUpper.contains('UPI/CR') || lineUpper.contains('DEP TFR')) {
            currentType = 'income';
          } else if (lineUpper.contains('UPI/DR') ||
              lineUpper.contains('WDL TFR')) {
            currentType = 'expense';
          }
        }

        // Collect amounts
        final amounts = amountPattern
            .allMatches(line)
            .map((m) => _parseDouble(m.group(1)!))
            .toList();
        currentAmounts.addAll(amounts);
      }
    }

    // Save last transaction
    if (currentDate != null &&
        currentDesc.isNotEmpty &&
        currentAmounts.isNotEmpty) {
      final txn = _buildSBITransaction(
        currentDate,
        currentDesc,
        currentAmounts,
        currentType,
      );
      if (txn != null) transactions.add(txn);
    }

    // Fallback to full-text regex
    if (transactions.isEmpty) {
      _log('SBI: Line-by-line failed, trying full-text approach');
      transactions.addAll(_extractSBIWithRegex(pdfText));
    }

    return transactions;
  }

  /// Build SBI transaction from collected data
  static ExtractedTransaction? _buildSBITransaction(
    DateTime date,
    String desc,
    List<double> amounts,
    String? detectedType,
  ) {
    if (amounts.isEmpty) return null;

    // Determine type
    String type = detectedType ?? 'expense';
    if (detectedType == null) {
      final descUpper = desc.toUpperCase();
      if (descUpper.contains('UPI/CR') ||
          descUpper.contains('DEP TFR') ||
          descUpper.contains('CREDIT')) {
        type = 'income';
      }
    }

    // SBI format: Debit | Credit | Balance
    // If we have amounts, use first non-balance amount
    // Balance is typically the largest and last
    double amount = amounts.first;
    if (amounts.length >= 2) {
      // First amount is likely the transaction, last is balance
      amount = amounts.first;
    }

    // Extract merchant
    String merchant = _extractMerchantFromSBI(desc);

    _log('SBI TX: $merchant | $amount | $type | $date');
    return ExtractedTransaction(
      date: date.toIso8601String().split('T')[0],
      description: merchant,
      amount: amount,
      type: type,
      lineNumber: 0,
    );
  }

  /// Extract merchant from SBI description
  static String _extractMerchantFromSBI(String desc) {
    // SBI format: "UPI/CR/554059003452/Mahanadi/IDFB/parisamana/UPI"
    // Or: "UPI/DR/225506287952/HARISH JUTIBM862061OVNO R"
    // Or: "UPI/DR/923438016171/ZOMATO/HDFC/payzomat/o@/NO REM"
    final parts = desc.split('/');
    if (parts.length >= 4) {
      // Look for merchant name after reference number
      for (int i = 3; i < parts.length; i++) {
        final part = parts[i].trim();
        // Skip if just numbers, too short, or bank codes
        if (!RegExp(r'^\d+$').hasMatch(part) &&
            part.length > 2 &&
            !_isBankCode(part) &&
            !part.toUpperCase().contains('NO REM') &&
            !part.contains('@')) {
          return _cleanMerchantName(part);
        }
      }
    }

    // Try to find Swiggy, Zomato, etc. directly
    final descUpper = desc.toUpperCase();
    if (descUpper.contains('SWIGGY')) return 'Swiggy';
    if (descUpper.contains('ZOMATO')) return 'Zomato';
    if (descUpper.contains('AMAZON')) return 'Amazon';
    if (descUpper.contains('FLIPKART')) return 'Flipkart';
    if (descUpper.contains('PAYTM')) return 'Paytm';

    return 'SBI Transaction';
  }

  /// Check if string is a bank code (IDFB, HDFC, SBIN, etc.)
  static bool _isBankCode(String s) {
    final upper = s.toUpperCase().trim();
    return [
      'IDFB',
      'HDFC',
      'SBIN',
      'ICIC',
      'UTIB',
      'FDRL',
      'AXIS',
      'KOTAK',
      'YES',
      'IDBI',
    ].contains(upper);
  }

  /// Fallback SBI extraction using regex
  static List<ExtractedTransaction> _extractSBIWithRegex(String pdfText) {
    final transactions = <ExtractedTransaction>[];

    // Pattern: date followed by transaction type and amount
    final pattern = RegExp(
      r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{4})\s+\d{1,2}[/\-]\d{1,2}[/\-]\d{4}\s+((?:UPI|NEFT|IMPS|DEP|WDL)[^\n]+?)\s+([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(pdfText)) {
      try {
        final dateStr = match.group(1)!;
        final desc = match.group(2)!;
        final amountStr = match.group(3)!;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final amount = _parseDouble(amountStr);
        if (amount <= 0) continue;

        String type =
            (desc.toUpperCase().contains('/CR') ||
                desc.toUpperCase().contains('DEP TFR'))
            ? 'income'
            : 'expense';
        String merchant = _extractMerchantFromSBI(desc);

        _log('SBI Regex TX: $merchant | $amount | $type | $date');
        transactions.add(
          ExtractedTransaction(
            date: date.toIso8601String().split('T')[0],
            description: merchant,
            amount: amount,
            type: type,
            lineNumber: 0,
          ),
        );
      } catch (e) {
        _log('SBI regex match failed: $e');
      }
    }

    return transactions;
  }

  // --- HELPERS ---

  /// Convert month name to int
  static int? _monthToInt(String monthStr) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[monthStr.toLowerCase().substring(0, 3)];
  }

  /// Clean merchant name from raw description
  static String _cleanMerchantName(String raw) {
    String name = raw.trim();

    // Remove common suffixes/prefixes
    name = name.replaceAll(RegExp(r'\d{10,}'), ''); // Long numbers
    name = name.replaceAll(RegExp(r'@\w+'), ''); // UPI handles
    name = name.replaceAll(RegExp(r'\.soz\d+'), ''); // Federal specific
    name = name.replaceAll(RegExp(r'\.\d+'), ''); // Decimal numbers
    name = name.replaceAll(RegExp(r'[^\w\s&\-]'), ' '); // Special chars
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize properly
    if (name.isNotEmpty) {
      name = name
          .split(' ')
          .map((w) {
            if (w.isEmpty) return w;
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return name.isEmpty ? 'Transaction' : name;
  }

  static double _parseDouble(String s) {
    return double.parse(s.replaceAll(',', ''));
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      String clean = dateStr.replaceAll('"', '').trim();

      // Handle "31/12/2025" (DD/MM/YYYY)
      if (clean.contains('/') && !clean.contains('-')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // Handle "01-Oct-2025" (IDFC format DD-Mon-YYYY)
      final monthNamePattern = RegExp(
        r'^(\d{1,2})[/-]([A-Za-z]{3})[/-](\d{4})$',
      );
      final monthNameMatch = monthNamePattern.firstMatch(clean);
      if (monthNameMatch != null) {
        final day = int.parse(monthNameMatch.group(1)!);
        final monthStr = monthNameMatch.group(2)!.toLowerCase();
        final year = int.parse(monthNameMatch.group(3)!);
        final month = _monthToInt(monthStr);
        if (month != null) {
          return DateTime(year, month, day);
        }
      }

      // Handle "2025-10-01" (YYYY-MM-DD) or "01-10-2025" (DD-MM-YYYY)
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          // Check if first part looks like year (4 digits)
          if (parts[0].length == 4 && int.tryParse(parts[0]) != null) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
          // Otherwise assume DD-MM-YYYY
          if (parts[2].length == 4) {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }

      // Handle "01 Oct 2025" or "01 Oct"
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        int day = int.parse(parts[0]);
        int year = DateTime.now().year;
        if (parts.length > 2 && parts[2].length == 4) {
          year = int.parse(parts[2]);
        }

        final month = _monthToInt(parts[1]);
        if (month != null) {
          return DateTime(year, month, day);
        }
      }

      return null;
    } catch (e) {
      _log('Date parse failed for "$dateStr": $e');
      return null;
    }
  }
}
