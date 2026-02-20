import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/ledger_service.dart';
import 'notification_provider.dart';
import 'budget_provider.dart';
import 'account_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final LedgerService _ledgerService = LedgerService();

  NotificationProvider? _notificationProvider;
  BudgetProvider? _budgetProvider;
  AccountProvider? _accountProvider;
  StreamSubscription<List<Transaction>>? _transactionSubscription;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

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
      // Cancel previous subscription to avoid multiple listeners
      await _transactionSubscription?.cancel();

      _transactionSubscription = _transactionService
          .watchUserTransactions(user.uid)
          .listen(
            (transactions) {
              print(
                '📊 TransactionProvider: Loaded ${transactions.length} transactions',
              );
              _transactions = transactions;
              notifyListeners();
            },
            onError: (error) {
              print('❌ TransactionProvider Error: $error');
              _setError('Failed to load transactions: $error');
            },
          );
    } catch (e) {
      print('❌ TransactionProvider Catch: $e');
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

      print(
        '➕ Adding transaction: ${transaction.description}, amount: ${transaction.amount}, userId: ${transaction.userId}',
      );
      // Atomic transaction + account update
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        print('💸 Processing TRANSFER');
        final sourceAccount = _accountProvider!.getAccountById(
          transaction.accountId,
        );
        final destAccount = _accountProvider!.getAccountById(
          transaction.toAccountId!,
        );
        if (sourceAccount == null || destAccount == null) {
          _setError('Source or destination account not found');
          _setLoading(false);
          return false;
        }
        final sourceNewBalance = sourceAccount.balance - transaction.amount;
        final destNewBalance = destAccount.balance + transaction.amount;
        await _ledgerService.addTransferAndUpdateBalances(
          transaction: transaction,
          sourceNewBalance: sourceNewBalance,
          destNewBalance: destNewBalance,
        );
        print('✅ Transfer and balances committed atomically');
      } else {
        print('💰 Processing regular ${transaction.type}');
        final account = _accountProvider!.getAccountById(transaction.accountId);
        if (account == null) {
          _setError('Account not found');
          _setLoading(false);
          return false;
        }
        final newBalance = transaction.type == TransactionType.income
            ? account.balance + transaction.amount
            : account.balance - transaction.amount;
        await _ledgerService.addTransactionAndUpdateBalance(
          transaction: transaction,
          newBalance: newBalance,
        );
        print('✅ Transaction and balance committed atomically');
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

  /// Restores a previously deleted transaction (used for undo)
  /// This preserves the original transaction ID
  Future<bool> restoreTransaction(Transaction transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _accountProvider == null) {
      _setError('User or Account Provider not available');
      return false;
    }

    try {
      print(
        '🔄 Restoring transaction: ${transaction.description}, id: ${transaction.id}',
      );
      print('📊 Current transactions count: ${_transactions.length}');

      // Restore to Firestore
      await _transactionService.restoreTransaction(transaction);
      print('✅ Transaction restored to Firestore');

      // Manually add to local list if not already present (stream may be delayed)
      // Check by ID to prevent duplicates
      final alreadyExists = _transactions.any((t) => t.id == transaction.id);
      print('🔍 Transaction already in list: $alreadyExists');

      if (!alreadyExists) {
        _transactions = [..._transactions, transaction];
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        print('📋 Added to local list. New count: ${_transactions.length}');
      } else {
        print(
          '⚠️ Transaction already exists in list (stream updated), forcing UI refresh',
        );
      }

      // Always notify listeners to ensure UI updates
      print(
        '🔔 Calling notifyListeners() - transaction count: ${_transactions.length}',
      );
      notifyListeners();
      print('✅ notifyListeners() called');

      // Handle transfers between accounts
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        print('💸 Restoring TRANSFER balances');

        // Deduct from source account
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          TransactionType.expense,
          isReversal: false,
        );

        // Add to destination account
        await _updateAccountBalance(
          transaction.toAccountId!,
          transaction.amount,
          TransactionType.income,
          isReversal: false,
        );
      } else {
        // Regular transaction - update account balance
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          transaction.type,
          isReversal: false,
        );
      }

      print('✅ Restore complete');
      return true;
    } catch (e) {
      print('❌ Restore failed: $e');
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

      await _transactionService.updateTransaction(transaction);

      // Check what changed
      final bool amountChanged =
          transaction.amount != originalTransaction.amount;
      final bool typeChanged = transaction.type != originalTransaction.type;
      final bool accountChanged =
          transaction.accountId != originalTransaction.accountId;
      final bool toAccountChanged =
          transaction.toAccountId != originalTransaction.toAccountId;
      final bool wasTransfer =
          originalTransaction.type == TransactionType.transfer;
      final bool isTransfer = transaction.type == TransactionType.transfer;

      // Handle the complex case of transfers
      if (wasTransfer ||
          isTransfer ||
          amountChanged ||
          typeChanged ||
          accountChanged ||
          toAccountChanged) {
        // Step 1: Reverse the original transaction completely
        if (wasTransfer && originalTransaction.toAccountId != null) {
          // Original was a transfer - reverse both accounts
          await _updateAccountBalance(
            originalTransaction.accountId,
            originalTransaction.amount,
            TransactionType.expense,
            isReversal: true, // Add back to source
          );
          await _updateAccountBalance(
            originalTransaction.toAccountId!,
            originalTransaction.amount,
            TransactionType.income,
            isReversal: true, // Remove from destination
          );
          print(
            '✅ Reversed original transfer: ${originalTransaction.accountId} <- ${originalTransaction.toAccountId}',
          );
        } else if (!wasTransfer) {
          // Original was income/expense - reverse it
          await _updateAccountBalance(
            originalTransaction.accountId,
            originalTransaction.amount,
            originalTransaction.type,
            isReversal: true,
          );
          print(
            '✅ Reversed original ${originalTransaction.type}: ${originalTransaction.accountId}',
          );
        }

        // Step 2: Apply the new transaction
        if (isTransfer && transaction.toAccountId != null) {
          // New is a transfer - apply to both accounts
          await _updateAccountBalance(
            transaction.accountId,
            transaction.amount,
            TransactionType.expense,
            isReversal: false, // Deduct from source
          );
          await _updateAccountBalance(
            transaction.toAccountId!,
            transaction.amount,
            TransactionType.income,
            isReversal: false, // Add to destination
          );
          print(
            '✅ Applied new transfer: ${transaction.accountId} -> ${transaction.toAccountId}',
          );
        } else if (!isTransfer) {
          // New is income/expense - apply it
          await _updateAccountBalance(
            transaction.accountId,
            transaction.amount,
            transaction.type,
            isReversal: false,
          );
          print('✅ Applied new ${transaction.type}: ${transaction.accountId}');
        }
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
      // Find the transaction before deleting it
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
      );

      // Delete from Firestore - the stream subscription will auto-update _transactions
      await _transactionService.deleteTransaction(transactionId);

      // Handle transfer deletion - reverse both accounts
      if (transaction.type == TransactionType.transfer &&
          transaction.toAccountId != null) {
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          TransactionType.expense,
          isReversal: true, // Add back to source
        );
        await _updateAccountBalance(
          transaction.toAccountId!,
          transaction.amount,
          TransactionType.income,
          isReversal: true, // Remove from destination
        );
        print('✅ Deleted transfer: reversed both accounts');
      } else {
        await _updateAccountBalance(
          transaction.accountId,
          transaction.amount,
          transaction.type,
          isReversal: true,
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    }
  }

  Future<void> _updateAccountBalance(
    String accountId,
    double amount,
    TransactionType type, {
    required bool isReversal,
  }) async {
    print(
      '🔄 _updateAccountBalance called: accountId=$accountId, amount=$amount, type=$type, isReversal=$isReversal',
    );

    final account = _accountProvider!.getAccountById(accountId);
    if (account == null) {
      print('❌ Account not found for id: $accountId');
      print(
        '📋 Available accounts: ${_accountProvider!.accounts.map((a) => '${a.id}:${a.name}').toList()}',
      );
      return;
    }

    print(
      '✅ Found account: ${account.name}, current balance: ${account.balance}',
    );

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

    print('💰 Updating balance: ${account.balance} -> $newBalance');
    await _accountProvider!.updateAccountBalance(accountId, newBalance);
    print('✅ Balance update complete for ${account.name}');
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

  /// Recalculates account balance from all transactions for a specific account
  Future<void> recalculateAccountBalance(String accountId) async {
    if (_accountProvider == null) {
      print('❌ AccountProvider not available');
      return;
    }
    if (accountId.isEmpty) {
      print('⚠️ Skipping recalculation: empty accountId');
      return;
    }

    try {
      print('🔢 Recalculating balance for account: $accountId');

      // Get all transactions for this account
      final accountTransactions = _transactions
          .where((t) => t.accountId == accountId || t.toAccountId == accountId)
          .toList();

      print(
        '📊 Found ${accountTransactions.length} transactions for this account',
      );

      // Calculate balance from transactions
      double calculatedBalance = 0.0;

      for (final transaction in accountTransactions) {
        if (transaction.type == TransactionType.income) {
          calculatedBalance += transaction.amount;
          print(
            '  ➕ Income: +${transaction.amount} (${transaction.description})',
          );
        } else if (transaction.type == TransactionType.expense) {
          calculatedBalance -= transaction.amount;
          print(
            '  ➖ Expense: -${transaction.amount} (${transaction.description})',
          );
        } else if (transaction.type == TransactionType.transfer) {
          if (transaction.accountId == accountId) {
            // Money going out (source account)
            calculatedBalance -= transaction.amount;
            print(
              '  ➖ Transfer Out: -${transaction.amount} (${transaction.description})',
            );
          } else if (transaction.toAccountId == accountId) {
            // Money coming in (destination account)
            calculatedBalance += transaction.amount;
            print(
              '  ➕ Transfer In: +${transaction.amount} (${transaction.description})',
            );
          }
        }
      }

      print('💰 Calculated balance: $calculatedBalance');

      // Update the account balance
      await _accountProvider!.updateAccountBalance(
        accountId,
        calculatedBalance,
      );
      print('✅ Account balance recalculated and updated');
    } catch (e) {
      print('❌ Error recalculating balance: $e');
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
    print('📒 Ledger for account=$accountId, total txns=${txns.length}');

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
      print(
        '  ${t.date.toIso8601String()}  ${kind.padRight(12)}  ${delta.toStringAsFixed(2).padLeft(8)}  ->  ${running.toStringAsFixed(2).padLeft(10)}  (${t.description ?? ''})',
      );
    }

    // Print last N for quick view
    final start = (txns.length - lastN) < 0 ? 0 : (txns.length - lastN);
    final recent = txns.sublist(start);
    print('🧾 Last $lastN entries:');
    for (final t in recent) {
      final isDst = t.toAccountId == accountId;
      final sign = t.type == TransactionType.income || isDst ? '+' : '-';
      print('  $sign${t.amount.toStringAsFixed(2)}  ${t.description ?? ''}');
    }
    print('✅ Computed balance from ledger: ${running.toStringAsFixed(2)}');
  }

  void clear() {
    _transactions.clear();
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
