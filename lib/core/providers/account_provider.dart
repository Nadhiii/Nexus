import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  double get totalBalance =>
      _accounts.fold(0.0, (sum, account) => sum + account.balance);
  double get netWorth => totalBalance; // Simplified for now

  AccountProvider() {
    initialize();
  }

  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user != null && !_isInitialized) {
      await _loadAccounts(user.uid);
      _isInitialized = true;
    }
  }

  Future<void> _loadAccounts(String userId) async {
    _setLoading(true);
    try {
      _accountService
          .watchAccounts(userId)
          .listen(
            (accounts) {
              _accounts = accounts;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Error loading accounts: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> addAccount(Account account) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      await _accountService.addAccount(user.uid, account);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccount(Account account) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      await _accountService.updateAccount(user.uid, account);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      print(
        '💰 AccountProvider.updateAccountBalance: accountId=$accountId, newBalance=$newBalance',
      );
      await _accountService.updateAccountBalance(
        user.uid,
        accountId,
        newBalance,
      );
      print('✅ AccountProvider: Balance updated in Firestore');
    } catch (e) {
      print('❌ AccountProvider: Failed to update balance: $e');
      _setError('Failed to update account balance: $e');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      await _accountService.deleteAccount(user.uid, accountId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Permanently deletes any account documents matching the given name.
  /// Useful for cleaning up orphaned accounts (e.g., 'SBI').
  Future<int> purgeAccountByName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    try {
      final count = await _accountService.purgeAccountsByName(user.uid, name);
      print('🧹 Purged $count account(s) named "$name"');
      return count;
    } catch (e) {
      print('❌ Failed to purge account "$name": $e');
      _setError('Failed to purge account "$name": $e');
      return 0;
    }
  }

  Account? getAccountById(String id) {
    print('🔍 getAccountById called with id: "$id"');
    print(
      '📋 Available accounts: ${_accounts.map((a) => '"${a.id}":${a.name}').toList()}',
    );
    try {
      final account = _accounts.firstWhere((acc) => acc.id == id);
      print('✅ Found account: ${account.name}');
      return account;
    } catch (e) {
      print('❌ Account not found for id: "$id"');
      return null;
    }
  }

  Future<void> clearAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _accountService.clearAllAccounts(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final accounts = data
        .map((d) => Account.fromJson(d as Map<String, dynamic>))
        .toList();
    await _accountService.restoreAccounts(user.uid, accounts);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void clear() {
    _accounts = [];
    _isInitialized = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
