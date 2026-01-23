import 'package:flutter/foundation.dart';
import '../models/pdf_statement.dart';

class GenericPDFParser {
  // --- 1. DETECT BANK ---
  static String? detectBank(String pdfText) {
    final text = pdfText.toUpperCase();

    // Check for IFSC Code Prefix (Strongest Signal)
    if (text.contains('FDRL')) return 'FEDERAL';
    if (text.contains('SBIN')) return 'SBI';
    if (text.contains('HDFC')) return 'HDFC';
    if (text.contains('ICIC')) return 'ICICI';
    if (text.contains('UTIB')) return 'AXIS';
    if (text.contains('KKBK')) return 'KOTAK';

    // Fallback: Check for Bank Names (Scan full text for footer)
    if (text.contains('FEDERAL BANK') || text.contains('FI MONEY'))
      return 'FEDERAL';

    return null;
  }

  // --- 2. EXTRACT METADATA ---
  static PDFStatementMetadata extractMetadata(
    String pdfText,
    String? detectedBank,
  ) {
    // Account Number
    final accountRegex = RegExp(
      r'(?:No|A/C)[:\s]*([0-9]{14})',
      caseSensitive: false,
    );
    final accountMatch = accountRegex.firstMatch(pdfText);

    // Period Detection
    final periodRegex = RegExp(
      r'(\d{1,2}\s+[A-Za-z]+\s+\d{4})\s+(?:to|-)\s+(\d{1,2}\s+[A-Za-z]+\s+\d{4})',
      caseSensitive: false,
    );
    final periodMatch = periodRegex.firstMatch(pdfText);

    DateTime? start, end;
    if (periodMatch != null) {
      start = _parseDate(periodMatch.group(1)!);
      end = _parseDate(periodMatch.group(2)!);
    }

    // Account Holder Strategy
    String holderName = 'Unknown User';
    final lines = pdfText.split('\n');

    // Blocklist for words that look like names but aren't
    final invalidNames = [
      'October',
      'November',
      'December',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'Statement',
      'Account',
      'Period',
      'Date',
      'Balance',
      'Page',
    ];

    for (int i = 0; i < 20 && i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip lines containing blocklisted words
      if (invalidNames.any((bad) => line.contains(bad))) continue;
      if (line.contains(RegExp(r'\d'))) continue; // Skip lines with numbers

      // Federal/Fi specific: Look for "Mahanadhi.P.J" style (Letters + Dots)
      // Or "ACCOUNT HOLDER : NAME"
      if (line.toUpperCase().startsWith('ACCOUNT HOLDER')) {
        holderName = line.split(':').last.trim();
        break;
      }

      // Name Heuristic: At least 3 chars, contains a dot (common for initials) or is Title Case
      if (line.contains('.') && line.length > 3 && !line.contains('..')) {
        holderName = line;
        break;
      }
    }

    return PDFStatementMetadata(
      bankName: detectedBank ?? 'Federal Bank',
      accountNumber: accountMatch?.group(1),
      accountHolder: holderName,
      accountType: 'Savings',
      statementPeriodStart: start,
      statementPeriodEnd: end,
    );
  }

  // --- 3. ROUTER ---
  static List<ExtractedTransaction> extractTransactions(String pdfText) {
    if (detectBank(pdfText) == 'FEDERAL' ||
        pdfText.contains('UPIOUT') ||
        pdfText.contains('FDRL')) {
      return _extractFederalTransactions(pdfText);
    }
    return _extractGenericTransactions(pdfText);
  }

  // ----------------------------------------------------------------------
  // FEDERAL BANK / FI PARSER
  // ----------------------------------------------------------------------
  static List<ExtractedTransaction> _extractFederalTransactions(
    String pdfText,
  ) {
    final transactions = <ExtractedTransaction>[];

    String cleanText = pdfText.replaceAll(RegExp(r'[\u00A0\u200B]'), ' ');
    final tokens = cleanText
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    String currentYear = DateTime.now().year.toString();
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(pdfText);
    if (yearMatch != null) currentYear = yearMatch.group(1)!;

    // Relaxed Amount Regex: Matches "28.00" inside "28.00x"
    bool hasAmount(String s) => RegExp(r'[0-9,]+\.[0-9]{2}').hasMatch(s);

    bool isDateStart(String s) => RegExp(r'^\d{1,2}$').hasMatch(s);
    bool isMonth(String s) => RegExp(
      r'^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$',
      caseSensitive: false,
    ).hasMatch(s);

    final startKeywords = [
      'UPIOUT',
      'UPI',
      'CHRG',
      'POS',
      'ECOM',
      'ATM',
      'IMPS',
      'NEFT',
      'RTGS',
      'SBINT',
    ];

    String lastDate = "";
    int i = 0;

    while (i < tokens.length) {
      String token = tokens[i];

      // 1. DATE Check
      if (i + 1 < tokens.length &&
          isDateStart(token) &&
          isMonth(tokens[i + 1])) {
        lastDate = "$token ${tokens[i + 1]}";
        i += 2;
        continue;
      }

      // 2. TRANSACTION START
      bool isStart = false;
      for (var k in startKeywords) {
        if (token.toUpperCase().contains(k)) {
          isStart = true;
          break;
        }
      }

      if (isStart) {
        StringBuffer descBuffer = StringBuffer();
        descBuffer.write("$token ");

        int j = i + 1;
        double? amount;

        // Scan ahead
        while (j < tokens.length && j < i + 60) {
          String nextToken = tokens[j];
          if (hasAmount(nextToken)) {
            // Clean the amount token (remove non-numeric chars)
            String cleanAmount = nextToken.replaceAll(RegExp(r'[^0-9.]'), '');
            amount = double.tryParse(cleanAmount);
            i = j;
            break;
          } else {
            descBuffer.write("$nextToken ");
            j++;
          }
        }

        if (amount != null && amount > 0) {
          String rawDesc = descBuffer.toString().trim();

          // --- ROBUST TYPE DETECTION ---
          String type = 'debit'; // Default
          String upper = rawDesc.toUpperCase();

          if (upper.contains('UPI IN') ||
              upper.contains('CREDIT') ||
              upper.contains('SBINT') ||
              upper.contains('REFUND')) {
            type = 'credit';
          }
          // UPIOUT is definitively Debit
          if (upper.contains('UPIOUT') ||
              upper.contains('DEBIT') ||
              upper.contains('DR')) {
            type = 'debit';
          }

          String cleanDesc = _cleanFederalDescription(rawDesc);
          DateTime date =
              _parseDate("$lastDate $currentYear") ?? DateTime.now();

          transactions.add(
            ExtractedTransaction(
              date: date.toIso8601String().split('T')[0],
              description: cleanDesc,
              amount: amount,
              type: type,
              lineNumber: 0,
            ),
          );
        }
      }
      i++;
    }
    return transactions;
  }

  static String _cleanFederalDescription(String raw) {
    String desc = raw;
    desc = desc
        .replaceAll(RegExp(r'UPI\s?OUT/?'), '')
        .replaceAll(RegExp(r'UPI\s?IN/?'), '')
        .replaceAll(RegExp(r'CHRG/'), '');

    if (desc.contains('/')) {
      final parts = desc.split('/');
      String candidate = "";
      for (var part in parts) {
        if (!RegExp(r'^\d+$').hasMatch(part) &&
            part.length > candidate.length) {
          candidate = part;
        }
      }
      if (candidate.isNotEmpty) desc = candidate;
    }
    return desc.trim();
  }

  static List<ExtractedTransaction> _extractGenericTransactions(
    String pdfText,
  ) {
    return [];
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      final clean = dateStr.replaceAll(RegExp(r'[,/-]'), ' ').trim();
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length < 3) return null;
      int day = int.parse(parts[0]);
      String monthStr = parts[1].toLowerCase().substring(0, 3);
      int year = int.parse(parts[2]);
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
      return DateTime(year, months[monthStr] ?? 1, day);
    } catch (e) {
      return null;
    }
  }
}
