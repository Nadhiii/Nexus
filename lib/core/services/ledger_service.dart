import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/account.dart';

/// LedgerService: Ensures atomicity for transaction + account updates
class LedgerService {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  /// Atomically add a transaction and update account balance
  Future<void> addTransactionAndUpdateBalance({
    required Transaction transaction,
    required double newBalance,
  }) async {
    final userId = transaction.userId;
    final transactionRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .doc();
    final accountRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('accounts')
      .doc(transaction.accountId);

    final batch = _firestore.batch();
    batch.set(transactionRef, transaction.copyWith(id: transactionRef.id).toMap());
    batch.update(accountRef, {'balance': newBalance});
    await batch.commit();
  }

  /// Atomically add a transfer transaction and update both accounts
  Future<void> addTransferAndUpdateBalances({
    required Transaction transaction,
    required double sourceNewBalance,
    required double destNewBalance,
  }) async {
    final userId = transaction.userId;
    final transactionRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .doc();
    final sourceAccountRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('accounts')
      .doc(transaction.accountId);
    final destAccountRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('accounts')
      .doc(transaction.toAccountId);

    final batch = _firestore.batch();
    batch.set(transactionRef, transaction.copyWith(id: transactionRef.id).toMap());
    batch.update(sourceAccountRef, {'balance': sourceNewBalance});
    batch.update(destAccountRef, {'balance': destNewBalance});
    await batch.commit();
  }
}
