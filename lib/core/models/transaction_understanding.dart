import 'detected_transaction.dart';
import '../services/transaction_intent_classifier.dart';

class TransactionUnderstanding {
  final DetectedTransaction source;
  final String? entity;
  final String? categoryId;
  final String purpose;
  final String? specialIntent;
  final TransactionIntent intent;
  final String counterpartyRole;
  final String? accountId;
  final String? destinationAccountId;
  final bool isTransfer;
  final bool isRecurring;
  final bool isRefund;
  final bool isPaymentFromCompany;
  final List<String> relatedTransactionIds;
  final List<String> relatedDetectionIds;
  final List<String> duplicateTransactionIds;
  final double? usualAmount;
  final double? amountDeviationRatio;
  final bool knowledgeConflict;
  final List<String> observations;
  final List<String> reasons;
  final Map<String, double> confidence;

  const TransactionUnderstanding({
    required this.source,
    this.entity,
    this.categoryId,
    this.purpose = 'unknown',
    this.specialIntent,
    this.intent = TransactionIntent.general,
    this.counterpartyRole = 'unknown',
    this.accountId,
    this.destinationAccountId,
    this.isTransfer = false,
    this.isRecurring = false,
    this.isRefund = false,
    this.isPaymentFromCompany = false,
    this.relatedTransactionIds = const [],
    this.relatedDetectionIds = const [],
    this.duplicateTransactionIds = const [],
    this.usualAmount,
    this.amountDeviationRatio,
    this.knowledgeConflict = false,
    this.observations = const [],
    this.reasons = const [],
    this.confidence = const {},
  });

  double confidenceFor(String field) => confidence[field] ?? 0.0;

  bool get canAutoRecord {
    if (duplicateTransactionIds.isNotEmpty || knowledgeConflict) return false;
    if (confidenceFor('entity') < 0.90 ||
        confidenceFor('purpose') < 0.90 ||
        confidenceFor('account') < 0.90) {
      return false;
    }
    if (isTransfer && confidenceFor('destination') < 0.90) return false;
    return true;
  }

  bool get needsReview => !canAutoRecord;
}
