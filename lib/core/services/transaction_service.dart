import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';

class TransactionService {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  fs.CollectionReference<Map<String, dynamic>> _getTransactionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Stream<List<Transaction>> watchUserTransactions(String userId) {
    return _getTransactionsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  }

  Future<void> addTransaction(Transaction transaction) async {
    final docRef = _getTransactionsCollection(transaction.userId).doc();
    await docRef.set(transaction.copyWith(id: docRef.id).toJson());
  }

  Future<void> updateTransaction(Transaction transaction) {
    return _getTransactionsCollection(transaction.userId).doc(transaction.id).update(transaction.toJson());
  }

  Future<void> deleteTransaction(String transactionId) {
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return Future.value();
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

  Future<void> restoreTransactions(String userId, List<Transaction> transactions) async {
    final batch = _firestore.batch();
    for (final transaction in transactions) {
      final docRef = _getTransactionsCollection(userId).doc(transaction.id);
      batch.set(docRef, transaction.toJson());
    }
    await batch.commit();
  }
}
