// Deprecated duplicate. Use account_provider.dart instead.
export 'account_provider.dart';

  List<Account> _accounts = [];
  Account? _selectedAccount;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Account> get accounts => List.unmodifiable(_accounts);
  Account? get selectedAccount => _selectedAccount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAccounts => _accounts.isNotEmpty;

  // Total balance across all accounts
  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

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

  // Initialize accounts for the current user
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _clearError();
      await loadAccounts();
    } catch (e) {
      _setError('Failed to initialize accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all accounts for the current user
  Future<void> loadAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Listen to account changes
      _accountService
          .watchUserAccounts(user.uid)
          .listen(
            (accounts) {
              _accounts = accounts;
              // Update selected account if it's no longer valid
              if (_selectedAccount != null &&
                  !_accounts.any((a) => a.id == _selectedAccount!.id)) {
                _selectedAccount = null;
              }
              notifyListeners();
            },
            onError: (error) {
              _setError('Failed to load accounts: $error');
            },
          );
    } catch (e) {
      _setError('Failed to load accounts: $e');
    }
  }

  // Create a new account
  Future<bool> createAccount(Account account) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      print('AccountProvider: Creating account: ${account.name}');
      print('AccountProvider: Account balance: ${account.balance}');

      // Create the account
      final accountId = await _accountService.createAccount(user.uid, account);
      print('AccountProvider: Account created with ID: $accountId');

      // Create opening balance transaction if balance > 0
      if (account.balance > 0) {
        final openingTransaction = Transaction(
          id: '', // Will be set by service
          type: TransactionType.income,
          amount: account.balance,
          description: 'Opening Balance',
          categoryId: 'opening_balance',
          accountId: accountId,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _transactionService.createTransaction(
          user.uid,
          openingTransaction,
        );
        print('AccountProvider: Opening balance transaction created');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      print('AccountProvider: Error creating account: $e');
      _setError('Failed to create account: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an account
  Future<bool> updateAccount(Account account) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _accountService.updateAccount(user.uid, account);

      // Update local state
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        if (_selectedAccount?.id == account.id) {
          _selectedAccount = account;
        }
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update account: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete an account
  Future<bool> deleteAccount(String accountId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _accountService.deleteAccount(user.uid, accountId);

      // Update local state
      _accounts.removeWhere((a) => a.id == accountId);
      if (_selectedAccount?.id == accountId) {
        _selectedAccount = null;
      }
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete account: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get account by ID
  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  // Set selected account
  void setSelectedAccount(Account? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  // Update account balance (called by transaction operations)
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _accountService.updateAccountBalance(
        user.uid,
        accountId,
        newBalance,
      );

      // Update local state
      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        );

        if (_selectedAccount?.id == accountId) {
          _selectedAccount = _accounts[index];
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error updating account balance: $e');
    }
  }

  // Clear all data (for logout)
  void clear() {
    _accounts.clear();
    _selectedAccount = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
