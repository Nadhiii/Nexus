import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as models;
import '../models/detected_transaction.dart';
import '../models/bike.dart';
import '../models/debt.dart';
import '../models/subscription.dart';
import '../models/investment.dart';
import 'transaction_intent_classifier.dart';
import 'ledger_service.dart';

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
  final models.Transaction transaction;
  final List<SideEffect> sideEffects;
  final Map<String, dynamic> extraData;

  /// Pre-calculated new account balance — must be provided by caller
  /// (the approval sheet reads AccountProvider and computes this).
  final double newAccountBalance;

  const ApprovedTransactionPlan({
    required this.source,
    required this.intent,
    required this.transaction,
    required this.sideEffects,
    required this.newAccountBalance,
    this.extraData = const {},
  });

  bool get hasSideEffects => sideEffects.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Transaction Router
// ---------------------------------------------------------------------------

class TransactionRouter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerService _ledgerService = LedgerService();

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
  }) async {
    // ── Step 1: Save transaction + update account + update budget ─────────────
    // We can't get the auto-generated ID back from LedgerService directly,
    // so we pre-generate the ID here and pass it in via copyWith.
    final txnRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc();
    final txnId = txnRef.id;

    final finalTransaction = plan.transaction.copyWith(id: txnId);

    // LedgerService.addTransactionAndUpdateBalance handles:
    //   - transaction write
    //   - account balance update
    //   - budget spentAmount increment
    // All in one atomic batch.
    await _ledgerService.addTransactionAndUpdateBalance(
      transaction: finalTransaction,
      newBalance: plan.newAccountBalance,
    );

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
        await sideBatch.commit();
        debugPrint(
          'TransactionRouter: side effects committed (${plan.sideEffects.length} effects)',
        );
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
        .doc();

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
      updates['nextPaymentDate'] =
          Timestamp.fromDate(data['nextPaymentDate'] as DateTime);
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
  // (categoryId now uses SmartCategoryResolver.resolve() output directly —
  //  i.e. 'garage', 'bills', 'entertainment', 'investment')
  // ---------------------------------------------------------------------------

  static ApprovedTransactionPlan buildFuelPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required double currentAccountBalance,
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
      if (mileage != null) 'mileage': mileage,
    };

    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '',
      userId: userId,
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'Fuel – ${bike.name}',
      categoryId: 'garage', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.fuel,
      transaction: transaction,
      newAccountBalance: currentAccountBalance - detected.amount,
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
            if (mileage != null) 'mileage': mileage,
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
        if (mileage != null) 'mileage': mileage,
      },
    );
  }

  static ApprovedTransactionPlan buildEmiPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required double currentAccountBalance,
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
        (debt.currentBalance - (debt.monthlyEMI ?? detected.amount))
            .clamp(0.0, double.infinity);

    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '',
      userId: userId,
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'EMI – ${debt.name}',
      categoryId: 'bills', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: {
        'intent': 'emi_payment',
        'debtId': debt.id,
        'debtName': debt.name,
        'paidMonthIndex': (debt.paidMonths ?? 0) + 1,
      },
      createdAt: now,
      updatedAt: now,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.emiPayment,
      transaction: transaction,
      newAccountBalance: currentAccountBalance - detected.amount,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateDebtProgress,
          description: 'Mark ${debt.name} EMI as paid',
          data: {
            'debtId': debt.id,
            'newBalance': newBalance,
            if (nextDate != null) 'nextPaymentDate': nextDate,
          },
        ),
      ],
    );
  }

  static ApprovedTransactionPlan buildSubscriptionPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required double currentAccountBalance,
    required Subscription subscription,
  }) {
    final newDueDate = subscription.calculateNextDueDate();

    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '',
      userId: userId,
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: subscription.name,
      categoryId: 'entertainment', // ← valid Category.id (most subs are OTT)
      accountId: accountId,
      date: detected.date,
      metadata: {
        'intent': 'subscription_payment',
        'subscriptionId': subscription.id,
        'subscriptionName': subscription.name,
        'previousDueDate': subscription.nextDueDate.toIso8601String(),
        'newDueDate': newDueDate.toIso8601String(),
      },
      createdAt: now,
      updatedAt: now,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.subscriptionPayment,
      transaction: transaction,
      newAccountBalance: currentAccountBalance - detected.amount,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateSubscriptionDueDate,
          description: 'Advance ${subscription.name} due date',
          data: {
            'subscriptionId': subscription.id,
            'newDueDate': newDueDate,
          },
        ),
      ],
    );
  }

  static ApprovedTransactionPlan buildSipPlan({
    required DetectedTransaction detected,
    required String userId,
    required String accountId,
    required double currentAccountBalance,
    required Investment investment,
  }) {
    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '',
      userId: userId,
      type: models.TransactionType.expense,
      amount: detected.amount,
      description: 'SIP – ${investment.name}',
      categoryId: 'investment', // ← valid Category.id
      accountId: accountId,
      date: detected.date,
      metadata: {
        'intent': 'investment_sip',
        'investmentId': investment.id,
        'investmentName': investment.name,
      },
      createdAt: now,
      updatedAt: now,
    );

    return ApprovedTransactionPlan(
      source: detected,
      intent: TransactionIntent.investmentSip,
      transaction: transaction,
      newAccountBalance: currentAccountBalance - detected.amount,
      sideEffects: [
        SideEffect(
          type: SideEffectType.updateInvestmentAmount,
          description:
              'Add ₹${detected.amount.toStringAsFixed(0)} to ${investment.name}',
          data: {
            'investmentId': investment.id,
            'amount': detected.amount,
          },
        ),
      ],
    );
  }
}