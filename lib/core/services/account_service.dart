import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Color getDefaultColor(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Colors.blue;
      case AccountType.salary:
        return Colors.green;
      case AccountType.checking:
        return Colors.orange;
      case AccountType.investment:
        return Colors.purple;
      case AccountType.cash:
        return Colors.teal;
      case AccountType.other:
        return Colors.grey;
    }
  }

  static IconData getDefaultIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.salary:
        return Icons.account_balance_wallet;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.cash:
        return Icons.money;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }

  CollectionReference<Map<String, dynamic>> _getAccountsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  Future<int> purgeAccountsByName(String userId, String name) async {
    final coll = _getAccountsCollection(userId);
    final snapshot = await coll.where('name', isEqualTo: name).get();
    int count = 0;
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
      count++;
    }
    return count;
  }

  Stream<List<Account>> watchAccounts(String userId) {
    return _getAccountsCollection(userId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addAccount(String userId, Account account) async {
    final docRef = _getAccountsCollection(userId).doc();
    await docRef.set(account.copyWith(id: docRef.id).toMap());
  }

  Future<void> updateAccount(String userId, Account account) {
    return _getAccountsCollection(
      userId,
    ).doc(account.id).update(account.toMap());
  }

  Future<void> deleteAccount(String userId, String accountId) {
    return _getAccountsCollection(userId).doc(accountId).delete();
  }

  Future<void> updateAccountBalance(
    String userId,
    String accountId,
    double newBalance,
  ) {
    return _getAccountsCollection(
      userId,
    ).doc(accountId).update({'balance': newBalance});
  }

  Future<void> clearAllAccounts(String userId) async {
    final snapshot = await _getAccountsCollection(userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreAccounts(String userId, List<Account> accounts) async {
    final batch = _firestore.batch();
    for (final account in accounts) {
      final docRef = _getAccountsCollection(userId).doc(account.id);
      batch.set(docRef, account.toMap());
    }
    await batch.commit();
  }
}
