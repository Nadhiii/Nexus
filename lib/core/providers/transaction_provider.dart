import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TransactionProvider();

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error state
  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
  }

  // Initialize transactions for the current user
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();
      await loadTransactions();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all transactions for the current user
  Future<void> loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Listen to transaction changes
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

  // Get transactions for a specific account
  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactions
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  // Add a new transaction
  Future<bool> addTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      print(
        'TransactionProvider: Adding transaction: ${transaction.description}',
      );
      print('TransactionProvider: Account ID: ${transaction.accountId}');
      print('TransactionProvider: Amount: ${transaction.amount}');
      print('TransactionProvider: Type: ${transaction.type}');

      // Create the transaction
      await _transactionService.createTransaction(user.uid, transaction);
      print('TransactionProvider: Transaction created successfully');

      // TODO: Update account balance - requires context
      // await _updateAccountBalance(user.uid, transaction);
      print(
        'TransactionProvider: Transaction created (balance update skipped)',
      );

      _setLoading(false);
      return true;
    } catch (e) {
      print('TransactionProvider: Error adding transaction: $e');
      _setError('Failed to add transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update a transaction
  Future<bool> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      print(
        'TransactionProvider: Updating transaction: ${newTransaction.description}',
      );

      // TODO: Reverse the old transaction's effect on account balance - requires context
      // await _reverseAccountBalance(user.uid, oldTransaction);

      // Update the transaction
      await _transactionService.updateTransaction(user.uid, newTransaction);

      // TODO: Apply the new transaction's effect on account balance - requires context
      // await _updateAccountBalance(user.uid, newTransaction);

      print(
        'TransactionProvider: Transaction updated (balance updates skipped)',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      print('TransactionProvider: Error updating transaction: $e');
      _setError('Failed to update transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      print('TransactionProvider: Deleting transaction: $transactionId');

      // Find the transaction to get its details before deleting
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      print(
        'TransactionProvider: Found transaction to delete: ${transaction.description}',
      );

      // Delete the transaction
      await _transactionService.deleteTransaction(user.uid, transactionId);
      print('TransactionProvider: Transaction deleted from database');

      // TODO: Reverse the transaction's effect on account balance - requires context
      // await _reverseAccountBalance(user.uid, transaction);
      print(
        'TransactionProvider: Transaction deleted (balance reversal skipped)',
      );

      _setLoading(false);
      return true;
    } catch (e) {
      print('TransactionProvider: Error deleting transaction: $e');
      _setError('Failed to delete transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get transaction by ID
  Transaction? getTransactionById(String transactionId) {
    try {
      return _transactions.firstWhere(
        (transaction) => transaction.id == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear all data (for logout)
  void clear() {
    _transactions.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Get transactions by date range
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get summary statistics
  Map<String, double> getSummary({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filteredTransactions = _transactions.where((t) {
      bool matchesAccount = accountId == null || t.accountId == accountId;
      bool matchesDate = true;

      if (startDate != null) {
        matchesDate =
            matchesDate &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1)));
      }

      if (endDate != null) {
        matchesDate =
            matchesDate &&
            t.date.isBefore(endDate.add(const Duration(days: 1)));
      }

      return matchesAccount && matchesDate;
    });

    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        totalExpense += transaction.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
}
