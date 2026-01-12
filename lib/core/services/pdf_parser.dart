import 'package:flutter/foundation.dart';
import '../models/pdf_statement.dart';

/// Generic PDF Statement Parser
/// Can be extended for specific banks
class GenericPDFParser {
  /// Detect bank from PDF text content
  static String? detectBank(String pdfText) {
    final text = pdfText.toLowerCase();

    // Bank patterns for detection
    final bankPatterns = {
      'sbi': ['state bank of india', 'sbi online', 'state bank'],
      'hdfc': ['hdfc bank', 'hdfc', 'housing development finance'],
      'icici': ['icici bank', 'icici', 'industrial credit'],
      'axis': ['axis bank', 'axis'],
      'kotak': ['kotak mahindra', 'kotak bank'],
      'boi': ['bank of india', 'boi'],
    };

    for (final entry in bankPatterns.entries) {
      for (final pattern in entry.value) {
        if (text.contains(pattern)) {
          return entry.key.toUpperCase();
        }
      }
    }

    return null; // Unknown bank
  }

  /// Extract metadata from PDF text
  static PDFStatementMetadata extractMetadata(
    String pdfText,
    String? detectedBank,
  ) {
    final text = pdfText;

    // Account number pattern (typically 10-16 digits or alphanumeric)
    final accountRegex = RegExp(
      r'(?:Account|A/C|Account No|A/C No)[:\s]*([A-Za-z0-9]{10,16})',
      caseSensitive: false,
    );
    final accountMatch = accountRegex.firstMatch(text);

    // Account holder name
    final nameRegex = RegExp(
      r'(?:Account Holder|Name)[:\s]*([A-Za-z\s]+)',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(text);

    // Account type
    String? accountType;
    if (text.contains('Savings')) {
      accountType = 'Savings Account';
    } else if (text.contains('Current'))
      accountType = 'Current Account';
    else if (text.contains('Salary'))
      accountType = 'Salary Account';

    // Statement period (try multiple date formats)
    DateTime? periodStart;
    DateTime? periodEnd;

    final periodRegex = RegExp(
      r'(?:Statement Period|Period|From)[:\s]*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})[^0-9]*to[^0-9]*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
      caseSensitive: false,
    );
    final periodMatch = periodRegex.firstMatch(text);

    if (periodMatch != null) {
      periodStart = _parseDate(periodMatch.group(1) ?? '');
      periodEnd = _parseDate(periodMatch.group(2) ?? '');
    }

    // Opening and closing balance
    double? openingBalance;
    double? closingBalance;

    final balanceRegex = RegExp(
      r'(?:Opening|Opening Balance)[:\s]*₹?[\s]*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    final balanceMatch = balanceRegex.firstMatch(text);
    if (balanceMatch != null) {
      openingBalance = _parseAmount(balanceMatch.group(1) ?? '');
    }

    final closingRegex = RegExp(
      r'(?:Closing|Closing Balance)[:\s]*₹?[\s]*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    final closingMatch = closingRegex.firstMatch(text);
    if (closingMatch != null) {
      closingBalance = _parseAmount(closingMatch.group(1) ?? '');
    }

    return PDFStatementMetadata(
      bankName: detectedBank,
      accountNumber: accountMatch?.group(1),
      accountHolder: nameMatch?.group(1)?.trim(),
      accountType: accountType,
      statementPeriodStart: periodStart,
      statementPeriodEnd: periodEnd,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
    );
  }

  /// Parse date from various formats
  static DateTime? _parseDate(String dateStr) {
    dateStr = dateStr.trim();

    // Remove ordinals (st, nd, rd, th)
    dateStr = dateStr.replaceAll(RegExp(r'(st|nd|rd|th)\b'), '');

    // Try various formats
    final formats = [
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'), // DD-MM-YYYY
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2})'), // DD-MM-YY
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          int day = int.parse(match.group(1) ?? '0');
          int month = int.parse(match.group(2) ?? '0');
          int year = int.parse(match.group(3) ?? '0');

          // Handle 2-digit years
          if (year < 100) {
            year = year + (year < 50 ? 2000 : 1900);
          }

          return DateTime(year, month, day);
        } catch (e) {
          if (kDebugMode) print('Error parsing date: $e');
        }
      }
    }

    return null;
  }

  /// Parse amount from string with commas and symbols
  static double? _parseAmount(String amountStr) {
    try {
      // Remove currency symbols and commas
      amountStr = amountStr
          .replaceAll('₹', '')
          .replaceAll(',', '')
          .replaceAll('USD', '')
          .replaceAll('INR', '')
          .trim();

      return double.tryParse(amountStr);
    } catch (e) {
      if (kDebugMode) print('Error parsing amount: $e');
      return null;
    }
  }

  /// Extract transactions from PDF text (table-based parsing)
  /// This is a simplified generic approach
  /// Bank-specific parsers should override this
  static List<ExtractedTransaction> extractTransactions(String pdfText) {
    final transactions = <ExtractedTransaction>[];

    // Split by lines and look for transaction patterns
    final lines = pdfText.split('\n');
    int lineNumber = 0;

    // Generic pattern: Date | Description | Debit/Amount | Credit/Amount | Balance
    final transactionPattern = RegExp(
      r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\s+(.+?)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)',
    );

    for (final line in lines) {
      lineNumber++;
      final match = transactionPattern.firstMatch(line);

      if (match != null) {
        try {
          final dateStr = match.group(1) ?? '';
          final description = match.group(2) ?? '';
          final debit = _parseAmount(match.group(3) ?? '0') ?? 0;
          final credit = _parseAmount(match.group(4) ?? '0') ?? 0;

          // Determine if debit or credit
          final amount = debit > 0 ? debit : credit;
          final type = debit > 0 ? 'debit' : 'credit';

          final date = _parseDate(dateStr);
          if (date != null && amount > 0 && description.isNotEmpty) {
            transactions.add(
              ExtractedTransaction(
                date: date.toIso8601String().split('T')[0],
                description: description.trim(),
                amount: amount,
                type: type,
                lineNumber: lineNumber,
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing transaction at line $lineNumber: $e');
          }
        }
      }
    }

    return transactions;
  }
}
