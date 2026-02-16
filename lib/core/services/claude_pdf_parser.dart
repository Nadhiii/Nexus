import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/pdf_statement.dart';
import '../config/ai_config.dart';
import 'claude_ai_service.dart';

class ClaudePDFParser {
  final String _apiKey;
  final List<String> _modelCandidates;

  ClaudePDFParser(String apiKey, {List<String>? modelCandidates})
    : _apiKey = apiKey,
      _modelCandidates = modelCandidates ?? AIConfig.claudePrecisionModels;

  /// Analyzes the PDF and extracts transactions using Claude
  Future<List<ExtractedTransaction>> parse(File pdfFile) async {
    final prompt = '''
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
''';

    String? lastError;

    for (final modelName in _modelCandidates) {
      try {
        if (kDebugMode)
          print('Attempting PDF parse with Claude model: $modelName');

        final service = ClaudeAIService(apiKey: _apiKey);

        // Read PDF as base64
        final fileBytes = await pdfFile.readAsBytes();
        final base64Data = base64Encode(fileBytes);

        final response = await service.sendVisionMessage(
          prompt: prompt,
          images: [
            {
              'type': 'document',
              'source': {
                'type': 'base64',
                'media_type': 'application/pdf',
                'data': base64Data,
              },
            },
          ],
          model: modelName,
          temperature: 0.1,
        );

        if (response.isEmpty) {
          throw Exception('Empty response from Claude');
        }

        // Clean Markdown if present (e.g. ```json ... ```)
        String cleanJson = response
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
            .trim();

        final List<dynamic> rawList = jsonDecode(cleanJson);

        if (kDebugMode)
          print(
            'Success! Extracted ${rawList.length} transactions using Claude ($modelName).',
          );

        return rawList.map((item) {
          return ExtractedTransaction(
            date: item['date'] ?? '',
            description:
                item['merchant_name'] ?? item['description'] ?? 'Unknown',
            amount: (item['amount'] is int)
                ? (item['amount'] as int).toDouble()
                : (item['amount'] as double),
            type: item['type'] ?? 'expense',
            lineNumber: 0,
          );
        }).toList();
      } catch (e) {
        lastError = e.toString();
        // Log the error but continue to the next model
        if (kDebugMode) print('Claude model $modelName failed: $e');
        continue;
      }
    }

    throw Exception('All Claude models failed. Last error: $lastError');
  }
}
