import 'package:flutter/foundation.dart';

<<<<<<< Updated upstream
=======
/// Granular confidence scores for different aspects of a transaction
/// This allows Nexus to be certain about some fields while uncertain about others
@immutable
class TransactionConfidence {
  final double overall; // Legacy: weighted average for backward compatibility
  final double merchant; // Confidence in merchant/entity identification
  final double amount; // Confidence in amount extraction
  final double account; // Confidence in which account was used
  final double category; // Confidence in category classification
  final double recurring; // Confidence this is a recurring transaction
  final double duplicate; // Confidence this is not a duplicate

  const TransactionConfidence({
    this.overall = 0.8,
    this.merchant = 0.8,
    this.amount = 0.9,
    this.account = 0.7,
    this.category = 0.75,
    this.recurring = 0.5,
    this.duplicate = 0.95,
  });

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'merchant': merchant,
    'amount': amount,
    'account': account,
    'category': category,
    'recurring': recurring,
    'duplicate': duplicate,
  };

  /// Check if transaction can be auto-approved (no review needed)
  /// Threshold: All critical fields must be > 0.95 confidence
  bool get canAutoApprove =>
      merchant >= 0.95 &&
      amount >= 0.98 &&
      category >= 0.90 &&
      duplicate >= 0.95;

  /// Check if transaction needs human review
  bool get needsReview =>
      merchant < 0.70 || amount < 0.80 || category < 0.60 || duplicate < 0.85;

  /// Get the weakest confidence area (what to ask user about)
  String? get weakestArea {
    final areas = [
      ('merchant', merchant),
      ('amount', amount),
      ('account', account),
      ('category', category),
      ('recurring', recurring),
    ];
    areas.sort((a, b) => a.$2.compareTo(b.$2));
    return areas.first.$2 < 0.85 ? areas.first.$1 : null;
  }

  TransactionConfidence copyWith({
    double? overall,
    double? merchant,
    double? amount,
    double? account,
    double? category,
    double? recurring,
    double? duplicate,
  }) {
    return TransactionConfidence(
      overall: overall ?? this.overall,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      account: account ?? this.account,
      category: category ?? this.category,
      recurring: recurring ?? this.recurring,
      duplicate: duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return 'TransactionConfidence(overall: ${overall.toStringAsFixed(2)}, '
        'merchant: ${merchant.toStringAsFixed(2)}, '
        'category: ${category.toStringAsFixed(2)}, '
        'canAutoApprove: $canAutoApprove)';
  }
}

>>>>>>> Stashed changes
@immutable
class DetectedTransaction {
  final String id; // Unique ID (SMS ID or Email ID)
  final String fingerprint; // Content-based hash, survives reinstall
  final double amount;
  final String merchant;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String source; // 'sms' or 'email'
  final String? body; // Full SMS or Email body
<<<<<<< Updated upstream
  final double confidence; // 0.0 to 1.0, higher = more reliable
  final List<String>
  warnings; // e.g., ["Merchant unclear", "Amount incomplete"]
  final String? detectedCategory; // Auto-detected category, if any
=======
  final String? accountId; // Detected account ID (if known)
  final TransactionConfidence confidence; // Granular confidence scores
  final List<String>
  warnings; // e.g., ["Merchant unclear", "Amount incomplete"]
  final String? detectedCategory; // Auto-detected category, if any

  final bool isRecurring; // Whether this appears to be recurring
  final String? recurrencePattern; // e.g., "monthly", "weekly"
  final KnowledgeType knowledgeType; // How was this determined
  final List<String> matchedPatterns; // IDs of patterns/merchants that matched
>>>>>>> Stashed changes
  final String? bankName; // e.g., "IDFC FIRST Bank" - identified source bank
  final double?
  balanceAfter; // Account balance after this transaction, if the alert included one
  final String? accountNumber; // Last-4 digits of account/card, if present
  final Map<String, dynamic>? analysis; // Latest interpretation/evidence
  final String? matchedTransactionId;
  final String? statementImportId;

  DetectedTransaction({
    required this.id,
    required this.fingerprint,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.source,
    this.body,
<<<<<<< Updated upstream
    this.confidence = 0.8,
    this.warnings = const [],
    this.detectedCategory,
=======
    this.accountId,
    Object confidence = const TransactionConfidence(),
    this.warnings = const [],
    this.detectedCategory,

    this.isRecurring = false,
    this.recurrencePattern,
    this.knowledgeType = KnowledgeType.unknown,
    this.matchedPatterns = const [],
>>>>>>> Stashed changes
    this.bankName,
    this.balanceAfter,
    this.accountNumber,
    this.analysis,
    this.matchedTransactionId,
    this.statementImportId,
<<<<<<< Updated upstream
  });

  // Quick check for reliability
  bool get isHighConfidence => confidence >= 0.85;
  bool get isLowConfidence => confidence < 0.65;
  bool get needsReview => isLowConfidence || warnings.isNotEmpty;
=======
  }) : confidence = _coerceConfidence(confidence);

  static TransactionConfidence _coerceConfidence(Object? value) {
    if (value is TransactionConfidence) return value;
    if (value is num) {
      final score = value.toDouble();
      return TransactionConfidence(
        overall: score,
        merchant: score,
        amount: score,
        account: score,
        category: score,
      );
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      double read(String key, double fallback) =>
          (map[key] as num?)?.toDouble() ?? fallback;
      return TransactionConfidence(
        overall: read('overall', 0.8),
        merchant: read('merchant', 0.8),
        amount: read('amount', 0.9),
        account: read('account', 0.7),
        category: read('category', 0.75),
        recurring: read('recurring', 0.5),
        duplicate: read('duplicate', 0.95),
      );
    }
    return const TransactionConfidence();
  }

  // Quick check for reliability (legacy - use confidence fields directly now)
  bool get isHighConfidence => confidence.overall >= 0.85;
  bool get isLowConfidence => confidence.overall < 0.65;

  /// Should this transaction bypass the Smart Approval screen?
  bool get shouldAutoApprove => confidence.canAutoApprove && warnings.isEmpty;

  /// Does this need human review?
  bool get needsReview => confidence.needsReview || warnings.isNotEmpty;

  /// What specific question should we ask the user?
  String? get questionToAsk => confidence.weakestArea;
>>>>>>> Stashed changes

  Map<String, dynamic> toJson() => {
    'id': id,
    'fingerprint': fingerprint,
    'amount': amount,
    'merchant': merchant,
    'date': date.toIso8601String(),
    'type': type,
    'source': source,
    'body': body,
    'accountId': accountId,
    'confidence': confidence.toJson(),
    'warnings': warnings,
    'detectedCategory': detectedCategory,
    'isRecurring': isRecurring,
    'recurrencePattern': recurrencePattern,
    'knowledgeType': knowledgeType.name,
    'matchedPatterns': matchedPatterns,
    'bankName': bankName,
    'balanceAfter': balanceAfter,
    'accountNumber': accountNumber,
    'analysis': analysis,
    'matchedTransactionId': matchedTransactionId,
    'statementImportId': statementImportId,
  };

  factory DetectedTransaction.fromJson(Map<String, dynamic> json) {
    return DetectedTransaction(
      id: json['id'] as String,
      fingerprint: json['fingerprint'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      source: json['source'] as String,
      body: json['body'] as String?,
      accountId: json['accountId'] as String?,
      confidence: json['confidence'] ?? 0.8,
      warnings: List<String>.from(json['warnings'] as List? ?? const []),
      detectedCategory: json['detectedCategory'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] as String?,
      knowledgeType: KnowledgeType.values.firstWhere(
        (value) => value.name == json['knowledgeType']?.toString(),
        orElse: () => KnowledgeType.unknown,
      ),
      matchedPatterns: List<String>.from(
        json['matchedPatterns'] as List? ?? const [],
      ),
      bankName: json['bankName'] as String?,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      accountNumber: json['accountNumber'] as String?,
      analysis: json['analysis'] != null
          ? Map<String, dynamic>.from(json['analysis'] as Map)
          : null,
      matchedTransactionId: json['matchedTransactionId'] as String?,
      statementImportId: json['statementImportId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedTransaction &&
          runtimeType == other.runtimeType &&
          fingerprint == other.fingerprint &&
          source == other.source;

  @override
  int get hashCode => fingerprint.hashCode ^ source.hashCode;

  DetectedTransaction copyWith({
    String? id,
    String? fingerprint,
    double? amount,
    String? merchant,
    DateTime? date,
    String? type,
    String? source,
    String? body,
<<<<<<< Updated upstream
    double? confidence,
=======
    String? accountId,
    Object? confidence,
>>>>>>> Stashed changes
    List<String>? warnings,
    String? detectedCategory,
    String? bankName,
    double? balanceAfter,
    String? accountNumber,
    Map<String, dynamic>? analysis,
    String? matchedTransactionId,
    String? statementImportId,
  }) {
    return DetectedTransaction(
      id: id ?? this.id,
      fingerprint: fingerprint ?? this.fingerprint,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      type: type ?? this.type,
      source: source ?? this.source,
      body: body ?? this.body,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      detectedCategory: detectedCategory ?? this.detectedCategory,
<<<<<<< Updated upstream
=======

      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      matchedPatterns: matchedPatterns ?? this.matchedPatterns,
>>>>>>> Stashed changes
      bankName: bankName ?? this.bankName,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      accountNumber: accountNumber ?? this.accountNumber,
      analysis: analysis ?? this.analysis,
      matchedTransactionId: matchedTransactionId ?? this.matchedTransactionId,
      statementImportId: statementImportId ?? this.statementImportId,
    );
  }
}
<<<<<<< Updated upstream
=======

/// How did Nexus learn this information?
enum KnowledgeType {
  explicit, // User explicitly told Nexus (highest authority)
  observed, // Nexus observed pattern from multiple transactions
  inferred, // Nexus inferred from context/rules (lower confidence)
  unknown, // No prior knowledge
}
>>>>>>> Stashed changes
