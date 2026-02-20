import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_statement.dart';
import '../models/transaction.dart';
import '../models/pdf_parsing_provider.dart';
import '../config/ai_config.dart';
import 'pdf_parser.dart';
import 'claude_pdf_parser.dart';
import 'local_pdf_parser.dart';
import 'duplicate_detector.dart';

class PDFParsingService extends ChangeNotifier {
  // API keys (managed by centralized AIConfig - supports Gemini or Claude)
  String? _geminiApiKey;
  String? _claudeApiKey;
  PDFParsingProvider _provider = PDFParsingProvider.gemini;

  // Local parser instance
  final LocalPDFParser _localParser = LocalPDFParser();

  /// Set the Gemini API key for PDF parsing
  void setGeminiApiKey(String apiKey) {
    _geminiApiKey = apiKey;
    if (kDebugMode) print('[PDFParsingService] Gemini API key set');
  }

  /// Set the Claude API key for PDF parsing
  void setClaudeApiKey(String apiKey) {
    _claudeApiKey = apiKey;
    if (kDebugMode) print('[PDFParsingService] Claude API key set');
  }

  /// Set which provider to use for PDF parsing
  void setPDFParsingProvider(PDFParsingProvider provider) {
    _provider = provider;
    if (kDebugMode) {
      print('[PDFParsingService] Provider set to: ${provider.name}');
    }
  }

  Future<PDFParseResult> parsePDF(
    String filePath, {
    String? userSelectedBank,
    String? userProvidedPassword,
  }) async {
    File? tempUnlockedFile;

    try {
      if (kDebugMode) print('[PDFParsingService] Processing: $filePath');

      // --- STEP 1: Unlock PDF if needed ---
      File originalFile = File(filePath);
      List<int> fileBytes = await originalFile.readAsBytes();
      String? validPassword;

      try {
        PdfDocument(inputBytes: fileBytes).dispose();
        tempUnlockedFile = originalFile; // Not password protected
      } catch (e) {
        validPassword = userProvidedPassword;

        if (validPassword == null || validPassword.isEmpty) {
          return PDFParseResult(
            success: false,
            errors: ['Password required'],
            requiresPassword: true,
          );
        }

        tempUnlockedFile = await _createUnlockedTempFile(
          fileBytes,
          validPassword,
        );
      }

      // --- STEP 2: Try local parser first ---
      if (kDebugMode) print('[PDFParsingService] Trying local parser...');

      List<ExtractedTransaction> transactions = [];
      String? parseError;

      try {
        transactions = await _localParser.parse(tempUnlockedFile);
        if (kDebugMode) {
          print(
            '[PDFParsingService] Local parser succeeded with ${transactions.length} transactions',
          );
        }
      } catch (e) {
        parseError = e.toString();
        if (kDebugMode) {
          print('[PDFParsingService] Local parser failed: $parseError');
        }

        // --- STEP 3: Fall back to AI parser ---
        if (kDebugMode) {
          print('[PDFParsingService] Using provider: ${_provider.name}');
        }

        if (_provider == PDFParsingProvider.claude) {
          // Use Claude for PDF parsing
          if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
            _claudeApiKey = await AIConfig.getClaudeApiKey();
          }

          if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
            return PDFParseResult(
              success: false,
              errors: [
                'Claude API key required for PDF parsing. Please add it in Nex settings.',
              ],
            );
          }

          if (kDebugMode) {
            print('[PDFParsingService] Sending to Claude parser...');
          }
          final parser = ClaudePDFParser(_claudeApiKey!);
          transactions = await parser.parse(tempUnlockedFile);
        } else {
          // Use Gemini for PDF parsing (default)
          if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
            _geminiApiKey = await AIConfig.getGeminiApiKey();
          }

          if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
            return PDFParseResult(
              success: false,
              errors: [
                'Gemini API key required for PDF parsing. Please add it in Nex settings.',
              ],
            );
          }

          if (kDebugMode) {
            print('[PDFParsingService] Sending to Gemini parser...');
          }
          final parser = PDFParser(_geminiApiKey!);
          transactions = await parser.parse(tempUnlockedFile);
        }
      }

      if (transactions.isEmpty) {
        return PDFParseResult(
          success: false,
          errors: ['No transactions found. Check statement format.'],
        );
      }

      // --- STEP 3: Create Result ---
      final statement = PDFStatement(
        id: 'Parsed_${DateTime.now().millisecondsSinceEpoch}',
        filePath: filePath,
        metadata: PDFStatementMetadata(
          bankName: "Auto-Detected",
          accountNumber: "Unknown",
          statementPeriodStart: DateTime.now(),
          statementPeriodEnd: DateTime.now(),
        ),
        transactions: transactions,
        uploadedAt: DateTime.now(),
        fileHash: '',
      );

      return PDFParseResult(
        success: true,
        statement: statement,
        detectedBank: "Auto-Detected",
        warnings: [],
      );
    } catch (e) {
      if (kDebugMode) print('[PDFParsingService] Error: $e');
      return PDFParseResult(success: false, errors: [e.toString()]);
    } finally {
      // Clean up temp file
      if (tempUnlockedFile != null && tempUnlockedFile.path != filePath) {
        if (await tempUnlockedFile.exists()) {
          await tempUnlockedFile.delete();
        }
      }
    }
  }

  Future<File> _createUnlockedTempFile(List<int> bytes, String password) async {
    final document = PdfDocument(inputBytes: bytes, password: password);
    final directory = await getTemporaryDirectory();
    final tempPath =
        '${directory.path}/unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(await document.save());
    document.dispose();
    return tempFile;
  }

  /// Check for duplicate transactions
  Future<Map<ExtractedTransaction, DuplicateCheckResult>> checkDuplicates(
    List<ExtractedTransaction> pdfTransactions,
    List<Transaction> existingTransactions,
  ) async {
    return await DuplicateDetector.checkBatch(
      pdfTransactions,
      existingTransactions,
    );
  }
}
