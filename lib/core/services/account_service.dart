import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference - now using root-level collection
  CollectionReference<Map<String, dynamic>> get _accountsCollection {
    return _firestore.collection('accounts');
  }

  // Create a new account
  Future<String> createAccount(String userId, Account account) async {
    try {
      final docRef = await _accountsCollection.add(account.toMap());

      // Update the account with the generated ID
      final updatedAccount = account.copyWith(id: docRef.id);
      await docRef.update(updatedAccount.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Get all accounts for a user
  Stream<List<Account>> watchUserAccounts(String userId) {
    return _accountsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Account.fromMap(data);
          }).toList();
        });
  }

  // Get a specific account
  Future<Account?> getAccount(String userId, String accountId) async {
    try {
      final doc = await _accountsCollection.doc(accountId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Account.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get account: $e');
    }
  }

  // Update an account
  Future<void> updateAccount(String userId, Account account) async {
    try {
      await _accountsCollection
          .doc(account.id)
          .update(account.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  // Update account balance
  Future<void> updateAccountBalance(
    String userId,
    String accountId,
    double newBalance,
  ) async {
    try {
      await _accountsCollection.doc(accountId).update({
        'balance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update account balance: $e');
    }
  }

  // Soft delete an account (mark as inactive)
  Future<void> deleteAccount(String userId, String accountId) async {
    try {
      await _accountsCollection.doc(accountId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Hard delete an account (permanent removal)
  Future<void> permanentDeleteAccount(String userId, String accountId) async {
    try {
      await _accountsCollection.doc(accountId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete account: $e');
    }
  }

  // Get accounts by type
  Stream<List<Account>> watchAccountsByType(
    String userId,
    List<AccountType> types,
  ) {
    return watchUserAccounts(userId).map((accounts) {
      return accounts.where((account) => types.contains(account.type)).toList();
    });
  }

  // Get assets (non-liability accounts)
  Stream<List<Account>> watchAssets(String userId) {
    return watchUserAccounts(userId).map((accounts) {
      return accounts.where((account) => account.isAsset).toList();
    });
  }

  // Get liabilities (credit cards, loans)
  Stream<List<Account>> watchLiabilities(String userId) {
    return watchUserAccounts(userId).map((accounts) {
      return accounts.where((account) => account.isLiability).toList();
    });
  }

  // Calculate total net worth
  Stream<double> watchNetWorth(String userId) {
    return watchUserAccounts(userId).map((accounts) {
      double totalAssets = 0;
      double totalLiabilities = 0;

      for (final account in accounts) {
        if (account.isAsset) {
          totalAssets += account.balance;
        } else {
          totalLiabilities += account.balance;
        }
      }

      return totalAssets - totalLiabilities;
    });
  }

  // Calculate total assets
  Stream<double> watchTotalAssets(String userId) {
    return watchAssets(userId).map((accounts) {
      return accounts.fold(0.0, (sum, account) => sum + account.balance);
    });
  }

  // Calculate total liabilities
  Stream<double> watchTotalLiabilities(String userId) {
    return watchLiabilities(userId).map((accounts) {
      return accounts.fold(0.0, (sum, account) => sum + account.balance);
    });
  }

  // Get default account icons for each type
  static IconData getDefaultIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.salary:
        return Icons.work;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.other:
        return Icons.account_box;
    }
  }

  // Get default account colors for each type
  static Color getDefaultColor(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Colors.green;
      case AccountType.salary:
        return Colors.blue;
      case AccountType.checking:
        return Colors.teal;
      case AccountType.investment:
        return Colors.purple;
      case AccountType.cash:
        return Colors.orange;
      case AccountType.other:
        return Colors.grey;
    }
  }
}
