import 'detected_transaction.dart';
import 'transaction.dart';

/// Canonical editable candidate shared by imported, detected, and manual flows.
/// It deliberately keeps detection evidence separate from the eventual ledger
/// identity: [sourceFingerprint] is an idempotency key, never a document ID.
class TransactionDraft {
  final String? ledgerId;
  final String? sourceId;
  final String? source;
  final String? sourceFingerprint;
  final double amount;
  final String description;
  final DateTime date;
  final TransactionType type;
  final String? categoryId;
  final String accountId;
  final String? destinationAccountId;
  final double confidence;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const TransactionDraft({
    this.ledgerId,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.accountId,
    this.sourceId,
    this.source,
    this.sourceFingerprint,
    this.categoryId,
    this.destinationAccountId,
    this.confidence = 1,
    this.warnings = const [],
    this.metadata = const {},
  });

  factory TransactionDraft.fromTransaction(Transaction transaction) {
    final metadata = transaction.metadata ?? const <String, dynamic>{};
    return TransactionDraft(
      ledgerId: transaction.id.isEmpty ? null : transaction.id,
      sourceId: metadata['sourceId']?.toString(),
      source: metadata['source']?.toString(),
      sourceFingerprint: metadata['sourceFingerprint']?.toString(),
      amount: transaction.amount,
      description: transaction.description?.trim().isNotEmpty == true
          ? transaction.description!.trim()
          : 'Transaction',
      date: transaction.date,
      type: transaction.type,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      destinationAccountId: transaction.toAccountId,
      confidence: (metadata['confidence'] as num?)?.toDouble() ?? 1,
      warnings: (metadata['warnings'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      metadata: metadata,
    );
  }

  factory TransactionDraft.fromDetected(
    DetectedTransaction detected, {
    required String accountId,
    String? categoryId,
    String? destinationAccountId,
  }) => TransactionDraft(
    sourceId: detected.id,
    source: detected.source,
    sourceFingerprint: detected.fingerprint,
    amount: detected.amount,
    description: detected.merchant,
    date: detected.date,
    type: detected.type.toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    categoryId: categoryId ?? detected.detectedCategory,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    confidence: detected.confidence,
    warnings: detected.warnings,
    metadata: {
      if (detected.body != null) 'sourceBody': detected.body,
      if (detected.bankName != null) 'bankName': detected.bankName,
    },
  );

  Transaction toTransaction({required String userId, String id = ''}) {
    final now = DateTime.now();
    return Transaction(
      id: id.isNotEmpty ? id : (ledgerId ?? ''),
      userId: userId,
      type: type,
      amount: amount,
      description: description,
      categoryId: categoryId,
      accountId: accountId,
      toAccountId: destinationAccountId,
      date: date,
      metadata: {
        ...metadata,
        if (source != null) 'source': source,
        if (sourceId != null) 'sourceId': sourceId,
        if (sourceFingerprint != null) 'sourceFingerprint': sourceFingerprint,
        'confidence': confidence,
        'warnings': warnings,
      },
      createdAt: now,
      updatedAt: now,
    );
  }
}
