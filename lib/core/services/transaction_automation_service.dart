import '../models/account.dart';
import '../models/detected_transaction.dart';
import '../models/knowledge_entry.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../models/transaction_understanding.dart';
import '../models/transaction_relationship.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import 'transaction_intelligence_service.dart';
import 'transaction_relationship_service.dart';

/// Decides whether a detected event can be recorded without user input.
/// It never creates Knowledge by itself.
class TransactionAutomationService {
  final TransactionIntelligenceService _intelligence;

  TransactionAutomationService({TransactionIntelligenceService? intelligence})
    : _intelligence = intelligence ?? const TransactionIntelligenceService();

  TransactionUnderstanding analyze({
    required DetectedTransaction detected,
    required List<Transaction> history,
    required List<KnowledgeEntry> knowledge,
    required AccountProvider accounts,
    List<DetectedTransaction> peerDetections = const [],
  }) {
    final account = resolveAccount(detected, accounts.accounts);
    var destination = resolveDestinationAccount(
      detected,
      accounts.accounts,
      account,
    );
    final understanding = _intelligence.analyze(
      detected: detected,
      history: history,
      knowledge: knowledge,
      accountId: account?.id,
      destinationAccountId: destination?.id,
      peerDetections: peerDetections,
    );

    if (destination == null && understanding.isTransfer) {
      final peer = _findTransferPeer(detected, peerDetections);
      if (peer != null && peer.accountNumber != null) {
        final hint = peer.accountNumber!.replaceAll(RegExp(r'\D'), '');
        final matches = accounts.accounts.where((item) {
          if (!item.isActive || item.id == account?.id || hint.length < 4) {
            return false;
          }
          final number = item.accountNumber?.replaceAll(RegExp(r'\D'), '');
          final card = item.cardNumber?.replaceAll(RegExp(r'\D'), '');
          return (number != null && number.endsWith(hint)) ||
              (card != null && card.endsWith(hint));
        }).toList();
        if (matches.length == 1) destination = matches.first;
      }
    }

    final confidence = Map<String, double>.from(understanding.confidence);
    confidence['account'] = account == null ? 0.0 : 0.96;
    if (understanding.isTransfer) {
      confidence['destination'] = destination == null ? 0.0 : 0.96;
    }

    return TransactionUnderstanding(
      source: detected,
      entity: understanding.entity,
      categoryId: understanding.categoryId ?? detected.detectedCategory,
      purpose: understanding.purpose,
      specialIntent: understanding.specialIntent,
      intent: understanding.intent,
      counterpartyRole: understanding.counterpartyRole,
      accountId: understanding.accountId,
      destinationAccountId: destination?.id,
      isTransfer: understanding.isTransfer,
      isRecurring: understanding.isRecurring,
      isRefund: understanding.isRefund,
      isPaymentFromCompany: understanding.isPaymentFromCompany,
      relatedTransactionIds: understanding.relatedTransactionIds,
      relatedDetectionIds: understanding.relatedDetectionIds,
      duplicateTransactionIds: understanding.duplicateTransactionIds,
      usualAmount: understanding.usualAmount,
      amountDeviationRatio: understanding.amountDeviationRatio,
      knowledgeConflict: understanding.knowledgeConflict,
      observations: understanding.observations,
      reasons: understanding.reasons,
      confidence: confidence,
    );
  }

  Future<bool> tryAutoRecord({
    required DetectedTransaction detected,
    required AccountProvider accountProvider,
    required TransactionProvider transactionProvider,
    required List<KnowledgeEntry> knowledge,
    List<DetectedTransaction> peerDetections = const [],
  }) async {
    if (detected.warnings.isNotEmpty || !detected.isHighConfidence) {
      return false;
    }

    final history = transactionProvider.transactions;
    final peer = _findTransferPeer(detected, peerDetections);
    // Two bank notifications can describe the same self-transfer. Treat the
    // outgoing side as the canonical transaction; the incoming notification
    // is consumed with it instead of creating a second ledger entry.
    if (peer != null && detected.type.toLowerCase() == 'income') return false;
    final understanding = analyze(
      detected: detected,
      history: history,
      knowledge: knowledge,
      accounts: accountProvider,
      peerDetections: peerDetections,
    );

    if (!understanding.canAutoRecord) return false;
    // These intents may have module-specific fields/side effects. Keep them
    // in review until their complete context is available.
    if (const {
      'fuel',
      'emi',
      'subscription',
      'investment',
      'credit_card_payment',
    }.contains(understanding.specialIntent)) {
      return false;
    }

    final account = resolveAccount(detected, accountProvider.accounts);
    if (account == null) return false;

    Account? destination;
    if (understanding.isTransfer) {
      // analyze() may have resolved the destination from the paired bank
      // notification, so don't discard that result by looking only at the
      // current message again.
      final destinationId = understanding.destinationAccountId;
      if (destinationId != null) {
        final matches = accountProvider.accounts.where(
          (item) => item.isActive && item.id == destinationId,
        );
        if (matches.length == 1) destination = matches.first;
      }
      destination ??= resolveDestinationAccount(
        detected,
        accountProvider.accounts,
        account,
      );
      if (destination == null) return false;
    }

    final type = understanding.isTransfer
        ? TransactionType.transfer
        : detected.type.toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    final metadata = <String, dynamic>{
      'source': detected.source,
      'sourceId': detected.id,
      'sourceFingerprint': detected.fingerprint,
      'entity': understanding.entity,
      'purpose': understanding.purpose,
      'specialIntent': understanding.specialIntent,
      'counterpartyRole': understanding.counterpartyRole,
      'accountId': understanding.accountId,
      'destinationAccountId': understanding.destinationAccountId,
      'isRecurring': understanding.isRecurring,
      'isRefund': understanding.isRefund,
      'isPaymentFromCompany': understanding.isPaymentFromCompany,
      'confidence': understanding.confidence,
      'reasons': understanding.reasons,
      'relatedTransactionIds': understanding.relatedTransactionIds,
    };

    final draft = TransactionDraft(
      type: type,
      amount: detected.amount,
      description: detected.merchant,
      categoryId: understanding.categoryId,
      accountId: account.id,
      destinationAccountId: destination?.id,
      date: detected.date,
      metadata: metadata,
      source: detected.source,
      sourceId: detected.id,
      sourceFingerprint: detected.fingerprint,
      confidence: detected.confidence,
      warnings: detected.warnings,
    );

    final result = await transactionProvider.commitDraft(draft);
    if (result == null) return false;
    final transactionId = result.transaction.id;
    if (result.alreadyExists) return true;

    // Persist only meaningful relationships. Facts remain separate; this is
    // just the explanation connecting them.
    if (understanding.relatedTransactionIds.isNotEmpty) {
      final relationshipType = understanding.isRefund
          ? TransactionRelationshipType.refund
          : understanding.isRecurring
          ? TransactionRelationshipType.recurringSeries
          : TransactionRelationshipType.relatedPayment;
      try {
        await TransactionRelationshipService().upsertRelated(
          type: relationshipType,
          transactionIds: [
            transactionId,
            ...understanding.relatedTransactionIds.take(9),
          ],
          reason: understanding.reasons.isEmpty
              ? 'Transactions appear related by entity and history.'
              : understanding.reasons.join(' '),
          confidence: understanding
              .confidenceFor('entity')
              .clamp(0.0, 1.0)
              .toDouble(),
        );
      } catch (_) {
        // A relationship is explanatory metadata; never treat a relationship
        // write failure as a transaction failure after the ledger commit.
      }
    }
    return true;
  }

  DetectedTransaction? _findTransferPeer(
    DetectedTransaction detected,
    List<DetectedTransaction> peers,
  ) {
    final opposite = detected.type.toLowerCase() == 'income'
        ? 'expense'
        : 'income';
    for (final peer in peers) {
      if (peer.source == detected.source &&
          peer.fingerprint == detected.fingerprint) {
        continue;
      }
      if (peer.type.toLowerCase() != opposite) continue;
      if ((peer.amount - detected.amount).abs() >= 0.01) continue;
      if (peer.date.difference(detected.date).inMinutes.abs() > 90) continue;
      final combined =
          '${detected.merchant} ${detected.body ?? ''} ${peer.merchant} ${peer.body ?? ''}'
              .toLowerCase();
      final transferSignal = RegExp(
        r'\b(transfer|transferred|self[- ]?transfer|imps|neft|rtgs|upi transfer|fund transfer)\b',
      ).hasMatch(combined);
      if (!transferSignal) continue;
      return peer;
    }
    return null;
  }

  Account? resolveAccount(
    DetectedTransaction detected,
    List<Account> accounts,
  ) {
    final active = accounts.where((account) => account.isActive).toList();
    final hint = detected.accountNumber?.replaceAll(RegExp(r'\D'), '');
    final bank = detected.bankName?.trim().toLowerCase();

    if (hint != null && hint.isNotEmpty) {
      final matches = active.where((account) {
        final accountNumber = account.accountNumber?.replaceAll(
          RegExp(r'\D'),
          '',
        );
        final cardNumber = account.cardNumber?.replaceAll(RegExp(r'\D'), '');
        return (accountNumber != null && accountNumber.endsWith(hint)) ||
            (cardNumber != null && cardNumber.endsWith(hint));
      }).toList();
      if (matches.length == 1) return matches.first;
    }

    if (bank != null && bank.isNotEmpty) {
      final matches = active.where((account) {
        final name = account.name.toLowerCase();
        final bankName = account.bankName?.toLowerCase() ?? '';
        return name.contains(bank) ||
            bank.contains(name) ||
            bankName.contains(bank) ||
            bank.contains(bankName);
      }).toList();
      if (matches.length == 1) return matches.first;
    }

    return null;
  }

  Account? resolveDestinationAccount(
    DetectedTransaction detected,
    List<Account> accounts,
    Account? source,
  ) {
    if (source == null) return null;
    final text = (detected.body ?? '').toLowerCase();
    final matches = accounts.where((account) {
      if (!account.isActive || account.id == source.id) return false;
      final name = account.name.toLowerCase();
      final number = account.accountNumber?.replaceAll(RegExp(r'\D'), '');
      return text.contains(name) ||
          (number != null &&
              number.length >= 4 &&
              text.contains(number.substring(number.length - 4)));
    }).toList();
    return matches.length == 1 ? matches.first : null;
  }
}
