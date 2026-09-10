import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/core/models/detected_transaction.dart';
import 'package:nexus/core/models/transaction_understanding.dart';
import 'package:nexus/core/models/transaction.dart';
import 'package:nexus/core/models/transaction_draft.dart';

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
}
