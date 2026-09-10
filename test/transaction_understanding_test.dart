import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/core/models/detected_transaction.dart';
import 'package:nexus/core/models/transaction_understanding.dart';
import 'package:nexus/core/models/transaction.dart';
import 'package:nexus/core/models/transaction_draft.dart';
import 'package:nexus/core/services/transaction_router.dart';

DetectedTransaction _detected() => DetectedTransaction(
      id: 'source-1',
      fingerprint: 'fingerprint-1',
      amount: 2000,
      merchant: 'Example Merchant',
      date: DateTime(2026, 1, 1),
      type: 'expense',
      source: 'sms',
    );

void main() {
  test('transaction JSON accepts numeric and string type representations', () {
    final base = <String, dynamic>{
      'id': 'tx-1',
      'userId': 'user-1',
      'amount': 120.5,
      'accountId': 'account-1',
      'date': '2026-01-01T10:00:00.000Z',
      'createdAt': '2026-01-01T10:00:00.000Z',
      'updatedAt': '2026-01-01T10:00:00.000Z',
    };

    expect(Transaction.fromJson({...base, 'type': 1}).type,
        TransactionType.expense);
    expect(Transaction.fromJson({...base, 'type': 'income'}).type,
        TransactionType.income);
  });

  test('high-confidence, fully resolved events can be auto-recorded', () {
    final understanding = TransactionUnderstanding(
      source: _detected(),
      entity: 'example merchant',
      categoryId: 'shopping',
      accountId: 'account-1',
      confidence: const {
        'entity': 0.95,
        'purpose': 0.92,
        'account': 0.96,
      },
    );

    expect(understanding.canAutoRecord, isTrue);
    expect(understanding.needsReview, isFalse);
  });

  test('duplicates and unresolved transfers always remain reviewable', () {
    final duplicate = TransactionUnderstanding(
      source: _detected(),
      confidence: const {'entity': 1.0, 'purpose': 1.0, 'account': 1.0},
      duplicateTransactionIds: const ['existing-1'],
    );
    final unresolvedTransfer = TransactionUnderstanding(
      source: _detected(),
      isTransfer: true,
      confidence: const {
        'entity': 1.0,
        'purpose': 1.0,
        'account': 1.0,
        'destination': 0.0,
      },
    );

    expect(duplicate.needsReview, isTrue);
    expect(unresolvedTransfer.canAutoRecord, isFalse);
  });

  test('draft keeps source identity separate from ledger identity', () {
    final transaction = TransactionDraft.fromDetected(
      _detected(),
      accountId: 'account-1',
    ).toTransaction(userId: 'user-1');

    expect(transaction.id, isEmpty);
    expect(transaction.metadata?['sourceId'], 'source-1');
    expect(transaction.metadata?['sourceFingerprint'], 'fingerprint-1');
  });

  test('detected transaction JSON round-trips all detection fields', () {
    final original = DetectedTransaction(
      id: 'email-1',
      fingerprint: 'fingerprint-1',
      amount: 321.45,
      merchant: 'Example Merchant',
      date: DateTime.utc(2026, 1, 2, 3, 4),
      type: 'expense',
      source: 'email',
      body: 'paid ₹321.45',
      accountId: 'account-1',
      confidence: const TransactionConfidence(
        overall: 0.91,
        merchant: 0.92,
        amount: 0.93,
        account: 0.94,
        category: 0.95,
        recurring: 0.96,
        duplicate: 0.97,
      ),
      warnings: const ['check account'],
      detectedCategory: 'shopping',
      isRecurring: true,
      recurrencePattern: 'monthly',
      knowledgeType: KnowledgeType.observed,
      matchedPatterns: const ['merchant-1'],
      bankName: 'Example Bank',
      balanceAfter: 1000.5,
      accountNumber: '1234',
      analysis: const {'reason': 'matched'},
      matchedTransactionId: 'tx-existing',
      statementImportId: 'statement-1',
    );

    final restored = DetectedTransaction.fromJson(original.toJson());
    expect(restored.toJson(), original.toJson());
  });

  test('draft carries structured detection evidence', () {
    final detected = _detected().copyWith(
      accountId: 'detected-account',
      isRecurring: true,
      recurrencePattern: 'weekly',
      knowledgeType: KnowledgeType.inferred,
      matchedPatterns: const ['pattern-1'],
      analysis: const {'source': 'parser'},
    );
    final draft = TransactionDraft.fromDetected(
      detected,
      accountId: 'selected-account',
    );
    final evidence = draft.metadata['detectionEvidence'] as Map;

    expect(evidence['accountId'], 'detected-account');
    expect(evidence['isRecurring'], isTrue);
    expect(evidence['knowledgeType'], 'inferred');
    expect(evidence['matchedPatterns'], ['pattern-1']);
    expect(evidence['analysis'], {'source': 'parser'});
  });

  test('simple approval builds the same canonical draft with evidence', () {
    final plan = TransactionRouter.buildSimplePlan(
      detected: _detected().copyWith(
        analysis: const {'parser': 'sms'},
        matchedPatterns: const ['merchant-pattern'],
      ),
      accountId: 'account-1',
      categoryId: 'shopping',
    );

    expect(plan.sideEffects, isEmpty);
    expect(plan.draft.categoryId, 'shopping');
    expect(plan.draft.sourceFingerprint, 'fingerprint-1');
    expect(
      (plan.draft.metadata['detectionEvidence'] as Map)['analysis'],
      {'parser': 'sms'},
    );
  });
}
