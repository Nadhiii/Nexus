import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../services/transaction_service.dart';
import '../services/transaction_engine.dart';
import 'notification_provider.dart';
import 'budget_provider.dart';
import 'account_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final TransactionEngine _transactionEngine = TransactionEngine();

  NotificationProvider? _notificationProvider;
  BudgetProvider? _budgetProvider;
  AccountProvider? _accountProvider;
  StreamSubscription<List<Transaction>>? _transactionSubscription;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  TransactionProvider();

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
    if (_initializationFuture != null) return _initializationFuture!;
    _initializationFuture = _initialize();
    return _initializationFuture!;
  }

  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

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
    if (user == null) {
      return;
    }

    final firstSnapshot = Completer<void>();
    try {
      // Cancel previous subscription to avoid multiple listeners
      await _transactionSubscription?.cancel();

      _transactionSubscription = _transactionService
          .watchUserTransactions(user.uid)
          .listen(
            (transactions) {
              debugPrint(
                '📊 TransactionProvider: Loaded ${transactions.length} transactions',
              );
              _transactions = transactions;
              notifyListeners();
              if (!firstSnapshot.isCompleted) firstSnapshot.complete();
            },
            onError: (error) {
              debugPrint('❌ TransactionProvider Error: $error');
              _setError('Failed to load transactions: $error');
              if (!firstSnapshot.isCompleted) firstSnapshot.complete();
            },
          );
      await firstSnapshot.future;
    } catch (e) {
      debugPrint('❌ TransactionProvider Catch: $e');
      _setError('Failed to load transactions: $e');
      if (!firstSnapshot.isCompleted) firstSnapshot.complete();
    }
  }

  Future<Transaction?> findBySourceFingerprint(String fingerprint) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || fingerprint.isEmpty) return null;
    return _transactionService.findBySourceFingerprint(user.uid, fingerprint);
  }

  /// Commits every new financial fact through the same application-layer
  /// use case. A source fingerprint is an idempotency key; it never becomes
  /// the ledger document id.
  Future<TransactionCommitResult?> commitDraft(TransactionDraft draft) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return null;
    }

    try {
      final transaction = draft.toTransaction(userId: user.uid);
      String? committedId;
      if (!transaction.amount.isFinite ||
          (transaction.type != TransactionType.adjustment &&
              transaction.amount <= 0) ||
          transaction.accountId.isEmpty) {
        _setError('Enter a valid amount and account');
        return null;
      }
      if (transaction.type == TransactionType.transfer &&
          (transaction.toAccountId == null ||
              transaction.toAccountId == transaction.accountId)) {
        _setError('Choose different source and destination accounts');
        return null;
      }
      // Source-backed transactions must be idempotent. NBox can receive the
      // same SMS/email again after a rescan, restart, or delayed listener.
      // Check Firestore as well as the local stream so deletion/recreation is
      // reflected immediately rather than relying on listener timing.
      final sourceFingerprint = transaction.metadata?['sourceFingerprint']
          ?.toString();
      final source = transaction.metadata?['source']?.toString();
      if (sourceFingerprint != null && sourceFingerprint.isNotEmpty) {
        final existing = await _transactionService.findBySourceFingerprint(
          user.uid,
          sourceFingerprint,
        );
        if (existing != null) {
          final existingSource = existing.metadata?['source']?.toString();
          if (source == null || existingSource == source) {
            return TransactionCommitResult(
              transaction: existing,
              alreadyExists: true,
            );
          }
        }
      }

      _setLoading(true);

      debugPrint(
        '➕ Adding transaction: ${transaction.description}, amount: ${transaction.amount}, userId: ${transaction.userId}',
      );
      // Atomic transaction + account update
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        debugPrint('💸 Processing TRANSFER');
        final sourceAccount = _accountProvider!.getAccountById(
          transaction.accountId,
        );
        final destAccount = _accountProvider!.getAccountById(
          transaction.toAccountId!,
        );
        if (sourceAccount == null || destAccount == null) {
          _setError('Source or destination account not found');
          _setLoading(false);
          return null;
        }
        final sourceNewBalance = sourceAccount.balance - transaction.amount;
        final destNewBalance = destAccount.balance + transaction.amount;
        committedId = await _transactionEngine.commitTransfer(
          transaction: transaction,
          sourceNewBalance: sourceNewBalance,
          destinationNewBalance: destNewBalance,
        );
        debugPrint('✅ Transfer and balances committed atomically');
      } else {
        debugPrint('💰 Processing regular ${transaction.type}');
        final account = _accountProvider!.getAccountById(transaction.accountId);
        if (account == null) {
          _setError('Account not found');
          _setLoading(false);
          return null;
        }
        final newBalance = transaction.type == TransactionType.income
            ? account.balance + transaction.amount
            : account.balance - transaction.amount;
        committedId = await _transactionEngine.commit(
          transaction: transaction,
          newBalance: newBalance,
        );
        debugPrint('TransactionProvider: committed transaction $committedId');
        debugPrint('✅ Transaction and balance committed atomically');
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
      return TransactionCommitResult(
        transaction: transaction.copyWith(id: committedId),
      );
    } catch (e) {
      _setError('Failed to add transaction: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Compatibility wrapper for older screens. New transaction-producing
  /// flows should create a [TransactionDraft] and call [commitDraft].
  Future<bool> addTransaction(Transaction transaction) async {
    final result = await commitDraft(TransactionDraft.fromTransaction(transaction));
    return result != null && !result.alreadyExists;
  }

  /// Restores a previously deleted transaction (used for undo)
  /// This preserves the original transaction ID
  Future<bool> restoreTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return false;
    }

    try {
      debugPrint(
        '🔄 Restoring transaction: ${transaction.description}, id: ${transaction.id}',
      );
      debugPrint('📊 Current transactions count: ${_transactions.length}');

      // Use the same logic as addTransaction to restore atomically
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        debugPrint('💸 Restoring TRANSFER');
        final sourceAccount = _accountProvider!.getAccountById(
          transaction.accountId,
        );
        final destAccount = _accountProvider!.getAccountById(
          transaction.toAccountId!,
        );
        if (sourceAccount == null || destAccount == null) {
          _setError('Source or destination account not found');
          return false;
        }
        final sourceNewBalance = sourceAccount.balance - transaction.amount;
        final destNewBalance = destAccount.balance + transaction.amount;
        await _transactionEngine.commitTransfer(
          transaction: transaction,
          sourceNewBalance: sourceNewBalance,
          destinationNewBalance: destNewBalance,
        );
        debugPrint('✅ Transfer restore committed atomically');
      } else {
        debugPrint('💰 Restoring regular ${transaction.type}');
        final account = _accountProvider!.getAccountById(transaction.accountId);
        if (account == null) {
          _setError('Account not found');
          return false;
        }
        final newBalance = transaction.type == TransactionType.income
            ? account.balance + transaction.amount
            : account.balance - transaction.amount;
        await _transactionEngine.commit(
          transaction: transaction,
          newBalance: newBalance,
        );
        debugPrint('✅ Transaction restore committed atomically');
      }

      // Manually add to local list if not already present (stream may be delayed)
      final alreadyExists = _transactions.any((t) => t.id == transaction.id);
      if (!alreadyExists) {
        _transactions = [..._transactions, transaction];
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      // Always notify listeners to ensure UI updates
      debugPrint(
        '🔔 Calling notifyListeners() - transaction count: ${_transactions.length}',
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Restore failed: $e');
      _setError('Failed to restore transaction: $e');
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

      final accountBalances = <String, double>{};

      double calcNewBalance(
        String acctId,
        double amt,
        bool isIncome,
        bool isReversal,
      ) {
        final acct = _accountProvider!.getAccountById(acctId);
        if (acct == null) return 0;
        double bal = accountBalances[acctId] ?? acct.balance;
        if (isReversal) {
          bal = isIncome ? bal - amt : bal + amt;
        } else {
          bal = isIncome ? bal + amt : bal - amt;
        }
        return bal;
      }

      // 1. Reverse original
      if (originalTransaction.type == TransactionType.transfer &&
          originalTransaction.toAccountId != null) {
        accountBalances[originalTransaction.accountId] = calcNewBalance(
          originalTransaction.accountId,
          originalTransaction.amount,
          false,
          true,
        );
        accountBalances[originalTransaction.toAccountId!] = calcNewBalance(
          originalTransaction.toAccountId!,
          originalTransaction.amount,
          true,
          true,
        );
      } else {
        final isIncome = originalTransaction.type == TransactionType.income;
        accountBalances[originalTransaction.accountId] = calcNewBalance(
          originalTransaction.accountId,
          originalTransaction.amount,
          isIncome,
          true,
        );
      }

      // 2. Apply new
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        accountBalances[transaction.accountId] = calcNewBalance(
          transaction.accountId,
          transaction.amount,
          false,
          false,
        );
        accountBalances[transaction.toAccountId!] = calcNewBalance(
          transaction.toAccountId!,
          transaction.amount,
          true,
          false,
        );
      } else {
        final isIncome = transaction.type == TransactionType.income;
        accountBalances[transaction.accountId] = calcNewBalance(
          transaction.accountId,
          transaction.amount,
          isIncome,
          false,
        );
      }

      await _transactionEngine.update(
        oldTransaction: originalTransaction,
        newTransaction: transaction,
        accountBalances: accountBalances,
      );

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
      final transaction = getTransactionById(transactionId);
      if (transaction == null) {
        _setError('Transaction no longer exists. Refresh and try again.');
        return false;
      }
      final accountBalances = <String, double>{};

      double calcNewBalance(
        String acctId,
        double amt,
        bool isIncome,
        bool isReversal,
      ) {
        final acct = _accountProvider!.getAccountById(acctId);
        if (acct == null) return 0;
        double bal = accountBalances[acctId] ?? acct.balance;
        if (isReversal) {
          bal = isIncome ? bal - amt : bal + amt;
        } else {
          bal = isIncome ? bal + amt : bal - amt;
        }
        return bal;
      }

      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        accountBalances[transaction.accountId] = calcNewBalance(
          transaction.accountId,
          transaction.amount,
          false,
          true,
        );
        accountBalances[transaction.toAccountId!] = calcNewBalance(
          transaction.toAccountId!,
          transaction.amount,
          true,
          true,
        );
      } else {
        final isIncome = transaction.type == TransactionType.income;
        accountBalances[transaction.accountId] = calcNewBalance(
          transaction.accountId,
          transaction.amount,
          isIncome,
          true,
        );
      }

      await _transactionEngine.delete(
        transaction: transaction,
        accountBalances: accountBalances,
      );

      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    await _transactionService.clearAllTransactions(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
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

  /// Recalculates account balance from all transactions for a specific account
  Future<void> recalculateAccountBalance(String accountId) async {
    if (_accountProvider == null) {
      debugPrint('❌ AccountProvider not available');
      return;
    }
    if (accountId.isEmpty) {
      debugPrint('⚠️ Skipping recalculation: empty accountId');
      return;
    }

    try {
      debugPrint('🔢 Recalculating balance for account: $accountId');

      // Get all transactions for this account
      final accountTransactions = _transactions
          .where((t) => t.accountId == accountId || t.toAccountId == accountId)
          .toList();

      debugPrint(
        '📊 Found ${accountTransactions.length} transactions for this account',
      );

      // Calculate balance from transactions
      double calculatedBalance = 0.0;

      for (final transaction in accountTransactions) {
        if (transaction.type == TransactionType.income) {
          calculatedBalance += transaction.amount;
          debugPrint(
            '  ➕ Income: +${transaction.amount} (${transaction.description})',
          );
        } else if (transaction.type == TransactionType.expense) {
          calculatedBalance -= transaction.amount;
          debugPrint(
            '  ➖ Expense: -${transaction.amount} (${transaction.description})',
          );
        } else if (transaction.type == TransactionType.transfer) {
          if (transaction.accountId == accountId) {
            // Money going out (source account)
            calculatedBalance -= transaction.amount;
            debugPrint(
              '  ➖ Transfer Out: -${transaction.amount} (${transaction.description})',
            );
          } else if (transaction.toAccountId == accountId) {
            // Money coming in (destination account)
            calculatedBalance += transaction.amount;
            debugPrint(
              '  ➕ Transfer In: +${transaction.amount} (${transaction.description})',
            );
          }
        }
      }

      debugPrint('💰 Calculated balance: $calculatedBalance');

      // Update the account balance
      await _accountProvider!.updateAccountBalance(
        accountId,
        calculatedBalance,
      );
      debugPrint('✅ Account balance recalculated and updated');
    } catch (e) {
      debugPrint('❌ Error recalculating balance: $e');
      _setError('Failed to recalculate balance: $e');
    }
  }

  /// Prints a detailed ledger summary for an account to diagnose mismatches
  void printAccountLedgerSummary(String accountId, {int lastN = 20}) {
    final txns =
        _transactions
            .where(
              (t) => t.accountId == accountId || t.toAccountId == accountId,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    double running = 0.0;
    debugPrint('📒 Ledger for account=$accountId, total txns=${txns.length}');

    for (final t in txns) {
      double delta = 0.0;
      String kind = '';
      if (t.type == TransactionType.income) {
        delta = t.amount;
        kind = 'INCOME';
      } else if (t.type == TransactionType.expense) {
        delta = -t.amount;
        kind = 'EXPENSE';
      } else if (t.type == TransactionType.transfer) {
        if (t.accountId == accountId) {
          delta = -t.amount;
          kind = 'TRANSFER OUT';
        } else if (t.toAccountId == accountId) {
          delta = t.amount;
          kind = 'TRANSFER IN';
        }
      }
      running += delta;
      debugPrint(
        '  ${t.date.toIso8601String()}  ${kind.padRight(12)}  ${delta.toStringAsFixed(2).padLeft(8)}  ->  ${running.toStringAsFixed(2).padLeft(10)}  (${t.description ?? ''})',
      );
    }

    // Print last N for quick view
    final start = (txns.length - lastN) < 0 ? 0 : (txns.length - lastN);
    final recent = txns.sublist(start);
    debugPrint('🧾 Last $lastN entries:');
    for (final t in recent) {
      final isDst = t.toAccountId == accountId;
      final sign = t.type == TransactionType.income || isDst ? '+' : '-';
      debugPrint(
        '  $sign${t.amount.toStringAsFixed(2)}  ${t.description ?? ''}',
      );
    }
    debugPrint('✅ Computed balance from ledger: ${running.toStringAsFixed(2)}');
  }

  void clear() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
    _transactions.clear();
    _isInitialized = false;
    _initializationFuture = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}

class TransactionCommitResult {
  final Transaction transaction;
  final bool alreadyExists;

  const TransactionCommitResult({
    required this.transaction,
    this.alreadyExists = false,
  });
}
