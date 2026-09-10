import '../models/detected_transaction.dart';
import '../models/knowledge_entry.dart';
import '../models/transaction.dart';
import '../models/transaction_understanding.dart';
import 'transaction_intent_classifier.dart';

/// Deterministic financial interpretation built from the user's own history
/// and Knowledge. It does not write data.
class TransactionIntelligenceService {
  const TransactionIntelligenceService();

  static const _merchantSeeds = <String, String>{
    'zomato': 'food', 'swiggy': 'food', 'uber': 'transport', 'ola': 'transport',
    'amazon': 'shopping', 'flipkart': 'shopping', 'myntra': 'shopping',
    'bigbasket': 'groceries', 'blinkit': 'groceries', 'zepto': 'groceries',
    'netflix': 'entertainment', 'spotify': 'entertainment',
    'apollo': 'health', 'medplus': 'health', 'pharmeasy': 'health',
    'hpcl': 'garage', 'bpcl': 'garage', 'iocl': 'garage',
    'groww': 'investment', 'zerodha': 'investment', 'upstox': 'investment',
    'phonepe': 'upi_p2p', 'google pay': 'upi_p2p', 'gpay': 'upi_p2p', 'paytm': 'upi_p2p',
  };

  static const _keywordSeeds = <String, String>{
    'rent': 'rent', 'landlord': 'rent', 'salary': 'salary', 'payroll': 'salary',
    'neft': 'transfer', 'imps': 'transfer', 'rtgs': 'transfer', 'upi transfer': 'transfer',
    'paid to': 'upi_p2p', 'sent to': 'upi_p2p', 'received from': 'upi_p2p',
    'emi': 'bills', 'credit card bill': 'bills', 'electricity': 'bills',
    'sip': 'investment', 'mutual fund': 'investment', 'donation': 'donation',
    'petrol': 'garage', 'diesel': 'garage', 'restaurant': 'food', 'grocery': 'groceries',
    'cab': 'transport', 'flight': 'travel', 'movie': 'entertainment', 'pharmacy': 'health',
  };

  TransactionUnderstanding analyze({
    required DetectedTransaction detected,
    required List<Transaction> history,
    required List<KnowledgeEntry> knowledge,
    String? accountId,
    String? destinationAccountId,
    List<DetectedTransaction> peerDetections = const [],
  }) {
    final rawText = '${detected.merchant} ${detected.body ?? ''}';
    final text = rawText.toLowerCase();
    final entity = _normalizeEntity(detected.merchant);
    final reasons = <String>[];
    final observations = <String>[];

    String? categoryId;
    String purpose = 'unknown';
    String? specialIntent;
    String counterpartyRole = 'unknown';
    double purposeConfidence = 0;
    final transferPeer = _findTransferPeer(detected, peerDetections);
    bool isTransfer = transferPeer != null || _containsAny(text, const [
      'transfer', 'fund transfer', 'self transfer', 'transferred to',
      'transferred from', 'imps', 'neft', 'rtgs', 'upi transfer',
    ]);
    bool isRefund = _containsAny(text, const [
      'refund', 'refunded', 'reversal', 'reversed', 'cashback',
    ]);
    bool isCompanyPayment = detected.type.toLowerCase() == 'income' &&
        _containsAny(text, const ['credited by', 'salary', 'payroll', 'employer']);

    final matchingKnowledge = knowledge.where((entry) {
      if (!entry.active) return false;
      final subject = _normalizeEntity(entry.subject);
      return subject == entity || (entity.isNotEmpty && subject.contains(entity));
    }).toList();

    final contextual = matchingKnowledge.where((e) => e.kind == KnowledgeKind.exception).toList();
    final explicit = matchingKnowledge.where((e) => e.source == KnowledgeSource.explicit || e.source == KnowledgeSource.correction).toList();

    // Never silently choose between contradictory user Knowledge entries.
    // The user owns the rules, so a conflict becomes a reviewable exception
    // instead of an arbitrary decision.
    final knownCategories = explicit
        .where((e) => e.predicate == 'category' && e.object.trim().isNotEmpty)
        .map((e) => e.object.trim())
        .toSet();
    final knownPurposes = explicit
        .where((e) => e.predicate == 'purpose' && e.object.trim().isNotEmpty)
        .map((e) => e.object.trim())
        .toSet();
    final knowledgeConflict = knownCategories.length > 1 || knownPurposes.length > 1;
    if (knowledgeConflict) {
      observations.add('Personal Knowledge has conflicting rules for this entity.');
      reasons.add('Conflicting saved rules were found, so Nexus will not choose one silently.');
    }

    KnowledgeEntry? selected;
    if (contextual.isNotEmpty) {
      selected = contextual.firstWhere(
        (e) => _contextMatches(e.context, text),
        orElse: () => contextual.first,
      );
    } else if (explicit.isNotEmpty) {
      selected = explicit.firstWhere(
        (e) => e.predicate == 'purpose' || e.predicate == 'category' || e.predicate == 'counterpartyRole',
        orElse: () => explicit.first,
      );
    }

    if (selected != null) {
      if (selected.predicate == 'category') {
        categoryId = selected.object;
        purpose = selected.object;
      } else if (selected.predicate == 'purpose') {
        purpose = selected.object;
      } else if (selected.predicate == 'counterpartyRole') {
        counterpartyRole = selected.object;
      }
      purposeConfidence = selected.confidence.clamp(0.0, 1.0).toDouble();
      reasons.add('Matched personal Knowledge for $entity.');
    }

    final historical = _historicalMatches(entity, history);
    final sameDirectionHistory = historical
        .where((tx) => tx.type.name == detected.type.toLowerCase())
        .toList();
    final patternHistory = sameDirectionHistory.isNotEmpty
        ? sameDirectionHistory
        : historical;
    final categoryCounts = <String, int>{};
    final purposeCounts = <String, int>{};
    for (final tx in historical) {
      if (tx.categoryId?.isNotEmpty == true) {
        categoryCounts[tx.categoryId!] = (categoryCounts[tx.categoryId!] ?? 0) + 1;
      }
      final txPurpose = tx.metadata?['purpose']?.toString();
      if (txPurpose != null && txPurpose.isNotEmpty) {
        purposeCounts[txPurpose] = (purposeCounts[txPurpose] ?? 0) + 1;
      }
    }

    if (categoryId == null && categoryCounts.isNotEmpty && !isTransfer && !isRefund) {
      final topCategory = _top(categoryCounts);
      categoryId = topCategory.key;
      if (purposeCounts.isNotEmpty) {
        final topPurpose = _top(purposeCounts);
        purpose = topPurpose.key;
      } else {
        purpose = topCategory.key;
      }
      purposeConfidence = (topCategory.value / historical.length)
          .clamp(0.0, 0.96)
          .toDouble();
      reasons.add('History repeatedly associates this entity with the same category.');
    }

    // Generic merchant keywords are deliberately consulted only after
    // Knowledge and personal history. A learned correction must always win.
    if (categoryId == null && !isTransfer && !isRefund) {
      final seedCategory = _seedCategory(detected.merchant, detected.body, detected.type);
      if (seedCategory != null) {
        categoryId = seedCategory;
        purpose = seedCategory;
        purposeConfidence = 0.60;
        reasons.add('Matched a generic merchant/category seed.');
      }
    }

    if (detected.detectedCategory?.isNotEmpty == true && categoryId == null && !isTransfer && !isRefund) {
      categoryId = detected.detectedCategory;
      purpose = detected.detectedCategory!;
      purposeConfidence = 0.90;
      reasons.add('The source parser supplied a category match.');
    }

    // Specific financial meanings take precedence over generic categories.
    if (_containsAny(text, const ['emi', 'equated monthly', 'loan repayment', 'loan payment'])) {
      specialIntent = 'emi';
      purpose = 'emi';
      purposeConfidence = purposeConfidence < 0.94 ? 0.94 : purposeConfidence;
      reasons.add('Text indicates an EMI or loan payment.');
    } else if (_containsAny(text, const ['credit card payment', 'card payment', 'card bill', 'credit card bill'])) {
      specialIntent = 'credit_card_payment';
      purpose = 'credit_card_payment';
      purposeConfidence = purposeConfidence < 0.94 ? 0.94 : purposeConfidence;
      reasons.add('Text indicates a credit-card payment.');
    } else if (_containsAny(text, const ['sip', 'mutual fund', 'systematic investment'])) {
      specialIntent = 'investment';
      purpose = 'investment';
      purposeConfidence = purposeConfidence < 0.94 ? 0.94 : purposeConfidence;
      reasons.add('Text indicates an investment contribution.');
    } else if (_containsAny(text, const ['subscription', 'membership', 'renewal'])) {
      specialIntent = 'subscription';
      purpose = 'subscription';
      purposeConfidence = purposeConfidence < 0.90 ? 0.90 : purposeConfidence;
      reasons.add('Text indicates a recurring subscription or renewal.');
    } else if (_containsAny(text, const ['petrol', 'fuel', 'diesel', 'indian oil', 'hpcl', 'bharat petroleum'])) {
      specialIntent = 'fuel';
      purpose = 'fuel';
      purposeConfidence = purposeConfidence < 0.94 ? 0.94 : purposeConfidence;
      reasons.add('Text indicates a fuel purchase.');
    }

    final intent = _intentFor(specialIntent, categoryId, purpose, detected.type);

    if (transferPeer != null) {
      purpose = 'transfer';
      purposeConfidence = purposeConfidence < 0.98 ? 0.98 : purposeConfidence;
      counterpartyRole = 'account';
      final direction = detected.type.toLowerCase() == 'income'
          ? 'Transfer in — matched to the outgoing side.'
          : 'Transfer out — matched to the incoming side.';
      observations.add(direction);
      reasons.add('Same amount and opposite direction appear close together, consistent with an account-to-account transfer.');
    }

    if (isTransfer) {
      categoryId ??= 'transfer';
      purpose = 'transfer';
      purposeConfidence = purposeConfidence < 0.96 ? 0.96 : purposeConfidence;
      counterpartyRole = 'account';
      reasons.add('Transaction text indicates account-to-account movement.');
    } else if (isRefund) {
      purpose = 'refund';
      purposeConfidence = purposeConfidence < 0.96 ? 0.96 : purposeConfidence;
      counterpartyRole = 'merchant';
      reasons.add('Transaction text indicates a refund or reversal.');
    } else if (counterpartyRole == 'unknown') {
      counterpartyRole = detected.type.toLowerCase() == 'income' ? 'payer' : 'payee';
    }

    if (isCompanyPayment) {
      counterpartyRole = 'company';
      reasons.add('Income text looks like a payment from an employer/company.');
    }

    final duplicateIds = <String>[];
    final relatedIds = <String>[];
    for (final tx in history) {
      final dayDiff = tx.date.difference(detected.date).inMinutes.abs();
      final amountMatch = (tx.amount - detected.amount).abs() < 0.01;
      final entityMatch = _transactionMatchesEntity(tx, entity);
      final sameDirection = tx.type.name == detected.type.toLowerCase();
      if (!isTransfer && amountMatch && entityMatch && sameDirection && dayDiff <= 24 * 60) {
        duplicateIds.add(tx.id);
      } else if (entityMatch) {
        relatedIds.add(tx.id);
      }
    }

    if (duplicateIds.isNotEmpty) {
      observations.add('A matching transaction already exists.');
      reasons.add('Same amount and recognized entity appear within 24 hours.');
    }

    final recurring = _recurringPattern(patternHistory);
    if (recurring.isRecurring) {
      observations.add('This entity follows a repeated timing pattern.');
      reasons.add('Historical timing suggests a ${recurring.frequency} transaction.');
    }

    final usualAmount = patternHistory.length >= 2
        ? patternHistory.map((t) => t.amount).reduce((a, b) => a + b) / patternHistory.length
        : null;
    final amountDeviationRatio = usualAmount != null && usualAmount > 0
        ? (detected.amount - usualAmount).abs() / usualAmount
        : null;
    final anomaly = _amountAnomaly(detected.amount, patternHistory);
    if (anomaly != null) {
      observations.add(anomaly);
      reasons.add('The amount differs noticeably from this entity\'s usual amount.');
    }

    final entityConfidence = _entityConfidence(entity, matchingKnowledge, historical);
    final recurringConfidence = recurring.isRecurring ? 0.90 : (historical.isEmpty ? 0.0 : 0.55);
    if (knowledgeConflict) {
      purposeConfidence = purposeConfidence < 0.45 ? purposeConfidence : 0.45;
    }
    final anomalyConfidence = anomaly == null ? 0.0 : 0.90;

    return TransactionUnderstanding(
      source: detected,
      entity: entity.isEmpty ? null : entity,
      categoryId: categoryId,
      purpose: purpose,
      specialIntent: specialIntent,
      intent: intent,
      counterpartyRole: counterpartyRole,
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      isTransfer: isTransfer,
      isRecurring: recurring.isRecurring,
      isRefund: isRefund,
      isPaymentFromCompany: isCompanyPayment,
      relatedTransactionIds: relatedIds.take(10).toList(),
      relatedDetectionIds: transferPeer == null ? const [] : [
        '${transferPeer.source}:${transferPeer.fingerprint}',
      ],
      duplicateTransactionIds: duplicateIds,
      usualAmount: usualAmount,
      amountDeviationRatio: amountDeviationRatio,
      knowledgeConflict: knowledgeConflict,
      observations: observations,
      reasons: reasons,
      confidence: {
        'entity': entityConfidence,
        'purpose': purposeConfidence,
        'account': accountId == null ? 0.0 : 0.96,
        'destination': isTransfer ? (destinationAccountId == null ? 0.0 : 0.96) : 1.0,
        'counterparty': counterpartyRole == 'unknown' ? 0.0 : 0.88,
        'recurring': recurringConfidence,
        'anomaly': anomalyConfidence,
        'duplicate': duplicateIds.isEmpty ? 0.98 : 0.99,
      },
    );
  }

  String? _seedCategory(String merchant, String? body, String type) {
    final merchantText = merchant.toLowerCase().trim();
    final text = '$merchantText ${(body ?? '').toLowerCase()}';
    if (type.toLowerCase() == 'income') {
      if (text.contains('salary') || text.contains('payroll')) return 'salary';
      if (_merchantSeeds[merchantText] == 'investment') return 'investment';
      if (text.contains('received from') || text.contains('sent to')) return 'upi_p2p';
      return null;
    }
    for (final entry in _keywordSeeds.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    for (final entry in _merchantSeeds.entries) {
      if (merchantText.contains(entry.key)) return entry.value;
    }
    return null;
  }

  TransactionIntent _intentFor(String? specialIntent, String? categoryId, String purpose, String type) {
    switch (specialIntent) {
      case 'emi': return TransactionIntent.emiPayment;
      case 'subscription': return TransactionIntent.subscriptionPayment;
      case 'investment': return TransactionIntent.investmentSip;
      case 'fuel': return TransactionIntent.fuel;
      case 'credit_card_payment': return TransactionIntent.emiPayment;
    }
    if (type.toLowerCase() == 'income' && purpose == 'salary') return TransactionIntent.salary;
    if (purpose == 'transfer' || categoryId == 'transfer') return TransactionIntent.transfer;
    switch (categoryId) {
      case 'food': return TransactionIntent.food;
      case 'shopping': return TransactionIntent.shopping;
      case 'entertainment': return TransactionIntent.entertainment;
      case 'health': return TransactionIntent.medical;
    }
    return TransactionIntent.general;
  }

  DetectedTransaction? _findTransferPeer(
    DetectedTransaction detected,
    List<DetectedTransaction> peers,
  ) {
    final opposite = detected.type.toLowerCase() == 'income' ? 'expense' : 'income';
    final text = '${detected.body ?? ''} ${detected.merchant}'.toLowerCase();
    for (final peer in peers) {
      if (peer.source == detected.source && peer.fingerprint == detected.fingerprint) continue;
      if (peer.type.toLowerCase() != opposite) continue;
      if ((peer.amount - detected.amount).abs() >= 0.01) continue;
      if (peer.date.difference(detected.date).inMinutes.abs() > 90) continue;

      final peerText = '${peer.body ?? ''} ${peer.merchant}'.toLowerCase();
      final hasTransferSignal = _containsAny(text, const [
            'upi', 'transfer', 'transferred', 'sent', 'received', 'from', 'to',
          ]) ||
          _containsAny(peerText, const [
            'upi', 'transfer', 'transferred', 'sent', 'received', 'from', 'to',
          ]);
      final differentAccounts = detected.accountNumber != null &&
          peer.accountNumber != null &&
          detected.accountNumber != peer.accountNumber;
      if (hasTransferSignal && (differentAccounts || detected.source != peer.source)) {
        return peer;
      }
    }
    return null;
  }

  List<Transaction> _historicalMatches(String entity, List<Transaction> history) =>
      history.where((tx) => _transactionMatchesEntity(tx, entity)).toList();

  bool _transactionMatchesEntity(Transaction tx, String entity) {
    if (entity.isEmpty) return false;
    final description = _normalizeEntity(tx.description ?? '');
    final metadataEntity = _normalizeEntity(tx.metadata?['entity']?.toString() ?? '');
    return description == entity || description.contains(entity) || metadataEntity == entity || metadataEntity.contains(entity);
  }

  MapEntry<String, int> _top(Map<String, int> values) =>
      values.entries.reduce((a, b) => a.value >= b.value ? a : b);

  double _entityConfidence(String entity, List<KnowledgeEntry> knowledge, List<Transaction> history) {
    if (entity.isEmpty) return 0;
    if (knowledge.any((e) => e.source == KnowledgeSource.explicit || e.source == KnowledgeSource.correction)) return 0.99;
    if (history.length >= 5) return 0.96;
    if (history.length >= 2) return 0.88;
    return 0.70;
  }

  _RecurringResult _recurringPattern(List<Transaction> transactions) {
    if (transactions.length < 2) return const _RecurringResult(false, '');
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final intervals = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i].date.difference(sorted[i - 1].date).inDays);
    }
    if (intervals.isEmpty) return const _RecurringResult(false, '');
    final average = intervals.reduce((a, b) => a + b) / intervals.length;
    if ((average - 30).abs() <= 5) return const _RecurringResult(true, 'monthly');
    if ((average - 7).abs() <= 2) return const _RecurringResult(true, 'weekly');
    if ((average - 365).abs() <= 15) return const _RecurringResult(true, 'yearly');
    return const _RecurringResult(false, '');
  }

  String? _amountAnomaly(double amount, List<Transaction> history) {
    if (history.length < 2) return null;
    final average = history.map((t) => t.amount).reduce((a, b) => a + b) / history.length;
    if (average <= 0) return null;
    final difference = ((amount - average).abs() / average);
    if (difference < 0.08) return null;
    final direction = amount > average ? 'higher' : 'lower';
    return 'Amount is ${((difference) * 100).round()}% $direction than the usual ${average.toStringAsFixed(0)}.';
  }

  String _normalizeEntity(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9@.& -]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _containsAny(String text, List<String> values) => values.any(text.contains);

  bool _contextMatches(Map<String, dynamic> context, String text) {
    final keyword = context['keyword']?.toString().toLowerCase();
    if (keyword == null || keyword.isEmpty) return true;
    return text.contains(keyword);
  }
}

class _RecurringResult {
  final bool isRecurring;
  final String frequency;
  const _RecurringResult(this.isRecurring, this.frequency);
}
