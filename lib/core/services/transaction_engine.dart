import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/transaction.dart';
import 'ledger_service.dart';
import 'transaction_paths.dart';

/// The single persistence gateway for financial transactions.
///
/// Providers and source-specific flows may prepare a Transaction, but the
/// financial write itself goes through this engine and LedgerService.
class TransactionEngine {
  final LedgerService _ledgerService;

  TransactionEngine({LedgerService? ledgerService})
    : _ledgerService = ledgerService ?? LedgerService();

  Future<String> commit({
    required Transaction transaction,
    required double newBalance,
  }) async {
    final id = transaction.id.isEmpty
        ? TransactionPaths.allocateId(
            firestore.FirebaseFirestore.instance,
            transaction.userId,
          )
        : transaction.id;

    final finalTransaction = transaction.copyWith(id: id);
    await _ledgerService.addTransactionAndUpdateBalance(
      transaction: finalTransaction,
      newBalance: newBalance,
    );
    return id;
  }

  Future<String> commitTransfer({
    required Transaction transaction,
    required double sourceNewBalance,
    required double destinationNewBalance,
  }) async {
    final id = transaction.id.isEmpty
        ? TransactionPaths.allocateId(
            firestore.FirebaseFirestore.instance,
            transaction.userId,
          )
        : transaction.id;
    await _ledgerService.addTransferAndUpdateBalances(
      transaction: transaction.copyWith(id: id),
      sourceNewBalance: sourceNewBalance,
      destNewBalance: destinationNewBalance,
    );
    return id;
  }

  Future<void> update({
    required Transaction oldTransaction,
    required Transaction newTransaction,
    required Map<String, double> accountBalances,
  }) {
    return _ledgerService.updateTransactionAndUpdateBalances(
      oldTransaction: oldTransaction,
      newTransaction: newTransaction,
      accountBalances: accountBalances,
    );
  }

  Future<void> delete({
    required Transaction transaction,
    required Map<String, double> accountBalances,
  }) {
    return _ledgerService.deleteTransactionAndUpdateBalances(
      transaction: transaction,
      accountBalances: accountBalances,
    );
  }
}
