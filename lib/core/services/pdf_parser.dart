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
      'federal': ['federal bank', 'fdrl'],
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
      r'(?:Account Holder|Name)[:\s]*([A-Za-z\s.]+)',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(text);

    // Account type
    String? accountType;
    if (text.contains('Savings') || text.contains('SAVINGS')) {
      accountType = 'Savings Account';
    } else if (text.contains('Current'))
      accountType = 'Current Account';
    else if (text.contains('Salary'))
      accountType = 'Salary Account';

    // Statement period (try multiple date formats)
    DateTime? periodStart;
    DateTime? periodEnd;

    // For Federal Bank format: "1 October 2025 to 31 December 2025"
    final periodRegexFederal = RegExp(
      r'(\d{1,2}\s+\w+\s+\d{4})\s+to\s+(\d{1,2}\s+\w+\s+\d{4})',
      caseSensitive: false,
    );
    final periodMatchFederal = periodRegexFederal.firstMatch(text);

    if (periodMatchFederal != null) {
      periodStart = _parseDate(periodMatchFederal.group(1) ?? '');
      periodEnd = _parseDate(periodMatchFederal.group(2) ?? '');
    } else {
      // Standard format with slashes/hyphens
      final periodRegex = RegExp(
        r'(?:Statement Period|Period|From)[:\s]*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})[^0-9]*to[^0-9]*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
        caseSensitive: false,
      );
      final periodMatch = periodRegex.firstMatch(text);

      if (periodMatch != null) {
        periodStart = _parseDate(periodMatch.group(1) ?? '');
        periodEnd = _parseDate(periodMatch.group(2) ?? '');
      }
    }

    // Opening and closing balance
    double? openingBalance;
    double? closingBalance;

    // Opening balance patterns
    final openingRegex = RegExp(
      r'(?:Opening Balance|Opening)[^0-9]*on[^0-9]*\d{1,2}\s+\w+\s+\d{4}[^0-9]*₹?[\s]*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    var balanceMatch = openingRegex.firstMatch(text);
    if (balanceMatch != null) {
      openingBalance = _parseAmount(balanceMatch.group(1) ?? '');
    } else {
      // Alternative pattern
      final balanceRegex = RegExp(
        r'(?:Opening|Opening Balance)[:\s]*₹?[\s]*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      );
      balanceMatch = balanceRegex.firstMatch(text);
      if (balanceMatch != null) {
        openingBalance = _parseAmount(balanceMatch.group(1) ?? '');
      }
    }

    // Closing balance patterns
    final closingRegex = RegExp(
      r'(?:Closing Balance|Closing)[^0-9]*on[^0-9]*\d{1,2}\s+\w+\s+\d{4}[^0-9]*₹?[\s]*([0-9,]+\.?[0-9]*)',
      caseSensitive: false,
    );
    var closingMatch = closingRegex.firstMatch(text);
    if (closingMatch != null) {
      closingBalance = _parseAmount(closingMatch.group(1) ?? '');
    } else {
      // Alternative pattern
      final altClosingRegex = RegExp(
        r'(?:Closing|Closing Balance)[:\s]*₹?[\s]*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      );
      closingMatch = altClosingRegex.firstMatch(text);
      if (closingMatch != null) {
        closingBalance = _parseAmount(closingMatch.group(1) ?? '');
      }
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

    // Try month name format: "1 October 2025"
    final monthNames = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };

    final monthNamePattern = RegExp(
      r'(\d{1,2})\s+(\w+)\s+(\d{4})',
      caseSensitive: false,
    );
    final monthMatch = monthNamePattern.firstMatch(dateStr);
    if (monthMatch != null) {
      try {
        int day = int.parse(monthMatch.group(1) ?? '0');
        String monthStr = (monthMatch.group(2) ?? '').toLowerCase();
        int? month = monthNames[monthStr];
        int year = int.parse(monthMatch.group(3) ?? '0');

        if (month != null) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        if (kDebugMode) print('Error parsing date with month name: $e');
      }
    }

    // Try numeric formats
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

  /// Extract transactions from PDF text
  /// Enhanced to properly detect transaction type based on keywords
  static List<ExtractedTransaction> extractTransactions(String pdfText) {
    final transactions = <ExtractedTransaction>[];
    final lines = pdfText.split('\n');
    int lineNumber = 0;

    // Keywords that indicate income/credit transactions
    final incomeKeywords = [
      'upi in/',
      'neft cr',
      'rtgs cr',
      'imps cr',
      'refund',
      'interest',
      'dividend',
      'salary',
      'credit',
      'deposit',
    ];

    // Keywords that indicate expense/debit transactions
    final expenseKeywords = [
      'upiout/',
      'neft dr',
      'rtgs dr',
      'imps dr',
      'atm',
      'pos',
      'emi',
      'chrg/',
      'charge',
      'fee',
      'debit',
    ];

    for (final line in lines) {
      lineNumber++;
      final trimmedLine = line.trim();
      
      // Skip empty lines and headers
      if (trimmedLine.isEmpty || 
          trimmedLine.toLowerCase().contains('date') ||
          trimmedLine.toLowerCase().contains('transaction details') ||
          trimmedLine.toLowerCase().contains('balance')) {
        continue;
      }

      // Try to parse Federal Bank format first
      // Format: Date | Transaction Details | Amount | Balance
      final federalPattern = RegExp(
        r'(\d{1,2}\s+\w{3})\s+(.*?)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)$',
      );
      final federalMatch = federalPattern.firstMatch(trimmedLine);

      if (federalMatch != null) {
        try {
          final dateStr = federalMatch.group(1) ?? '';
          final description = federalMatch.group(2) ?? '';
          final amount = _parseAmount(federalMatch.group(3) ?? '0') ?? 0;
          final balance = _parseAmount(federalMatch.group(4) ?? '0');

          if (amount <= 0 || description.isEmpty) continue;

          // Determine transaction type based on keywords in description
          final descLower = description.toLowerCase();
          String type = 'expense'; // Default to expense
          
          // Check for income keywords
          for (final keyword in incomeKeywords) {
            if (descLower.contains(keyword)) {
              type = 'income';
              break;
            }
          }
          
          // If not income, verify it's an expense
          if (type != 'income') {
            bool isExpense = false;
            for (final keyword in expenseKeywords) {
              if (descLower.contains(keyword)) {
                isExpense = true;
                break;
              }
            }
            // If no clear expense keyword found, check the balance change direction
            // This is a fallback - you might want to refine this logic
            if (!isExpense && balance != null) {
              // Could add additional logic here if needed
            }
          }

          // Parse date - for "01 Oct" format, we need the year from statement period
          DateTime? date;
          final shortDateMatch = RegExp(r'(\d{1,2})\s+(\w{3})').firstMatch(dateStr);
          if (shortDateMatch != null) {
            // Extract year from the statement period in metadata
            // For now, use current year or extract from statement
            final yearMatch = RegExp(r'(\d{4})').firstMatch(pdfText);
            final year = yearMatch != null ? int.parse(yearMatch.group(1)!) : DateTime.now().year;
            
            final day = int.parse(shortDateMatch.group(1)!);
            final monthStr = shortDateMatch.group(2)!.toLowerCase();
            
            final monthMap = {
              'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
              'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
              'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
            };
            
            final month = monthMap[monthStr];
            if (month != null) {
              date = DateTime(year, month, day);
            }
          }

          if (date != null) {
            transactions.add(
              ExtractedTransaction(
                date: date.toIso8601String().split('T')[0],
                description: description.trim(),
                amount: amount,
                balance: balance,
                type: type,
                lineNumber: lineNumber,
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing Federal Bank transaction at line $lineNumber: $e');
          }
        }
        continue;
      }

      // Fallback: Generic pattern for other bank formats
      final transactionPattern = RegExp(
        r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\s+(.+?)\s+([\d,]+\.?\d*)\s+([\d,]+\.?\d*)',
      );
      final match = transactionPattern.firstMatch(trimmedLine);

      if (match != null) {
        try {
          final dateStr = match.group(1) ?? '';
          final description = match.group(2) ?? '';
          final col3 = _parseAmount(match.group(3) ?? '0') ?? 0;
          final col4 = _parseAmount(match.group(4) ?? '0') ?? 0;

          // Determine which column is debit/credit
          // Usually: Date | Description | Debit | Credit | Balance
          // or: Date | Description | Amount | Balance
          String type = 'expense';
          double amount = 0;

          final descLower = description.toLowerCase();
          
          // Check for income keywords
          bool isIncome = false;
          for (final keyword in incomeKeywords) {
            if (descLower.contains(keyword)) {
              isIncome = true;
              break;
            }
          }

          if (col3 > 0 && col4 > 0) {
            // Both columns have values - likely Debit/Credit format
            // Determine based on keywords
            if (isIncome) {
              type = 'income';
              amount = col4; // Credit column
            } else {
              type = 'expense';
              amount = col3; // Debit column
            }
          } else if (col3 > 0) {
            // Only first amount column has value
            type = isIncome ? 'income' : 'expense';
            amount = col3;
          } else if (col4 > 0) {
            // Only second column has value (likely balance)
            continue; // Skip this line
          }

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
            print('Error parsing generic transaction at line $lineNumber: $e');
          }
        }
      }
    }

    if (kDebugMode) {
      print('[GenericPDFParser] Extracted ${transactions.length} transactions');
      final incomeCount = transactions.where((t) => t.type == 'income').length;
      final expenseCount = transactions.where((t) => t.type == 'expense').length;
      print('[GenericPDFParser] Income: $incomeCount, Expense: $expenseCount');
    }

    return transactions;
  }
}