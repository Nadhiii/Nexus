import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../../models/detected_transaction.dart';
import 'notification_provider.dart';
import 'budget_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  NotificationProvider? notificationProvider;
  BudgetProvider? budgetProvider;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TransactionProvider({this.notificationProvider, this.budgetProvider});

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

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
      _transactionService.watchUserTransactions(user.uid).listen(
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
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);

      await _transactionService.createTransaction(user.uid, transaction);
      await _updateAccountBalance(transaction.accountId, transaction.amount, transaction.type);

      // Notification Logic
      notificationProvider?.notifyTransaction(
        transaction.description ?? 'New Transaction',
        transaction.amount,
        transaction.type == TransactionType.income,
      );

      // Budget Check Logic
      if (transaction.type == TransactionType.expense && budgetProvider != null) {
        await budgetProvider!.checkBudgetForTransaction(transaction);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction, Transaction originalTransaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);

      await _transactionService.updateTransaction(user.uid, transaction);
      await _reverseTransactionOnAccount(originalTransaction);
      await _updateAccountBalance(transaction.accountId, transaction.amount, transaction.type);

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
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);

      final transaction = _transactions.firstWhere((t) => t.id == transactionId);
      await _transactionService.deleteTransaction(user.uid, transactionId);
      await _reverseTransactionOnAccount(transaction);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      _setLoading(false);
      return false;
    } 
  }

  Future<void> _updateAccountBalance(String accountId, double amount, TransactionType type) async {
    final accountDoc = FirebaseFirestore.instance.collection('accounts').doc(accountId);
    final accountSnapshot = await accountDoc.get();

    if (accountSnapshot.exists) {
      final currentBalance = (accountSnapshot.data()?['balance'] ?? 0.0).toDouble();
      final newBalance = type == TransactionType.income
          ? currentBalance + amount
          : currentBalance - amount;
      await accountDoc.update({'balance': newBalance});
    }
  }

  Future<void> _reverseTransactionOnAccount(Transaction transaction) async {
    final accountDoc = FirebaseFirestore.instance.collection('accounts').doc(transaction.accountId);
    final accountSnapshot = await accountDoc.get();

    if (accountSnapshot.exists) {
      final currentBalance = (accountSnapshot.data()?['balance'] ?? 0.0).toDouble();
      final newBalance = transaction.type == TransactionType.income
          ? currentBalance - transaction.amount
          : currentBalance + transaction.amount;
      await accountDoc.update({'balance': newBalance});
    }
  }

  Transaction? getTransactionById(String transactionId) {
    try {
      return _transactions.firstWhere((transaction) => transaction.id == transactionId);
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
