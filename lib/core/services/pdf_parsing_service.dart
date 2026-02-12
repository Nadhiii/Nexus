import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // REQUIRED LIBRARY
import '../models/pdf_statement.dart';
import '../models/transaction.dart';
import 'pdf_parser.dart';
import 'duplicate_detector.dart';
import 'pdf_password_manager.dart';

/// Main PDF Parsing Service
class PDFParsingService extends ChangeNotifier {
  PDFParseResult? _lastParseResult;
  PDFImportProgress? _importProgress;

  PDFParseResult? get lastParseResult => _lastParseResult;
  PDFImportProgress? get importProgress => _importProgress;

  /// Parse a PDF file with optional password
  Future<PDFParseResult> parsePDF(
    String filePath, {
    String? userSelectedBank,
    String? userProvidedPassword,
  }) async {
    try {
      if (kDebugMode) print('[PDFParsingService] Reading PDF: $filePath');

      String pdfText = '';
      String? workingPassword;

      // 1. Attempt Extraction (Try User Password -> Saved Passwords -> No Password)
      try {
        // A. Try User Provided Password First
        if (userProvidedPassword != null) {
          pdfText = await _extractTextWithLibrary(
            filePath,
            userProvidedPassword,
          );
          workingPassword = userProvidedPassword;
        }
        // B. Try No Password (or Saved Passwords)
        else {
          try {
            // Try open without password
            pdfText = await _extractTextWithLibrary(filePath, "");
          } catch (e) {
            // If failed, it might be password protected. Try saved passwords.
            final savedPasswords = await PDFPasswordManager.getSavedPasswords();
            bool unlocked = false;

            for (final saved in savedPasswords) {
              try {
                pdfText = await _extractTextWithLibrary(filePath, saved);
                workingPassword = saved;
                unlocked = true;
                break;
              } catch (_) {
                continue;
              }
            }

            if (!unlocked) throw Exception("Password required");
          }
        }
      } catch (e) {
        // If we still can't open it, report password required
        return PDFParseResult(
          success: false,
          errors: ['PDF is password-protected. Please provide the password.'],
          requiresPassword: true,
          requiresManualBankSelection: true,
        );
      }

      if (pdfText.isEmpty) {
        return PDFParseResult(
          success: false,
          errors: ['Extracted text is empty. File may be image-based/scanned.'],
          requiresManualBankSelection: true,
        );
      }

      if (kDebugMode) {
        print(
          '[PDFParsingService] Success! Extracted ${pdfText.length} characters.',
        );
      }

      // 2. Detect bank
      String? detectedBank =
          userSelectedBank ?? GenericPDFParser.detectBank(pdfText);

      // 3. Extract Metadata & Transactions
      final metadata = GenericPDFParser.extractMetadata(pdfText, detectedBank);
      final transactions = GenericPDFParser.extractTransactions(pdfText);

      if (transactions.isEmpty) {
        return PDFParseResult(
          success: false,
          errors: ['No transactions found. Verify the statement format.'],
          requiresManualBankSelection: true,
        );
      }

      // 4. Save working password if successful
      if (workingPassword != null) {
        await PDFPasswordManager.savePassword(workingPassword);
      }

      final statement = PDFStatement(
        id: '${detectedBank ?? "Unknown"}_${DateTime.now().millisecondsSinceEpoch}',
        filePath: filePath,
        metadata: metadata,
        transactions: transactions,
        uploadedAt: DateTime.now(),
        fileHash: '',
      );

      _lastParseResult = PDFParseResult(
        success: true,
        statement: statement,
        detectedBank: detectedBank,
        warnings: _generateWarnings(metadata, transactions),
        usedPassword: workingPassword != null,
      );

      notifyListeners();
      return _lastParseResult!;
    } catch (e) {
      if (kDebugMode) print('[PDFParsingService] Critical Error: $e');
      _lastParseResult = PDFParseResult(
        success: false,
        errors: ['Error parsing PDF: $e'],
        requiresManualBankSelection: true,
      );
      notifyListeners();
      return _lastParseResult!;
    }
  }

  /// REAL IMPLEMENTATION using Syncfusion PDF
  Future<String> _extractTextWithLibrary(
    String filePath,
    String password,
  ) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();

      // Load the PDF document
      final PdfDocument document = PdfDocument(
        inputBytes: bytes,
        password: password,
      );

      // Extract text from all pages
      String text = PdfTextExtractor(document).extractText();

      // Dispose the document
      document.dispose();

      return text;
    } catch (e) {
      // Syncfusion throws specific errors for passwords
      if (e.toString().toLowerCase().contains('password')) {
        throw Exception("Password required");
      }
      rethrow;
    }
  }

  // --- PRESERVED HELPER METHODS ---

  List<String> _generateWarnings(
    PDFStatementMetadata metadata,
    List<ExtractedTransaction> transactions,
  ) {
    final warnings = <String>[];
    if (metadata.accountNumber == null) {
      warnings.add('Account number not detected.');
    }
    if (transactions.isEmpty) warnings.add('No transactions detected.');
    return warnings;
  }

  Future<Map<ExtractedTransaction, DuplicateCheckResult>> checkDuplicates(
    List<ExtractedTransaction> pdfTransactions,
    List<Transaction> existingTransactions,
  ) async {
    _updateProgress(
      totalTransactions: pdfTransactions.length,
      currentStatus: 'Checking for duplicates...',
    );
    return await DuplicateDetector.checkBatch(
      pdfTransactions,
      existingTransactions,
    );
  }

  void _updateProgress({
    required int totalTransactions,
    int processedTransactions = 0,
    int successfulImports = 0,
    int duplicateSkipped = 0,
    int errorCount = 0,
    required String currentStatus,
  }) {
    _importProgress = PDFImportProgress(
      totalTransactions: totalTransactions,
      processedTransactions: processedTransactions,
      successfulImports: successfulImports,
      duplicateSkipped: duplicateSkipped,
      errorCount: errorCount,
      currentStatus: currentStatus,
      percentComplete: totalTransactions > 0
          ? (processedTransactions / totalTransactions) * 100
          : 0,
    );
    notifyListeners();
  }
}
