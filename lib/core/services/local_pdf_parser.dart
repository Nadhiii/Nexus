import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_statement.dart';

class LocalPDFParser {
  Future<List<ExtractedTransaction>> parse(File file) async {
    // 1. Extract Raw Text
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
    );
    String fullText = PdfTextExtractor(document).extractText();
    document.dispose();

    if (kDebugMode) print("Extracted Text Length: ${fullText.length}");

    // 2. Run the "Universal Scraper"
    // This ignores bank names and just hunts for transactions
    return _universalScraper(fullText);
  }

  List<ExtractedTransaction> _universalScraper(String text) {
    List<ExtractedTransaction> txns = [];
    final lines = text.split('\n');

    // 1. Define the "Golden Pattern" components
    // Date: Matches 01-Oct, 01/10/2025, 2025-10-01, 1 Oct 2025
    final datePattern = RegExp(
      r'(\d{1,2}[\/\-\.\s](?:[A-Za-z]{3}|\d{1,2})[\/\-\.\s]?\d{2,4}?)',
    );

    // Money: Matches 1,200.00 or 500.00 (Must have dot and 2 decimals)
    final moneyPattern = RegExp(r'[\d,]+\.\d{2}');

    String currentYear = DateTime.now().year.toString();

    for (String line in lines) {
      String cleanLine = line.trim();

      // Skip noise
      if (cleanLine.length < 10) continue;
      if (cleanLine.toLowerCase().contains("opening balance")) continue;
      if (cleanLine.toLowerCase().contains("brought forward")) continue;
      if (cleanLine.toLowerCase().contains("total")) continue;

      // --- STEP A: Does this line have a Date? ---
      final dateMatch = datePattern.firstMatch(cleanLine);
      if (dateMatch == null) continue; // No date? Skip it.

      // --- STEP B: Does this line have Money? ---
      final moneyMatches = moneyPattern.allMatches(cleanLine).toList();
      if (moneyMatches.isEmpty) continue; // No money? Skip it.

      // --- STEP C: Extract Data ---
      String dateStr = dateMatch.group(0)!;
      // Fix dates without year (e.g., "01 Oct")
      if (dateStr.length < 7) {
        dateStr = "$dateStr $currentYear";
      }

      // INTELLIGENT AMOUNT PICKER:
      // If 1 number found -> It is the Amount.
      // If 2+ numbers found -> The LAST one is Balance. The ONE BEFORE IT is Amount.
      double amount = 0.0;
      try {
        String rawAmount;
        if (moneyMatches.length == 1) {
          rawAmount = moneyMatches.first.group(0)!;
        } else {
          // Take the second to last number (Amount)
          rawAmount = moneyMatches[moneyMatches.length - 2].group(0)!;
        }
        amount = double.parse(rawAmount.replaceAll(',', ''));
      } catch (e) {
        continue; // Skip parse errors
      }

      // --- STEP D: Determine Income vs Expense ---
      // We look for "Cr", "Credit", "Dep" OR we check if the amount matches the "Credit" column
      // (Hard to check columns in raw text, so we rely on keywords)
      String upper = cleanLine.toUpperCase();
      bool isIncome =
          upper.contains(" CR ") ||
          upper.contains("CREDIT") ||
          upper.contains("DEPOSIT") ||
          upper.contains("UPI IN") ||
          upper.contains("REFUND");

      // --- STEP E: Clean Description ---
      // Remove Date and Amounts from the text to leave just the description
      String desc = cleanLine;
      desc = desc.replaceAll(dateStr, ''); // Remove date
      for (var m in moneyMatches) {
        desc = desc.replaceAll(m.group(0)!, ''); // Remove all numbers
      }
      desc = desc.replaceAll(RegExp(r'\s+'), ' ').trim(); // Fix spaces

      // --- STEP F: Save ---
      txns.add(
        ExtractedTransaction(
          date: dateStr,
          description: desc.isEmpty ? "Transaction" : desc,
          amount: amount,
          type: isIncome ? 'income' : 'expense',
          merchantName: _extractMerchant(desc),
        ),
      );
    }

    return txns;
  }

  String _extractMerchant(String desc) {
    // Basic cleanup to find a name-like string
    if (desc.contains('/')) {
      final parts = desc.split('/');
      for (var part in parts) {
        if (part.length > 3 && !part.contains(RegExp(r'\d'))) {
          return part.trim();
        }
      }
    }
    return "Unknown";
  }
}
