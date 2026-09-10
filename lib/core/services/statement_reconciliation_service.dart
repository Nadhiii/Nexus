import '../models/detected_transaction.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';

class MatchedPair {
  final DetectedTransaction statementTransaction;
  final Transaction existingTransaction;
  const MatchedPair(this.statementTransaction, this.existingTransaction);
}

class AmbiguousMatch {
  final DetectedTransaction statementTransaction;
  final List<Transaction> candidates;
  const AmbiguousMatch(this.statementTransaction, this.candidates);
}

class ReconciliationResult {
  final List<DetectedTransaction> inserted;
  final List<MatchedPair> confirmed;
  final List<AmbiguousMatch> needsReview;
  final Transaction? adjustment;
  final bool alreadyReconciled;
  const ReconciliationResult({
    this.inserted = const [],
    this.confirmed = const [],
    this.needsReview = const [],
    this.adjustment,
    this.alreadyReconciled = false,
  });
}

class StatementReconciliationService {
  const StatementReconciliationService();

  ReconciliationResult reconcile({
    required List<DetectedTransaction> statementTransactions,
    required List<Transaction> existingTransactions,
    required String accountId,
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double closingBalance,
    required double openingBalance,
    DateTime? closingDate,
    bool alreadyReconciled = false,
    double epsilon = 0.01,
  }) {
    if (alreadyReconciled) {
      return const ReconciliationResult(alreadyReconciled: true);
    }

    final used = <String>{};
    final inserted = <DetectedTransaction>[];
    final confirmed = <MatchedPair>[];
    final review = <AmbiguousMatch>[];

    for (final statement in statementTransactions) {
      final candidates = existingTransactions.where((t) {
        final days = t.date.difference(statement.date).inHours.abs() / 24;
        final direction = statement.type.toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        return t.accountId == accountId &&
            t.amount == statement.amount &&
            days <= 1 &&
            t.type == direction &&
            !used.contains(t.id);
      }).toList();

      if (candidates.length == 1) {
        used.add(candidates.single.id);
        confirmed.add(MatchedPair(statement, candidates.single));
      } else if (candidates.length > 1) {
        used.addAll(candidates.map((c) => c.id));
        review.add(AmbiguousMatch(statement, candidates));
      } else {
        inserted.add(statement.copyWith(source: 'statement_import'));
      }
    }

    final all = [
      ...existingTransactions,
      ...inserted.map((d) => _asTransaction(d, accountId, userId)),
    ];

    final computed = all
        .where((t) => !t.date.isAfter(closingDate ?? periodEnd))
        .fold<double>(openingBalance, (sum, t) {
          switch (t.type) {
            case TransactionType.income:
              return sum + t.amount;
            case TransactionType.expense:
              return sum - t.amount;
            case TransactionType.adjustment:
              return sum + t.amount; // signed value, see _buildAdjustment below
            default:
              return sum;
          }
        });

    final gap = closingBalance - computed;
    Transaction? adjustment;
    if (gap.abs() > epsilon) {
      adjustment = _buildAdjustment(
        gap: gap,
        closingBalance: closingBalance,
        accountId: accountId,
        userId: userId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        date: closingDate ?? periodEnd,
      );
    }

    return ReconciliationResult(
      inserted: inserted,
      confirmed: confirmed,
      needsReview: review,
      adjustment: adjustment,
    );
  }

  Transaction _buildAdjustment({
    required double gap,
    required double closingBalance,
    required String accountId,
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime date,
  }) {
    return Transaction(
      id: '',
      userId: userId,
      type: TransactionType.adjustment,
      amount: gap,
      description:
          'Reconciliation adjustment — closing balance ₹${closingBalance.toStringAsFixed(2)}',
      accountId: accountId,
      date: date,
      metadata: {
        'source': 'statement_reconciliation',
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      },
      createdAt: date,
      updatedAt: date,
    );
  }

  Transaction _asTransaction(
    DetectedTransaction d,
    String accountId,
    String userId,
  ) => TransactionDraft.fromDetected(d, accountId: accountId).toTransaction(
    userId: userId,
  );
}
