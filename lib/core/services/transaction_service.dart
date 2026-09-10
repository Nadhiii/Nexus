import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import 'transaction_paths.dart';

class TransactionService {
  Future<Transaction?> findBySourceFingerprint(
    String userId,
    String fingerprint,
  ) async {
    final snapshot =
        await TransactionPaths.collection(fs.FirebaseFirestore.instance, userId)
            .where('metadata.sourceFingerprint', isEqualTo: fingerprint)
            .limit(1)
            .get();
    if (snapshot.docs.isEmpty) return null;
    // The Firestore document id is authoritative and is not duplicated in
    // the document payload. Preserve it so callers can safely compare an
    // existing record with the candidate being imported.
    return Transaction.fromFirestore(snapshot.docs.first);
  }

  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  fs.CollectionReference<Map<String, dynamic>> _getTransactionsCollection(
    String userId,
  ) {
    return TransactionPaths.collection(_firestore, userId);
  }

  Stream<List<Transaction>> watchUserTransactions(String userId) {
    return _getTransactionsCollection(userId).snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
      // Sort in memory instead of using Firestore orderBy
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    });
  }

  /// Restores a transaction with its original ID (used for undo)
  Future<void> restoreTransaction(Transaction transaction) async {
    final docRef = TransactionPaths.document(
      _firestore,
      transaction.userId,
      transaction.id,
    );
    await docRef.set(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _getTransactionsCollection(
      transaction.userId,
    ).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.value();
    }
    return _getTransactionsCollection(user.uid).doc(transactionId).delete();
  }

  Future<void> clearAllTransactions(String userId) async {
    final snapshot = await _getTransactionsCollection(userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Get all transactions for a specific account (as both source and destination)
  Future<List<Transaction>> getTransactionsByAccountId(
    String userId,
    String accountId,
  ) async {
    final snapshot = await _getTransactionsCollection(
      userId,
    ).where('accountId', isEqualTo: accountId).get();
    final snapshot2 = await _getTransactionsCollection(
      userId,
    ).where('toAccountId', isEqualTo: accountId).get();

    final transactions = <Transaction>[];
    for (final doc in snapshot.docs) {
      transactions.add(Transaction.fromFirestore(doc));
    }
    for (final doc in snapshot2.docs) {
      transactions.add(Transaction.fromFirestore(doc));
    }
    return transactions;
  }

  /// Delete all transactions linked to a specific account
  Future<int> deleteTransactionsByAccountId(
    String userId,
    String accountId,
  ) async {
    final snapshot = await _getTransactionsCollection(
      userId,
    ).where('accountId', isEqualTo: accountId).get();
    final snapshot2 = await _getTransactionsCollection(
      userId,
    ).where('toAccountId', isEqualTo: accountId).get();

    final batch = _firestore.batch();
    int count = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
    }
    for (final doc in snapshot2.docs) {
      batch.delete(doc.reference);
      count++;
    }
    if (count > 0) {
      await batch.commit();
    }
    return count;
  }

  /// Bulk delete transactions by IDs
  Future<void> deleteTransactionsBatch(
    String userId,
    List<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final id in transactionIds) {
      batch.delete(_getTransactionsCollection(userId).doc(id));
    }
    await batch.commit();
  }

  Future<void> restoreTransactions(
    String userId,
    List<Transaction> transactions,
  ) async {
    final batch = _firestore.batch();
    for (final transaction in transactions) {
      final docRef = _getTransactionsCollection(userId).doc(transaction.id);
      batch.set(docRef, transaction.toMap());
    }
    await batch.commit();
  }
}
