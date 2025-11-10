// Deprecated duplicate. Use transaction_provider.dart instead.
export 'transaction_provider.dart';
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider with user data
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadTransactions();
    }
  }

  // Load all transactions
  Future<void> loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final transactions = await _transactionService.getUserTransactions(
        user.uid,
      );
      _transactions = transactions;

      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setError('Failed to load transactions: $error');
      _setLoading(false);
    }
  }

  // Load transactions for a specific account
  Future<void> loadTransactionsForAccount(String accountId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final transactions = await _transactionService.getAccountTransactions(
        user.uid,
        accountId,
      );
      _transactions = transactions;

      _setLoading(false);
      notifyListeners();
    } catch (error) {
      _setError('Failed to load account transactions: $error');
      _setLoading(false);
    }
  }

  // Get transactions for a specific account
  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  // Get transactions by type
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Get transactions for a date range
  List<Transaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Create the transaction
      await _transactionService.createTransaction(user.uid, transaction);

      // Update account balance based on transaction type
      await _updateAccountBalance(user.uid, transaction);

      // Reload transactions
      await loadTransactions();

      _setLoading(false);
    } catch (error) {
      _setError('Failed to add transaction: $error');
      _setLoading(false);
    }
  }

  // Helper method to update account balance based on transaction
  Future<void> _updateAccountBalance(
    String userId,
    Transaction transaction,
  ) async {
    try {
      // Get current account
      final account = await _accountService.getAccount(
        userId,
        transaction.accountId,
      );
      if (account == null) return;

      double newBalance = account.balance;

      // Calculate new balance based on transaction type
      switch (transaction.type) {
        case TransactionType.income:
          newBalance += transaction.amount; // Add income
          break;
        case TransactionType.expense:
          newBalance -= transaction.amount; // Subtract expense
          break;
        case TransactionType.transfer:
          // For transfers, we need to handle both accounts
          newBalance -= transaction.amount; // Subtract from source account
          // TODO: Add to destination account if it exists
          break;
      }

      // Update the account balance
      await _accountService.updateAccountBalance(
        userId,
        transaction.accountId,
        newBalance,
      );
    } catch (e) {
      print('Error updating account balance: $e');
      // Don't throw here to avoid breaking transaction creation
    }
  }

  // Update a transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();

      await _transactionService.updateTransaction(user.uid, transaction);
      await loadTransactions();

      _setLoading(false);
    } catch (error) {
      _setError('Failed to update transaction: $error');
      _setLoading(false);
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('TransactionProvider: No user found for delete operation');
      return;
    }

    print(
      'TransactionProvider: Starting delete for transaction ID: $transactionId',
    );

    try {
      _setLoading(true);
      _clearError();

      // Get the transaction before deleting to reverse its effect on account balance
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      print(
        'TransactionProvider: Found transaction to delete: ${transaction.description}',
      );

      // Delete the transaction
      await _transactionService.deleteTransaction(user.uid, transactionId);
      print('TransactionProvider: Transaction deleted from Firebase');

      // Reverse the account balance change
      await _reverseAccountBalance(user.uid, transaction);
      print('TransactionProvider: Account balance reversed');

      // Reload transactions
      await loadTransactions();
      print('TransactionProvider: Transactions reloaded');

      _setLoading(false);
    } catch (error) {
      print('TransactionProvider: Error deleting transaction: $error');
      _setError('Failed to delete transaction: $error');
      _setLoading(false);
    }
  }

  // Helper method to reverse account balance when transaction is deleted
  Future<void> _reverseAccountBalance(
    String userId,
    Transaction transaction,
  ) async {
    try {
      // Get current account
      final account = await _accountService.getAccount(
        userId,
        transaction.accountId,
      );
      if (account == null) return;

      double newBalance = account.balance;

      // Reverse the transaction effect
      switch (transaction.type) {
        case TransactionType.income:
          newBalance -= transaction.amount; // Remove income
          break;
        case TransactionType.expense:
          newBalance += transaction.amount; // Add back expense
          break;
        case TransactionType.transfer:
          newBalance += transaction.amount; // Add back transfer amount
          break;
      }

      // Update the account balance
      await _accountService.updateAccountBalance(
        userId,
        transaction.accountId,
        newBalance,
      );
    } catch (e) {
      print('Error reversing account balance: $e');
      // Don't throw here to avoid breaking transaction deletion
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
