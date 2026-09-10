import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import 'transaction_paths.dart';

/// LedgerService: Ensures atomicity for transaction + account + budget updates.
///
/// Every write path (add, transfer) now updates:
///   1. transactions/{id}          — the new transaction document
///   2. accounts/{id}.balance      — updated account balance
///   3. budgets/{id}.spentAmount   — if an active expense budget matches the categoryId
///
/// All three happen in a single WriteBatch — either all succeed or all fail.
class LedgerService {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Atomically add a transaction, update account balance, and update budget spentAmount.
  Future<void> addTransactionAndUpdateBalance({
    required Transaction transaction,
    required double newBalance,
  }) async {
    final userId = transaction.userId;

    final transactionRef = transaction.id.isNotEmpty
        ? TransactionPaths.document(_firestore, userId, transaction.id)
        : TransactionPaths.collection(_firestore, userId).doc();
    final accountRef = _userDoc(userId, 'accounts', transaction.accountId);

    final batch = _firestore.batch();

    // 1. Transaction
    batch.set(
      transactionRef,
      transaction.copyWith(id: transactionRef.id).toMap(),
    );

    // 2. Account balance
    batch.update(accountRef, {'balance': newBalance});

    // 3. Budget spentAmount (expense only, best-effort — never throws)
    if (transaction.type == TransactionType.expense &&
        transaction.categoryId != null &&
        transaction.categoryId!.isNotEmpty) {
      await _applyBudgetUpdate(
        batch: batch,
        userId: userId,
        categoryId: transaction.categoryId!,
        amount: transaction.amount,
        transactionDate: transaction.date,
      );
    }

    await batch.commit();
    debugPrint(
      'LedgerService: committed txn+balance${transaction.type == TransactionType.expense ? "+budget" : ""}',
    );
  }

  /// Atomically add a transfer transaction and update both account balances.
  /// Transfers don't touch budgets (they are neutral money movements).
  Future<void> addTransferAndUpdateBalances({
    required Transaction transaction,
    required double sourceNewBalance,
    required double destNewBalance,
  }) async {
    final userId = transaction.userId;

    final transactionRef = transaction.id.isNotEmpty
        ? TransactionPaths.document(_firestore, userId, transaction.id)
        : TransactionPaths.collection(_firestore, userId).doc();
    final sourceAccountRef =
        _userDoc(userId, 'accounts', transaction.accountId);
    final destAccountRef =
        _userDoc(userId, 'accounts', transaction.toAccountId!);

    final batch = _firestore.batch();

    batch.set(
      transactionRef,
      transaction.copyWith(id: transactionRef.id).toMap(),
    );
    batch.update(sourceAccountRef, {'balance': sourceNewBalance});
    batch.update(destAccountRef, {'balance': destNewBalance});

    await batch.commit();
    debugPrint('LedgerService: committed transfer+both balances');
  }

  /// Atomically update a transaction, update account balances, and adjust budgets.
  /// [accountBalances] should contain the fully computed new balances for any account
  /// affected by this edit (e.g. source, dest, or if the account was changed).
  Future<void> updateTransactionAndUpdateBalances({
    required Transaction oldTransaction,
    required Transaction newTransaction,
    required Map<String, double> accountBalances,
  }) async {
    final userId = newTransaction.userId;
    final transactionRef = TransactionPaths.document(
      _firestore,
      userId,
      newTransaction.id,
    );
    
    final batch = _firestore.batch();
    batch.update(transactionRef, newTransaction.toMap());

    for (final entry in accountBalances.entries) {
      final accountRef = _userDoc(userId, 'accounts', entry.key);
      batch.update(accountRef, {'balance': entry.value});
    }

    // Budget revert old amount (if expense)
    if (oldTransaction.type == TransactionType.expense &&
        oldTransaction.categoryId != null &&
        oldTransaction.categoryId!.isNotEmpty) {
      await _applyBudgetUpdate(
        batch: batch,
        userId: userId,
        categoryId: oldTransaction.categoryId!,
        amount: -oldTransaction.amount, // negative to revert
        transactionDate: oldTransaction.date,
      );
    }

    // Budget apply new amount (if expense)
    if (newTransaction.type == TransactionType.expense &&
        newTransaction.categoryId != null &&
        newTransaction.categoryId!.isNotEmpty) {
      await _applyBudgetUpdate(
        batch: batch,
        userId: userId,
        categoryId: newTransaction.categoryId!,
        amount: newTransaction.amount,
        transactionDate: newTransaction.date,
      );
    }

    await batch.commit();
    debugPrint('LedgerService: committed transaction update + balances + budget adjustments');
  }

  /// Atomically delete a transaction, update affected account balances, and adjust budgets.
  Future<void> deleteTransactionAndUpdateBalances({
    required Transaction transaction,
    required Map<String, double> accountBalances,
  }) async {
    final userId = transaction.userId;
    final transactionRef = TransactionPaths.document(
      _firestore,
      userId,
      transaction.id,
    );
    
    final batch = _firestore.batch();
    batch.delete(transactionRef);

    for (final entry in accountBalances.entries) {
      final accountRef = _userDoc(userId, 'accounts', entry.key);
      batch.update(accountRef, {'balance': entry.value});
    }

    // Budget revert amount (if expense)
    if (transaction.type == TransactionType.expense &&
        transaction.categoryId != null &&
        transaction.categoryId!.isNotEmpty) {
      await _applyBudgetUpdate(
        batch: batch,
        userId: userId,
        categoryId: transaction.categoryId!,
        amount: -transaction.amount, // negative to revert
        transactionDate: transaction.date,
      );
    }

    await batch.commit();
    debugPrint('LedgerService: committed transaction delete + balances + budget revert');
  }

  // ---------------------------------------------------------------------------
  // Budget update helper
  // ---------------------------------------------------------------------------

  /// Finds the active budget for [categoryId] and increments its spentAmount
  /// in the same [batch]. Silent no-op if no matching budget exists.
  Future<void> _applyBudgetUpdate({
    required fs.WriteBatch batch,
    required String userId,
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      // Query for an active budget matching this category
      // "Active" means: startDate <= now <= endDate
      final now = fs.Timestamp.fromDate(transactionDate);

      final querySnap = await _userCol(userId, 'budgets')
          .where('categoryId', isEqualTo: categoryId)
          .where('startDate', isLessThanOrEqualTo: now)
          .limit(5) // safety limit
          .get();

      if (querySnap.docs.isEmpty) return;

      // Pick the budget whose endDate is >= transactionDate
      final txDate = transactionDate;
      fs.DocumentSnapshot? matchDoc;

      for (final doc in querySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final endRaw = data['endDate'];
        DateTime? endDate;
        if (endRaw is fs.Timestamp) {
          endDate = endRaw.toDate();
        } else if (endRaw is String) {
          endDate = DateTime.tryParse(endRaw);
        }
        if (endDate != null && !txDate.isAfter(endDate)) {
          matchDoc = doc;
          break;
        }
      }

      if (matchDoc == null) return;

      // Increment spentAmount atomically in the same batch
      batch.update(matchDoc.reference, {
        'spentAmount': fs.FieldValue.increment(amount),
      });

      debugPrint(
        'LedgerService: budget[${matchDoc.id}] spentAmount += $amount',
      );
    } catch (e) {
      // Budget update is best-effort — never fail the main transaction
      debugPrint('LedgerService: budget update skipped ($e)');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  fs.CollectionReference _userCol(String userId, String collection) =>
      _firestore.collection('users').doc(userId).collection(collection);

  fs.DocumentReference _userDoc(
          String userId, String collection, String docId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(docId);
}
