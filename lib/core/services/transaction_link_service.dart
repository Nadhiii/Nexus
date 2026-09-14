import '../models/detected_transaction.dart';
import '../models/transaction.dart' as models;

/// A candidate existing transaction that a newly detected/planned transaction
/// might actually be — i.e. something the user already logged manually
/// (or detected earlier) before this new one came along.
class LinkCandidate {
  final models.Transaction transaction;
  final double confidence; // 0..1
  final List<String> reasons;

  const LinkCandidate({
    required this.transaction,
    required this.confidence,
    required this.reasons,
  });
}

/// Finds existing transactions that a new detection or a planned manual
/// payment could be linked to instead of creating a brand-new one. This is
/// deliberately more forgiving than a strict exact-match check — it
/// surfaces softer matches (amount drifted a little, description worded
/// differently, a few days apart) so the user can decide instead of
/// silently creating a duplicate.
class TransactionLinkService {
  const TransactionLinkService();

  /// Entry point for the nbox detection review flow (Scenario 1: a manual
  /// entry exists, then Nexus later detects the same real-world payment).
  List<LinkCandidate> findCandidates({
    required DetectedTransaction detected,
    required List<models.Transaction> history,
    String? subscriptionId,
    String? debtId,
    String? investmentId,
    int dateWindowDays = 5,
    double amountTolerancePct = 0.1,
    int maxResults = 3,
  }) {
    return findCandidatesForPayment(
      amount: detected.amount,
      date: detected.date,
      isIncome: detected.type.toLowerCase() == 'income',
      merchant: detected.merchant,
      history: history,
      subscriptionId: subscriptionId,
      debtId: debtId,
      investmentId: investmentId,
      dateWindowDays: dateWindowDays,
      amountTolerancePct: amountTolerancePct,
      maxResults: maxResults,
    );
  }

  /// Entry point for manual "Pay" / "Renew" flows (Scenario 2: a manual
  /// entry exists, then the user later clicks Pay/Renew for that same
  /// debt/subscription). There's no DetectedTransaction here — just a
  /// planned payment (amount, date, direction) that's about to be recorded.
  List<LinkCandidate> findCandidatesForPayment({
    required double amount,
    required DateTime date,
    required bool isIncome,
    required List<models.Transaction> history,
    String? merchant,
    String? subscriptionId,
    String? debtId,
    String? investmentId,
    int dateWindowDays = 5,
    double amountTolerancePct = 0.1,
    int maxResults = 3,
  }) {
    final direction = isIncome
        ? models.TransactionType.income
        : models.TransactionType.expense;
    final normalizedMerchant = (merchant ?? '').trim().toLowerCase();
    final merchantWords = normalizedMerchant
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    final results = <LinkCandidate>[];

    for (final tx in history) {
      // Never suggest linking to something already tied to a detection —
      // that would mean stealing a fingerprint that resolves a different
      // SMS/email.
      final alreadyLinked =
          (tx.metadata?['sourceFingerprint']?.toString() ?? '').isNotEmpty;
      if (alreadyLinked) continue;
      if (tx.type != direction) continue;

      final reasons = <String>[];
      double confidence = 0;

      // Strong signal: this transaction already belongs to the same
      // subscription/debt/investment we're currently reviewing.
      final metaSubId = tx.metadata?['subscriptionId']?.toString();
      final metaDebtId = tx.metadata?['debtId']?.toString();
      final metaInvId = tx.metadata?['investmentId']?.toString();
      final belongsToSameEntity =
          (subscriptionId != null && metaSubId == subscriptionId) ||
          (debtId != null && metaDebtId == debtId) ||
          (investmentId != null && metaInvId == investmentId);
      if (belongsToSameEntity) {
        confidence += 0.45;
        reasons.add('Already logged against the same subscription/loan');
      }

      // Amount closeness.
      final amountDiffPct = amount == 0
          ? 1.0
          : (tx.amount - amount).abs() / amount;
      if (amountDiffPct <= 0.01) {
        confidence += 0.35;
        reasons.add('Same amount');
      } else if (amountDiffPct <= amountTolerancePct) {
        confidence += 0.2;
        reasons.add('Very close amount');
      } else if (!belongsToSameEntity) {
        continue; // amount too different and no entity link — not a candidate
      }

      // Date closeness.
      final dayDiff = tx.date.difference(date).inHours.abs() / 24;
      if (dayDiff <= 1) {
        confidence += 0.15;
        reasons.add('Same day');
      } else if (dayDiff <= dateWindowDays) {
        confidence += 0.08;
        reasons.add('Within ${dateWindowDays}d');
      } else if (!belongsToSameEntity) {
        continue;
      }

      // Merchant / description overlap.
      final description = (tx.description ?? '').toLowerCase();
      final entity = (tx.metadata?['entity']?.toString() ?? '').toLowerCase();
      if (normalizedMerchant.isNotEmpty &&
          (description.contains(normalizedMerchant) ||
              entity == normalizedMerchant)) {
        confidence += 0.1;
        reasons.add('Matching description');
      } else if (merchantWords.isNotEmpty) {
        final hit = merchantWords.any(
          (w) => description.contains(w) || entity.contains(w),
        );
        if (hit) {
          confidence += 0.05;
          reasons.add('Partial description match');
        }
      }

      if (confidence <= 0) continue;
      results.add(
        LinkCandidate(
          transaction: tx,
          confidence: confidence.clamp(0.0, 1.0),
          reasons: reasons,
        ),
      );
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(maxResults).toList();
  }
}
