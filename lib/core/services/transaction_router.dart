import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as models;
import '../models/transaction_draft.dart';
import '../models/detected_transaction.dart';
import '../models/bike.dart';
import '../models/debt.dart';
import '../models/subscription.dart';
import '../models/investment.dart';
import 'transaction_intent_classifier.dart';
import 'transaction_paths.dart';
import '../providers/transaction_provider.dart';
import '../utils/currency_formatter.dart';

// ---------------------------------------------------------------------------
// Side Effect types
// ---------------------------------------------------------------------------

enum SideEffectType {
  createBikeEntry,
  updateBikeOdometer,
  updateDebtProgress,
  updateSubscriptionDueDate,
  updateInvestmentAmount,
}

class SideEffect {
  final SideEffectType type;
  final String description;
  final Map<String, dynamic> data;

  const SideEffect({
    required this.type,
    required this.description,
    required this.data,
  });
}

// ---------------------------------------------------------------------------
// Approved plan
// ---------------------------------------------------------------------------

class ApprovedTransactionPlan {
  final DetectedTransaction source;
  final TransactionIntent intent;
  final TransactionDraft draft;
  final List<SideEffect> sideEffects;
  final Map<String, dynamic> extraData;

  const ApprovedTransactionPlan({
    required this.source,
    required this.intent,
    required this.draft,
    required this.sideEffects,
    this.extraData = const {},
  });

  bool get hasSideEffects => sideEffects.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Transaction Router
// ---------------------------------------------------------------------------

class TransactionRouter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  /// Executes an [ApprovedTransactionPlan]:
  ///   - Routes through LedgerService for the main transaction
  ///     (handles account balance + budget spentAmount atomically)
  ///   - Applies side effects (bike entry, debt progress, etc.) in a
  ///     second batch immediately after
  ///
  /// Returns the created transaction ID.
  Future<String> execute({
    required ApprovedTransactionPlan plan,
    required String userId,
    required TransactionProvider transactionProvider,
  }) async {
    final result = await transactionProvider.commitDraft(plan.draft);
    if (result == null) {
      throw StateError(
        transactionProvider.error ?? 'Transaction could not be committed',
      );
    }
    final txnId = result.transaction.id;
    if (result.alreadyExists) return txnId;

    debugPrint(
      'TransactionRouter: main commit done — intent=${plan.intent.label}, txnId=$txnId',
    );

    // ── Step 2: Side effects (second batch) ───────────────────────────────────
    if (plan.sideEffects.isNotEmpty) {
      final sideBatch = _firestore.batch();
      bool hasSideWrites = false;

      for (final effect in plan.sideEffects) {
        switch (effect.type) {
          case SideEffectType.createBikeEntry:
            _applyCreateBikeEntry(sideBatch, userId, effect.data, txnId);
            hasSideWrites = true;
            break;

          case SideEffectType.updateBikeOdometer:
            _applyUpdateBikeOdometer(sideBatch, userId, effect.data);
            hasSideWrites = true;
            break;

          case SideEffectType.updateDebtProgress:
            _applyUpdateDebtProgress(sideBatch, userId, effect.data);
            hasSideWrites = true;
            break;

          case SideEffectType.updateSubscriptionDueDate:
            _applyUpdateSubscriptionDueDate(sideBatch, userId, effect.data);
            hasSideWrites = true;
            break;

          case SideEffectType.updateInvestmentAmount:
            _applyUpdateInvestmentAmount(sideBatch, userId, effect.data);
            hasSideWrites = true;
            break;
        }
      }

      if (hasSideWrites) {
        try {
          await sideBatch.commit();
          await TransactionPaths.document(_firestore, userId, txnId).update({
            'metadata.sideEffectStatus': 'completed',
            'metadata.sideEffectCompletedAt': Timestamp.now(),
          });
          debugPrint(
            'TransactionRouter: side effects committed (${plan.sideEffects.length} effects)',
          );
        } catch (error) {
          // The ledger commit remains valid, but the record explicitly marks
          // the follow-up work for a retry/reconciliation worker. Do not
          // report the financial commit as failed or silently lose the error.
          try {
            await TransactionPaths.document(_firestore, userId, txnId).update({
              'metadata.sideEffectStatus': 'pending_retry',
              'metadata.sideEffectError': error.toString(),
            });
          } catch (statusError) {
            debugPrint(
              'TransactionRouter: could not record retry status: $statusError',
            );
          }
          rethrow;
        }
      }
    }

    return txnId;
  }

  // ---------------------------------------------------------------------------
  // Side effect writers (unchanged from original)
  // ---------------------------------------------------------------------------

  void _applyCreateBikeEntry(
    WriteBatch batch,
    String userId,
    Map<String, dynamic> data,
    String transactionId,
  ) {
    final bikeId = data['bikeId'] as String;
    final entryRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        // Retrying an approval must update the same side-effect record rather
        // than creating a second fuel entry.
        .doc(transactionId);

    final now = DateTime.now();
    batch.set(entryRef, {
      'id': entryRef.id,
      'userId': userId,
      'bikeName': data['bikeName'] as String,
      'date': Timestamp.fromDate(now),
      'odometerReading': data['odometerReading'] as double,
      'fuelQuantity': data['fuelLiters'] as double,
      'fuelAmount': data['amount'] as double,
      'category': 'Fuel',
      'notes': data['notes'] as String? ?? '',
      'mileage': data['mileage'] as double?,
      'isFullTank': data['isFullTank'] as bool? ?? true,
      'linkedTransactionId': transactionId,
    });
  }

  void _applyUpdateBikeOdometer(
    WriteBatch batch,
    String userId,
    Map<String, dynamic> data,
  ) {
    final bikeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(data['bikeId'] as String);
    batch.update(bikeRef, {'currentOdometer': data['newOdometer'] as double});
  }

  void _applyUpdateDebtProgress(
    WriteBatch batch,
    String userId,
    Map<String, dynamic> data,
  ) {
    final debtRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('debts')
        .doc(data['debtId'] as String);

    final updates = <String, dynamic>{
      'paidMonths': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    };
    if (data['newBalance'] != null) {
      updates['currentBalance'] = data['newBalance'] as double;
    }
    if (data['nextPaymentDate'] != null) {
      updates['nextPaymentDate'] = Timestamp.fromDate(
        data['nextPaymentDate'] as DateTime,
      );
    }
    batch.update(debtRef, updates);
  }

  void _applyUpdateSubscriptionDueDate(
    WriteBatch batch,
    String userId,
    Map<String, dynamic> data,
  ) {
    final subRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(data['subscriptionId'] as String);
    batch.update(subRef, {
      'nextDueDate': Timestamp.fromDate(data['newDueDate'] as DateTime),
      'updatedAt': Timestamp.now(),
    });
  }

  void _applyUpdateInvestmentAmount(
    WriteBatch batch,
    String userId,
    Map<String, dynamic> data,
  ) {
    final invRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('investments')
        .doc(data['investmentId'] as String);
    final updates = <String, dynamic>{
      'investedAmount': FieldValue.increment(data['amount'] as double),
      'updatedAt': Timestamp.now(),
    };
    if (data['newQuantity'] != null) {
      updates['quantity'] = data['newQuantity'] as double;
    }
    batch.update(invRef, updates);
  }

  // ---------------------------------------------------------------------------
  // Static plan builders
  // (categoryId now uses the resolved category output directly —
  //  i.e. 'garage', 'bills', 'entertainment', 'investment')
  // ---------------------------------------------------------------------------

  static ApprovedTransactionPlan buildFuelPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required Bike bike,
    required double odometerReading,
    required double fuelLiters,
    required bool isFullTank,
    double? previousFullTankOdometer,
  }) {
    double? mileage;
    if (isFullTank &&
        previousFullTankOdometer != null &&
        previousFullTankOdometer > 0 &&
        odometerReading > previousFullTankOdometer &&
        fuelLiters > 0) {
      mileage = (odometerReading - previousFullTankOdometer) / fuelLiters;
    }

    final metadata = <String, dynamic>{
      'intent': 'fuel',
      'bikeId': bike.id,
      'bikeName': bike.name,
      'fuelLiters': fuelLiters,
      'odometerReading': odometerReading,
      'previousOdometer': bike.currentOdometer,
      'pricePerLiter': fuelLiters > 0 ? detected.amount / fuelLiters : null,
      'isFullTank': isFullTank,
      'mileage': mileage,
    };

    final draft = TransactionDraft(
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'Fuel – ${bike.name}',
      categoryId: 'garage', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: metadata,
      source: detected.source,
      sourceId: detected.id,
      sourceFingerprint: detected.fingerprint,
      confidence: detected.confidence,
      warnings: detected.warnings,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.fuel,
      draft: draft,
      sideEffects: [
        SideEffect(
          type: SideEffectType.createBikeEntry,
          description: 'Log fuel entry for ${bike.name}',
          data: {
            'bikeId': bike.id,
            'bikeName': bike.name,
            'odometerReading': odometerReading,
            'fuelLiters': fuelLiters,
            'amount': detected.amount,
            'isFullTank': isFullTank,
            'mileage': mileage,
          },
        ),
        SideEffect(
          type: SideEffectType.updateBikeOdometer,
          description:
              'Update odometer to ${odometerReading.toStringAsFixed(0)} km',
          data: {'bikeId': bike.id, 'newOdometer': odometerReading},
        ),
      ],
      extraData: {
        'odometerReading': odometerReading,
        'fuelLiters': fuelLiters,
        'isFullTank': isFullTank,
        'mileage': mileage,
      },
    );
  }

  static ApprovedTransactionPlan buildEmiPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required Debt debt,
  }) {
    final nextDate = debt.nextPaymentDate != null
        ? DateTime(
            debt.nextPaymentDate!.year,
            debt.nextPaymentDate!.month + 1,
            debt.nextPaymentDate!.day,
          )
        : null;

    final newBalance =
        (debt.currentBalance - (debt.monthlyEMI ?? detected.amount)).clamp(
          0.0,
          double.infinity,
        );

    final draft = TransactionDraft(
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'EMI – ${debt.name}',
      categoryId: 'bills', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: {
        'source': detected.source,
        'sourceId': detected.id,
        'sourceFingerprint': detected.fingerprint,
        'intent': 'emi_payment',
        'debtId': debt.id,
        'debtName': debt.name,
        'paidMonthIndex': (debt.paidMonths ?? 0) + 1,
      },
      source: detected.source,
      sourceId: detected.id,
      sourceFingerprint: detected.fingerprint,
      confidence: detected.confidence,
      warnings: detected.warnings,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.emiPayment,
      draft: draft,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateDebtProgress,
          description: 'Mark ${debt.name} EMI as paid',
          data: {
            'debtId': debt.id,
            'newBalance': newBalance,
            'nextPaymentDate': nextDate,
          },
        ),
      ],
    );
  }

  static ApprovedTransactionPlan buildSubscriptionPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required Subscription subscription,
  }) {
    final newDueDate = subscription.calculateNextDueDate();

    final draft = TransactionDraft(
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: subscription.name,
      categoryId: 'entertainment', // ← valid Category.id (most subs are OTT)
      accountId: accountId,
      date: detected.date,
      metadata: {
        'source': detected.source,
        'sourceId': detected.id,
        'sourceFingerprint': detected.fingerprint,
        'intent': 'subscription_payment',
        'subscriptionId': subscription.id,
        'subscriptionName': subscription.name,
        'previousDueDate': subscription.nextDueDate.toIso8601String(),
        'newDueDate': newDueDate.toIso8601String(),
      },
      source: detected.source,
      sourceId: detected.id,
      sourceFingerprint: detected.fingerprint,
      confidence: detected.confidence,
      warnings: detected.warnings,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.subscriptionPayment,
      draft: draft,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateSubscriptionDueDate,
          description: 'Advance ${subscription.name} due date',
          data: {'subscriptionId': subscription.id, 'newDueDate': newDueDate},
        ),
      ],
    );
  }

  static ApprovedTransactionPlan buildSipPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required Investment investment,
  }) {
    final draft = TransactionDraft(
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'SIP – ${investment.name}',
      categoryId: 'investment', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: {
        'source': detected.source,
        'sourceId': detected.id,
        'sourceFingerprint': detected.fingerprint,
        'intent': 'investment_sip',
        'investmentId': investment.id,
        'investmentName': investment.name,
      },
      source: detected.source,
      sourceId: detected.id,
      sourceFingerprint: detected.fingerprint,
      confidence: detected.confidence,
      warnings: detected.warnings,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.investmentSip,
      draft: draft,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateInvestmentAmount,
          description:
              'Add ₹${AppCurrency.format(detected.amount)} to ${investment.name}',
          data: {'investmentId': investment.id, 'amount': detected.amount},
        ),
      ],
    );
  }
}
