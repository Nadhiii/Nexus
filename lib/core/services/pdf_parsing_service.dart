import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_statement.dart';
import '../models/transaction.dart';
import 'pdf_password_manager.dart';
import 'pdf_parser.dart'; // Import the new parser
import 'duplicate_detector.dart';

class PDFParsingService extends ChangeNotifier {
  // ... (keep existing state variables like _lastParseResult)

  // TODO: Securely inject your API Key
  static const String _geminiApiKey = "YOUR_GEMINI_API_KEY";

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
        // ... (Keep your existing password retry logic here) ...
        // ... Assuming you find the password and set 'validPassword' ...

        if (validPassword == null) {
          return PDFParseResult(
            success: false,
            errors: ['Password required'],
            requiresPassword: true,
          );
        }

        // Decrypt for Gemini
        tempUnlockedFile = await _createUnlockedTempFile(
          fileBytes,
          validPassword,
        );
      }

      // --- STEP 2: Parse using the new PDFParser ---
      if (kDebugMode) print('[PDFParsingService] Sending to PDFParser...');

      // Initialize the parser
      final parser = PDFParser(_geminiApiKey);

      // Execute parse
      final transactions = await parser.parse(tempUnlockedFile!);

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
      if (tempUnlockedFile != null && tempUnlockedFile!.path != filePath) {
        if (await tempUnlockedFile!.exists()) {
          await tempUnlockedFile!.delete();
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
