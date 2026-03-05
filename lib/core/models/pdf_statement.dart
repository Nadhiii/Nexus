// ignore_for_file: avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a transaction extracted from a PDF statement
class ExtractedTransaction {
  final String date; // YYYY-MM-DD
  final String description; // Merchant/Description
  final double amount; // Always positive
  final double? balance; // Account balance after transaction
  final String type; // 'debit', 'credit', 'expense', 'income'
  final int lineNumber; // Position in PDF for reference
  final String? merchantName; // Extracted merchant name (optional)

  /// Unique signature for duplicate detection
  String get signature {
    return '${date}_${amount.toStringAsFixed(2)}_${description.toLowerCase().trim()}';
  }

  ExtractedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    this.balance,
    required this.type,
    this.lineNumber = 0,
    this.merchantName,
  });

  factory ExtractedTransaction.fromMap(Map<String, dynamic> data) {
    return ExtractedTransaction(
      date: data['date'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      balance: data['balance']?.toDouble(),
      type: data['type'] ?? 'debit',
      lineNumber: data['lineNumber'] ?? 0,
      merchantName: data['merchantName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'description': description,
      'amount': amount,
      'balance': balance,
      'type': type,
      'lineNumber': lineNumber,
      'merchantName': merchantName,
    };
  }
}

/// Metadata extracted from PDF statement
class PDFStatementMetadata {
  final String? bankName; // Detected bank (SBI, HDFC, etc)
  final String? accountNumber; // From statement header
  final String? accountHolder; // Account owner name
  final String? accountType; // Savings, Current, etc
  final DateTime? statementPeriodStart;
  final DateTime? statementPeriodEnd;
  final double? openingBalance;
  final double? closingBalance;

  PDFStatementMetadata({
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.accountType,
    this.statementPeriodStart,
    this.statementPeriodEnd,
    this.openingBalance,
    this.closingBalance,
  });

  factory PDFStatementMetadata.fromMap(Map<String, dynamic> data) {
    return PDFStatementMetadata(
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      accountHolder: data['accountHolder'],
      accountType: data['accountType'],
      statementPeriodStart: data['statementPeriodStart'] is Timestamp
          ? (data['statementPeriodStart'] as Timestamp).toDate()
          : (data['statementPeriodStart'] is String
                ? DateTime.tryParse(data['statementPeriodStart'])
                : null),
      statementPeriodEnd: data['statementPeriodEnd'] is Timestamp
          ? (data['statementPeriodEnd'] as Timestamp).toDate()
          : (data['statementPeriodEnd'] is String
                ? DateTime.tryParse(data['statementPeriodEnd'])
                : null),
      openingBalance: data['openingBalance']?.toDouble(),
      closingBalance: data['closingBalance']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'accountType': accountType,
      'statementPeriodStart': statementPeriodStart?.toIso8601String(),
      'statementPeriodEnd': statementPeriodEnd?.toIso8601String(),
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
    };
  }
}

/// Complete PDF statement with extracted data
class PDFStatement {
  final String id; // Unique per statement
  final String filePath; // Local or cached path
  final PDFStatementMetadata metadata;
  final List<ExtractedTransaction> transactions;
  final DateTime uploadedAt;
  final String? fileHash; // For duplicate file detection

  /// Total transactions in this statement
  int get transactionCount => transactions.length;

  /// Count of income and expense transactions
  int get incomeCount =>
      transactions.where((t) => _isIncomeType(t.type)).length;
  int get expenseCount =>
      transactions.where((t) => _isExpenseType(t.type)).length;

  /// Totals for income and expense amounts
  double get incomeTotal => transactions
      .where((t) => _isIncomeType(t.type))
      .fold(0.0, (sum, t) => sum + (t.amount.abs()));
  double get expenseTotal => transactions
      .where((t) => _isExpenseType(t.type))
      .fold(0.0, (sum, t) => sum + (t.amount.abs()));

  /// Date range covered
  String get dateRange {
    if (metadata.statementPeriodStart == null ||
        metadata.statementPeriodEnd == null) {
      return 'Unknown Period';
    }
    return '${metadata.statementPeriodStart!.toIso8601String().split('T')[0]} to ${metadata.statementPeriodEnd!.toIso8601String().split('T')[0]}';
  }

  /// Helpers to interpret transaction type strings
  bool _isIncomeType(String type) {
    final t = type.toLowerCase();
    return t.contains('income') || t.contains('credit') || t == 'cr';
  }

  bool _isExpenseType(String type) {
    final t = type.toLowerCase();
    return t.contains('expense') || t.contains('debit') || t == 'dr';
  }

  PDFStatement({
    required this.id,
    required this.filePath,
    required this.metadata,
    required this.transactions,
    required this.uploadedAt,
    this.fileHash,
  });

  factory PDFStatement.fromMap(Map<String, dynamic> data) {
    return PDFStatement(
      id: data['id'] ?? '',
      filePath: data['filePath'] ?? '',
      metadata: PDFStatementMetadata.fromMap(data['metadata'] ?? {}),
      transactions:
          (data['transactions'] as List?)
              ?.map((t) => ExtractedTransaction.fromMap(t))
              .toList() ??
          [],
      uploadedAt: data['uploadedAt'] is Timestamp
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['uploadedAt'] ?? '') ?? DateTime.now(),
      fileHash: data['fileHash'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'metadata': metadata.toMap(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileHash': fileHash,
    };
  }
}

/// Result of PDF parsing with status and errors
class PDFParseResult {
  final bool success;
  final PDFStatement? statement;
  final List<String> errors; // Parse errors
  final List<String> warnings; // Non-critical issues
  final String? detectedBank;
  final bool requiresManualBankSelection;
  final bool requiresPassword; // PDF is password-protected
  final bool usedPassword; // Password was used to unlock

  PDFParseResult({
    required this.success,
    this.statement,
    this.errors = const [],
    this.warnings = const [],
    this.detectedBank,
    this.requiresManualBankSelection = false,
    this.requiresPassword = false,
    this.usedPassword = false,
  });
}

/// Import progress during bulk operation
class PDFImportProgress {
  final int totalTransactions;
  final int processedTransactions;
  final int successfulImports;
  final int duplicateSkipped;
  final int errorCount;
  final String currentStatus;
  final double percentComplete;

  PDFImportProgress({
    required this.totalTransactions,
    required this.processedTransactions,
    required this.successfulImports,
    required this.duplicateSkipped,
    required this.errorCount,
    required this.currentStatus,
    required this.percentComplete,
  });
}

/// Duplicate detection result
class DuplicateCheckResult {
  final bool isDuplicate;
  final String? matchingTransactionId; // If duplicate found
  final double confidenceScore; // 0-100
  final String reason; // Why it's a duplicate
  final List<String> matchingFields; // Which fields matched
  final bool needsTypeUpdate; // If duplicate has wrong transaction type

  DuplicateCheckResult({
    required this.isDuplicate,
    this.matchingTransactionId,
    required this.confidenceScore,
    required this.reason,
    this.matchingFields = const [],
    this.needsTypeUpdate = false,
  });
}
