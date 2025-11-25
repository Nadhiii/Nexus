import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/learning_service.dart';
import 'notification_provider.dart';
import 'budget_provider.dart';
import 'account_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final LearningService _learningService;

  NotificationProvider? _notificationProvider;
  BudgetProvider? _budgetProvider;
  AccountProvider? _accountProvider;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  TransactionProvider({required LearningService learningService})
    : _learningService = learningService;

  void update(
    AccountProvider account,
    BudgetProvider budget,
    NotificationProvider notification,
  ) {
    _accountProvider = account;
    _budgetProvider = budget;
    _notificationProvider = notification;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      await loadTransactions();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _transactionService
          .watchUserTransactions(user.uid)
          .listen(
            (transactions) {
              _transactions = transactions;
              notifyListeners();
            },
            onError: (error) {
              _setError('Failed to load transactions: $error');
            },
          );
    } catch (e) {
      _setError('Failed to load transactions: $e');
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return false;
    }

    try {
      _setLoading(true);

      await _transactionService.addTransaction(transaction);
      await _updateAccountBalance(
        transaction.accountId,
        transaction.amount,
        transaction.type,
        isReversal: false,
      );

      if (transaction.description != null && transaction.categoryId != null) {
        await _learningService.learn(
          transaction.description!,
          transaction.categoryId!,
        );
      }

      _notificationProvider?.notifyTransaction(
        transaction.description ?? 'New Transaction',
        transaction.amount,
        transaction.type == TransactionType.income,
      );

      if (transaction.type == TransactionType.expense &&
          _budgetProvider != null) {
        await _budgetProvider!.checkBudgetForTransaction(transaction);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTransaction(
    Transaction transaction,
    Transaction originalTransaction,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return false;
    }

    try {
      _setLoading(true);

      await _transactionService.updateTransaction(transaction);

      // Only update account balances if amount, type, or account changed
      final bool amountChanged =
          transaction.amount != originalTransaction.amount;
      final bool typeChanged = transaction.type != originalTransaction.type;
      final bool accountChanged =
          transaction.accountId != originalTransaction.accountId;

      if (amountChanged || typeChanged || accountChanged) {
        // Reverse the old transaction amount from its original account
        await _updateAccountBalance(
          originalTransaction.accountId,
          originalTransaction.amount,
          originalTransaction.type,
          isReversal: true,
        );
        // Apply the new transaction amount to its (potentially new) account
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          transaction.type,
          isReversal: false,
        );
      }

      if (transaction.description != null && transaction.categoryId != null) {
        await _learningService.learn(
          transaction.description!,
          transaction.categoryId!,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return false;
    }

    try {
      _setLoading(true);

      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
      );
      await _transactionService.deleteTransaction(transactionId);
      await _updateAccountBalance(
        transaction.accountId,
        transaction.amount,
        transaction.type,
        isReversal: true,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _updateAccountBalance(
    String accountId,
    double amount,
    TransactionType type, {
    required bool isReversal,
  }) async {
    final account = _accountProvider!.getAccountById(accountId);
    if (account == null) return;

    double newBalance;
    if (isReversal) {
      newBalance = type == TransactionType.income
          ? account.balance - amount
          : account.balance + amount;
    } else {
      newBalance = type == TransactionType.income
          ? account.balance + amount
          : account.balance - amount;
    }
    await _accountProvider!.updateAccountBalance(accountId, newBalance);
  }

  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _transactionService.clearAllTransactions(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final transactions = data
        .map((d) => Transaction.fromJson(d as Map<String, dynamic>))
        .toList();
    await _transactionService.restoreTransactions(user.uid, transactions);
  }

  Transaction? getTransactionById(String transactionId) {
    try {
      return _transactions.firstWhere(
        (transaction) => transaction.id == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _transactions.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
