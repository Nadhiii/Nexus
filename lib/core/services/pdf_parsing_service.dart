import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/pdf_statement.dart';
import '../models/transaction.dart';
import 'pdf_parser.dart';
import 'duplicate_detector.dart';
import 'pdf_password_manager.dart';

/// Main PDF Parsing Service
/// Handles file reading, text extraction, and delegating to specific bank parsers
class PDFParsingService extends ChangeNotifier {
  PDFParseResult? _lastParseResult;
  PDFImportProgress? _importProgress;

  PDFParseResult? get lastParseResult => _lastParseResult;
  PDFImportProgress? get importProgress => _importProgress;

  /// Parse a PDF file with optional password
  /// Tries saved passwords first, then user-provided password
  /// Returns PDFParseResult with parsed statement or errors
  Future<PDFParseResult> parsePDF(
    String filePath, {
    String? userSelectedBank,
    String? userProvidedPassword,
  }) async {
    try {
      // 1. Read PDF file
      if (kDebugMode) print('[PDFParsingService] Reading PDF: $filePath');

      // Try to extract text, attempting saved passwords first if needed
      String pdfText = '';
      String? workingPassword;

      try {
        pdfText = await _extractTextFromPDF(
          filePath,
          password: userProvidedPassword,
        );
        if (userProvidedPassword != null) {
          workingPassword = userProvidedPassword;
        }
      } catch (e) {
        // If extraction failed and no password provided, try saved passwords
        if (userProvidedPassword == null) {
          final savedPasswords = await PDFPasswordManager.getSavedPasswords();

          if (savedPasswords.isNotEmpty && kDebugMode) {
            print(
              '[PDFParsingService] Trying ${savedPasswords.length} saved passwords...',
            );
          }

          for (final savedPassword in savedPasswords) {
            try {
              pdfText = await _extractTextFromPDF(
                filePath,
                password: savedPassword,
              );
              workingPassword = savedPassword;
              if (kDebugMode) {
                print(
                  '[PDFParsingService] Successfully unlocked PDF with saved password',
                );
              }
              break;
            } catch (e) {
              if (kDebugMode) {
                print(
                  '[PDFParsingService] Saved password failed, trying next...',
                );
              }
              continue;
            }
          }
        }

        // If still no success and we tried everything, indicate password needed
        if (pdfText.isEmpty &&
            userProvidedPassword == null &&
            workingPassword == null) {
          return PDFParseResult(
            success: false,
            errors: ['PDF is password-protected. Please provide the password.'],
            requiresPassword: true,
            requiresManualBankSelection: true,
          );
        }

        if (pdfText.isEmpty) {
          rethrow;
        }
      }

      if (pdfText.isEmpty) {
        return PDFParseResult(
          success: false,
          errors: [
            'Failed to extract text from PDF. File may be corrupted or image-based.',
          ],
          requiresManualBankSelection: true,
        );
      }

      // 2. Detect bank (unless user provided one)
      String? detectedBank =
          userSelectedBank ?? GenericPDFParser.detectBank(pdfText);

      final requiresManualSelection = detectedBank == null;
      if (requiresManualSelection && userSelectedBank == null) {
        return PDFParseResult(
          success: false,
          errors: [
            'Could not automatically detect bank. Please select manually.',
          ],
          warnings: [
            'Statement format not recognized. You can still proceed with manual selection.',
          ],
          requiresManualBankSelection: true,
        );
      }

      if (kDebugMode) print('[PDFParsingService] Detected bank: $detectedBank');

      // 3. Extract metadata
      final metadata = GenericPDFParser.extractMetadata(pdfText, detectedBank);

      if (metadata.accountNumber == null) {
        if (kDebugMode) {
          print(
            '[PDFParsingService] Warning: Could not extract account number',
          );
        }
      }

      // 4. Extract transactions
      final transactions = GenericPDFParser.extractTransactions(pdfText);

      if (transactions.isEmpty) {
        return PDFParseResult(
          success: false,
          errors: [
            'No transactions found in PDF. Please verify the file format.',
          ],
          requiresManualBankSelection: true,
        );
      }

      if (kDebugMode) {
        print(
          '[PDFParsingService] Extracted ${transactions.length} transactions',
        );
      }

      // 5. Save working password for future use
      if (workingPassword != null) {
        await PDFPasswordManager.savePassword(workingPassword);
        if (kDebugMode) {
          print('[PDFParsingService] Password saved for future PDFs');
        }
      }

      // 6. Create PDFStatement
      final statement = PDFStatement(
        id: '${detectedBank}_${DateTime.now().millisecondsSinceEpoch}',
        filePath: filePath,
        metadata: metadata,
        transactions: transactions,
        uploadedAt: DateTime.now(),
        fileHash: '', // TODO: Add file hashing
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
      if (kDebugMode) print('[PDFParsingService] Error: $e');

      _lastParseResult = PDFParseResult(
        success: false,
        errors: ['Error parsing PDF: $e'],
        requiresManualBankSelection: true,
      );

      notifyListeners();
      return _lastParseResult!;
    }
  }

  /// Extract text from PDF file with optional password support
  /// This requires installing and using a PDF library
  /// Recommended: Use pdfx or syncfusion_flutter_pdf for better text extraction
  Future<String> _extractTextFromPDF(
    String filePath, {
    String? password,
  }) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('PDF file not found: $filePath');
      }

      // TODO: Implement actual PDF text extraction using:
      // 1. pdfx package - Simple and lightweight
      // 2. syncfusion_flutter_pdf - More powerful, requires license
      // 3. pdf package - For reading PDF structure

      // For now, we return empty string as placeholder
      // Integration steps:
      // 1. Add package to pubspec.yaml: pdfx: ^2.5.0
      // 2. Read PDF bytes: final bytes = await file.readAsBytes();
      // 3. For password-protected PDFs, use the password parameter:
      //    final pdfDocument = PdfDocument(
      //      bytes: bytes,
      //      password: password,
      //    );
      // 4. Extract text from pages
      // 5. Return the extracted text

      if (kDebugMode) {
        print('[PDFParsingService] PDF file size: ${file.lengthSync()} bytes');
        if (password != null) {
          print('[PDFParsingService] Attempting extraction with password');
        }
        print(
          '[PDFParsingService] PDF text extraction not implemented. Install pdfx package for full support.',
        );
      }

      return '';
    } catch (e) {
      if (kDebugMode) {
        print('[PDFParsingService] Error extracting PDF text: $e');
      }
      rethrow;
    }
  }

  /// Generate warnings for data quality
  List<String> _generateWarnings(
    PDFStatementMetadata metadata,
    List<ExtractedTransaction> transactions,
  ) {
    final warnings = <String>[];

    if (metadata.accountNumber == null) {
      warnings.add(
        'Account number not found in PDF. You may need to verify it.',
      );
    }

    if (metadata.accountHolder == null) {
      warnings.add('Account holder name not found. Please enter it manually.');
    }

    if (transactions.isEmpty) {
      warnings.add('No transactions detected. Verify PDF format.');
    }

    if (metadata.statementPeriodStart == null) {
      warnings.add('Statement period not detected. Check dates manually.');
    }

    return warnings;
  }

  /// Check for duplicates in batch before import
  Future<Map<ExtractedTransaction, DuplicateCheckResult>> checkDuplicates(
    List<ExtractedTransaction> pdfTransactions,
    List<Transaction> existingTransactions,
  ) async {
    _updateProgress(
      totalTransactions: pdfTransactions.length,
      currentStatus: 'Checking for duplicates...',
    );

    final results = await DuplicateDetector.checkBatch(
      pdfTransactions,
      existingTransactions,
    );

    return results;
  }

  /// Update import progress
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

// Extension for null safety
extension NullSafety<T> on T? {
  R? let<R>(R Function(T) fn) {
    if (this != null) {
      return fn(this as T);
    }
    return null;
  }
}
