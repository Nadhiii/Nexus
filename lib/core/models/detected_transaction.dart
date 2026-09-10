import 'package:flutter/foundation.dart';

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

  /// Check if transaction can be auto-approved (no review needed)
  /// Threshold: All critical fields must be > 0.95 confidence
  bool get canAutoApprove => 
      merchant >= 0.95 && 
      amount >= 0.98 && 
      category >= 0.90 &&
      duplicate >= 0.95;

  /// Check if transaction needs human review
  bool get needsReview => 
      merchant < 0.70 || 
      amount < 0.80 || 
      category < 0.60 ||
      duplicate < 0.85;

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

@immutable
class DetectedTransaction {
  final String id; // Unique ID (SMS ID or Email ID)
  final double amount;
  final String merchant;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String source; // 'sms' or 'email'
  final String? body; // Full SMS or Email body
  final String? accountId; // Detected account ID (if known)
  final TransactionConfidence confidence; // Granular confidence scores
  final List<String> warnings; // e.g., ["Merchant unclear", "Amount incomplete"]
  final String? detectedCategory; // Auto-detected category, if any
  final bool isRecurring; // Whether this appears to be recurring
  final String? recurrencePattern; // e.g., "monthly", "weekly"
  final KnowledgeType knowledgeType; // How was this determined
  final List<String> matchedPatterns; // IDs of patterns/merchants that matched

  const DetectedTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.source,
    this.body,
    this.accountId,
    this.confidence = const TransactionConfidence(),
    this.warnings = const [],
    this.detectedCategory,
    this.isRecurring = false,
    this.recurrencePattern,
    this.knowledgeType = KnowledgeType.observed,
    this.matchedPatterns = const [],
  });

  // Quick check for reliability (legacy - use confidence fields directly now)
  bool get isHighConfidence => confidence.overall >= 0.85;
  bool get isLowConfidence => confidence.overall < 0.65;
  
  /// Should this transaction bypass the Smart Approval screen?
  bool get shouldAutoApprove => confidence.canAutoApprove && warnings.isEmpty;
  
  /// Does this need human review?
  bool get needsReview => confidence.needsReview || warnings.isNotEmpty;
  
  /// What specific question should we ask the user?
  String? get questionToAsk => confidence.weakestArea;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          source == other.source;

  @override
  int get hashCode => id.hashCode ^ source.hashCode;

  DetectedTransaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    DateTime? date,
    String? type,
    String? source,
    String? body,
    String? accountId,
    TransactionConfidence? confidence,
    List<String>? warnings,
    String? detectedCategory,
    bool? isRecurring,
    String? recurrencePattern,
    KnowledgeType? knowledgeType,
    List<String>? matchedPatterns,
  }) {
    return DetectedTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      type: type ?? this.type,
      source: source ?? this.source,
      body: body ?? this.body,
      accountId: accountId ?? this.accountId,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      detectedCategory: detectedCategory ?? this.detectedCategory,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      matchedPatterns: matchedPatterns ?? this.matchedPatterns,
    );
  }
}

/// How did Nexus learn this information?
enum KnowledgeType {
  explicit,    // User explicitly told Nexus (highest authority)
  observed,    // Nexus observed pattern from multiple transactions
  inferred,    // Nexus inferred from context/rules (lower confidence)
  unknown,     // No prior knowledge
}
