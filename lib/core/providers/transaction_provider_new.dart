// Deprecated duplicate. Use transaction_provider.dart instead.
export 'transaction_provider.dart';

  TransactionProvider(this._accountProvider);

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
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

      // Update account balance
      await _updateAccountBalance(user.uid, transaction);
      print('TransactionProvider: Account balance updated');

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

      // Reverse the old transaction's effect on account balance
      await _reverseAccountBalance(user.uid, oldTransaction);

      // Update the transaction
      await _transactionService.updateTransaction(user.uid, newTransaction);

      // Apply the new transaction's effect on account balance
      await _updateAccountBalance(user.uid, newTransaction);

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

      // Reverse the transaction's effect on account balance
      await _reverseAccountBalance(user.uid, transaction);
      print('TransactionProvider: Account balance reversed');

      _setLoading(false);
      return true;
    } catch (e) {
      print('TransactionProvider: Error deleting transaction: $e');
      _setError('Failed to delete transaction: $e');
      _setLoading(false);
      return false;
    }
  }

  // Helper method to update account balance when transaction is added
  Future<void> _updateAccountBalance(
    String userId,
    Transaction transaction,
  ) async {
    try {
      final account = _accountProvider.getAccountById(transaction.accountId);
      if (account == null) {
        print('Account not found: ${transaction.accountId}');
        return;
      }

      double newBalance = account.balance;

      switch (transaction.type) {
        case TransactionType.income:
          newBalance += transaction.amount;
          break;
        case TransactionType.expense:
          newBalance -= transaction.amount;
          break;
        case TransactionType.transfer:
          // For transfers, deduct from source account
          newBalance -= transaction.amount;
          // Add to destination account if specified
          if (transaction.toAccountId != null) {
            final toAccount = _accountProvider.getAccountById(
              transaction.toAccountId!,
            );
            if (toAccount != null) {
              await _accountProvider.updateAccountBalance(
                transaction.toAccountId!,
                toAccount.balance + transaction.amount,
              );
            }
          }
          break;
      }

      await _accountProvider.updateAccountBalance(
        transaction.accountId,
        newBalance,
      );
      print('Account balance updated: ${account.name} -> $newBalance');
    } catch (e) {
      print('Error updating account balance: $e');
      rethrow;
    }
  }

  // Helper method to reverse account balance when transaction is deleted/updated
  Future<void> _reverseAccountBalance(
    String userId,
    Transaction transaction,
  ) async {
    try {
      final account = _accountProvider.getAccountById(transaction.accountId);
      if (account == null) {
        print('Account not found for reversal: ${transaction.accountId}');
        return;
      }

      double newBalance = account.balance;

      switch (transaction.type) {
        case TransactionType.income:
          newBalance -= transaction.amount; // Remove the income
          break;
        case TransactionType.expense:
          newBalance += transaction.amount; // Add back the expense
          break;
        case TransactionType.transfer:
          // For transfers, add back to source account
          newBalance += transaction.amount;
          // Remove from destination account if specified
          if (transaction.toAccountId != null) {
            final toAccount = _accountProvider.getAccountById(
              transaction.toAccountId!,
            );
            if (toAccount != null) {
              await _accountProvider.updateAccountBalance(
                transaction.toAccountId!,
                toAccount.balance - transaction.amount,
              );
            }
          }
          break;
      }

      await _accountProvider.updateAccountBalance(
        transaction.accountId,
        newBalance,
      );
      print('Account balance reversed: ${account.name} -> $newBalance');
    } catch (e) {
      print('Error reversing account balance: $e');
      // Don't throw here to avoid breaking transaction deletion
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
