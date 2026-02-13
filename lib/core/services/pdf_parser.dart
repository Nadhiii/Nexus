import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/extracted_transaction.dart';

class PDFParser {
  final GenerativeModel _model;

  PDFParser(String apiKey)
    : _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Keep it factual
        ),
      );

  /// Analyzes the PDF and extracts transactions using Gemini
  Future<List<ExtractedTransaction>> parse(File pdfFile) async {
    final prompt = Content.multi([
      TextPart('''
        You are a financial data extraction engine. Analyze the attached bank statement PDF.

        **MISSION:**
        Extract every financial transaction into a strict JSON array.

        **UNIVERSAL PARSING RULES:**
        1. **Date Handling:** - Use "Transaction Date" or "Value Date". 
           - **CRITICAL:** If a date is missing (common in Federal Bank), use the date from the previous valid row (Forward Fill).
           - Convert all dates to "YYYY-MM-DD" format.
        
        2. **Description & Merchant:**
           - Extract the full description. 
           - Attempt to identify the "Merchant" (e.g., "Swiggy", "Zomato", "User Name") and put it in "merchant_name". Clean up bank codes.

        3. **Amounts & Type:**
           - If separate "Debit"/"Credit" columns exist, use them.
           - If single column, infer type from description (e.g., "UPI IN" = INCOME/CREDIT, "UPIOUT" = EXPENSE/DEBIT).
           - "type" must be exactly "expense" or "income".
           - All amounts must be positive numbers.

        4. **Exclusions:**
           - Ignore "Opening/Closing Balance" rows.
           - Ignore page headers/footers.

        **OUTPUT JSON STRUCTURE:**
        [
          {
            "date": "YYYY-MM-DD",
            "description": "Original raw description",
            "merchant_name": "Cleaned name",
            "amount": 100.50,
            "type": "expense"
          }
        ]
      '''),
      DataPart('application/pdf', await pdfFile.readAsBytes()),
    ]);

    try {
      final response = await _model.generateContent([prompt]);

      if (response.text == null) throw Exception("Empty response from AI");

      // Clean Markdown if present (e.g. ```json ... ```)
      String cleanJson = response.text!
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      final List<dynamic> rawList = jsonDecode(cleanJson);

      return rawList.map((item) {
        return ExtractedTransaction(
          date: item['date'] ?? '',
          description: item['merchant_name'] ?? item['description'],
          amount: (item['amount'] is int)
              ? (item['amount'] as int).toDouble()
              : (item['amount'] as double),
          type: item['type'] ?? 'expense',
          lineNumber: 0,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print('PDFParser Error: $e');
      rethrow;
    }
  }
}
