import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/detected_transaction.dart';
import 'bank_parsers/bank_statement_parser.dart';
import 'bank_parsers/idfc_statement_parser.dart';
import 'bank_parsers/sbi_statement_parser.dart';
import 'bank_parsers/slice_statement_parser.dart';

/// Container object for the parsed statement details.
class StatementParseData {
  final List<DetectedTransaction> transactions;
  final double? openingBalance;
  final double? closingBalance;

  StatementParseData({
    required this.transactions,
    this.openingBalance,
    this.closingBalance,
  });
}

class _PdfParsePayload {
  final Uint8List bytes;
  final String fileName;
  final String? password;

  _PdfParsePayload(this.bytes, this.fileName, {this.password});
}

class _PdfParseResult {
  final List<Map<String, dynamic>>? transactions;
  final double? openingBalance;
  final double? closingBalance;
  final bool isPasswordError;
  final String? error;

  _PdfParseResult({
    this.transactions,
    this.openingBalance,
    this.closingBalance,
    this.isPasswordError = false,
    this.error,
  });
}

/// Human-readable bank name for the parser that matched.
String _bankNameFor(BankStatementParser parser) {
  if (parser is SbiStatementParser) return 'SBI';
  if (parser is IdfcStatementParser) return 'IDFC First';
  if (parser is SliceStatementParser) return 'Slice';
  return 'Unknown Bank';
}

_PdfParseResult _parsePdfInIsolate(_PdfParsePayload payload) {
  // --- Step 1: open the document. ONLY this step can produce a password error. ---
  PdfDocument document;
  try {
    document = PdfDocument(
      inputBytes: payload.bytes,
      password: payload.password,
    );
  } catch (e) {
    return _PdfParseResult(isPasswordError: true, error: e.toString());
  }

  String rawText;
  try {
    rawText = PdfTextExtractor(document).extractText();
    final marker = rawText.indexOf('04-06-26');
    if (marker != -1) {
      final start = (marker - 1500 > 0) ? marker - 1500 : 0;
      final end = (marker + 1500 < rawText.length)
          ? marker + 1500
          : rawText.length;
      debugPrint('[RAW_TEXT_DUMP] ${rawText.substring(start, end)}');
    } else {
      debugPrint(
        '[RAW_TEXT_DUMP] date marker not found in extracted text at all',
      );
      debugPrint('[RAW_TEXT_DUMP] full length: ${rawText.length}');
    }
  } catch (e) {
    return _PdfParseResult(error: 'Failed to read text from PDF: $e');
  } finally {
    document.dispose();
  }

  try {
    final parsers = <BankStatementParser>[
      SbiStatementParser(),
      IdfcStatementParser(),
      SliceStatementParser(),
    ];

    BankStatementParser? matched;
    for (final p in parsers) {
      if (p.canParse(rawText)) {
        matched = p;
        break;
      }
    }

    if (matched == null) {
      return _PdfParseResult(
        error:
            'Could not identify the bank for this statement. Supported: SBI, IDFC First, Slice.',
      );
    }

    double? openingBalance;
    double? closingBalance;

    // Check if the parser supports extracting overall balances
    if (matched is SbiStatementParser) {
      final result = matched.parseStatement(rawText, payload.fileName);
      openingBalance = result.openingBalance;
      closingBalance = result.closingBalance;
    }

    final transactions = matched.parse(rawText, payload.fileName);
    final bankName = _bankNameFor(matched);

    return _PdfParseResult(
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      transactions: transactions
          .map(
            (t) => {
              'id': t.id,
              'fingerprint': t.fingerprint,
              'amount': t.amount,
              'merchant': t.merchant,
              'date': t.date.toIso8601String(),
              'type': t.type,
              'source': 'pdf',
              'body': t.body,
              'confidence': t.confidence,
              'warnings': t.warnings,
              'detectedCategory': t.detectedCategory,
              'bankName': bankName,
            },
          )
          .toList(),
    );
  } catch (e) {
    // A genuine parsing bug must surface to the user
    return _PdfParseResult(error: 'Failed to parse statement: $e');
  }
}

class PdfStatementImportService {
  static const String _savedPasswordsKey = 'saved_pdf_passwords';

  static Future<List<String>> _getSavedPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedPasswordsKey) ?? [];
  }

  static Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final passwords = prefs.getStringList(_savedPasswordsKey) ?? [];
    if (!passwords.contains(password)) {
      passwords.add(password);
      await prefs.setStringList(_savedPasswordsKey, passwords);
    }
  }

  /// Wraps compute() with a hard timeout so a stuck isolate surfaces as an error.
  static Future<_PdfParseResult> _computeWithTimeout(
    _PdfParsePayload payload,
    String stageLabel,
  ) {
    debugPrint('[PdfImport] $stageLabel: starting compute() ...');
    return compute(_parsePdfInIsolate, payload)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            debugPrint('[PdfImport] $stageLabel: TIMED OUT after 20s');
            throw TimeoutException(
              'PDF parsing timed out during "$stageLabel". The file may be too large or malformed.',
            );
          },
        )
        .then((r) {
          debugPrint(
            '[PdfImport] $stageLabel: compute() returned '
            '(txns=${r.transactions?.length}, isPasswordError=${r.isPasswordError}, error=${r.error})',
          );
          return r;
        });
  }

  static Future<StatementParseData?> pickAndParse({
    Future<String?> Function()? onPromptPassword,
  }) async {
    debugPrint('[PdfImport] Opening file picker ...');
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.single.path == null) {
      debugPrint('[PdfImport] File picker cancelled or no path.');
      return null;
    }

    debugPrint('[PdfImport] File picked: ${result.single.name}');
    final file = File(result.single.path!);
    final bytes = await file.readAsBytes();
    debugPrint('[PdfImport] Read ${bytes.length} bytes from file.');
    final fileName = result.single.name;

    final savedPasswords = await _getSavedPasswords();
    debugPrint(
      '[PdfImport] ${savedPasswords.length} saved password(s) on file.',
    );

    // 1. Try no password first, then all saved passwords, in order.
    final candidatePasswords = <String?>[null, ...savedPasswords];
    _PdfParseResult? successfulResult;
    String? parseError;

    for (final pwd in candidatePasswords) {
      final parseResult = await _computeWithTimeout(
        _PdfParsePayload(bytes, fileName, password: pwd),
        pwd == null ? 'trying no password' : 'trying saved password',
      );

      if (parseResult.transactions != null) {
        successfulResult = parseResult;
        break;
      } else if (!parseResult.isPasswordError && parseResult.error != null) {
        // Real parsing/identification failure - not a password problem.
        parseError = parseResult.error;
        break;
      }
    }

    if (parseError != null) {
      throw UnsupportedError(parseError);
    }

    // 2. If no password worked, prompt the user.
    while (successfulResult == null) {
      if (onPromptPassword == null) {
        throw ArgumentError(
          'PDF is password protected and no prompt callback was provided.',
        );
      }

      debugPrint('[PdfImport] Prompting user for password ...');
      final userPassword = await onPromptPassword();
      if (userPassword == null || userPassword.isEmpty) {
        debugPrint('[PdfImport] Password prompt cancelled by user.');
        return null; // User cancelled prompt
      }
      debugPrint('[PdfImport] Password entered, retrying parse ...');

      final parseResult = await _computeWithTimeout(
        _PdfParsePayload(bytes, fileName, password: userPassword),
        'trying user-entered password',
      );

      if (parseResult.transactions != null) {
        successfulResult = parseResult;
        await _savePassword(userPassword); // Save new working password
      } else if (!parseResult.isPasswordError && parseResult.error != null) {
        throw UnsupportedError(parseResult.error!);
      }
    }

    final rawMaps = successfulResult.transactions!;
    final transactions = rawMaps
        .map(
          (m) => DetectedTransaction(
            id: m['id'] as String,
            fingerprint: m['fingerprint'] as String,
            amount: (m['amount'] as num).toDouble(),
            merchant: m['merchant'] as String,
            date: DateTime.parse(m['date'] as String),
            type: m['type'] as String,
            source: m['source'] as String,
            body: m['body'] as String?,
            confidence: (m['confidence'] as num).toDouble(),
            warnings: List<String>.from(m['warnings'] as List),
            detectedCategory: m['detectedCategory'] as String?,
            bankName: m['bankName'] as String?,
          ),
        )
        .toList();

    return StatementParseData(
      transactions: transactions,
      openingBalance: successfulResult.openingBalance,
      closingBalance: successfulResult.closingBalance,
    );
  }
}
