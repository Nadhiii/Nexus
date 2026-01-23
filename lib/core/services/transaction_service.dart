import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';

class TransactionService {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  fs.CollectionReference<Map<String, dynamic>> _getTransactionsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
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

  Future<void> addTransaction(Transaction transaction) async {
    final docRef = _getTransactionsCollection(transaction.userId).doc();
    await docRef.set(transaction.copyWith(id: docRef.id).toMap());
  }

  /// Restores a transaction with its original ID (used for undo)
  Future<void> restoreTransaction(Transaction transaction) async {
    final docRef = _getTransactionsCollection(
      transaction.userId,
    ).doc(transaction.id);
    await docRef.set(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _getTransactionsCollection(
      transaction.userId,
    ).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value();
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
    if (transactionIds.isEmpty) return;
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
