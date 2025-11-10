import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as model;

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference - now using root-level collection
  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    return _firestore.collection('transactions');
  }

  // Create a new transaction
  Future<String> createTransaction(
    String userId,
    model.Transaction transaction,
  ) async {
    try {
      final docRef = await _transactionsCollection.add(transaction.toMap());

      // Update the transaction with the generated ID
      final updatedTransaction = transaction.copyWith(id: docRef.id);
      await docRef.update(updatedTransaction.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Get all transactions for a user (one-time fetch)
  Future<List<model.Transaction>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return model.Transaction.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user transactions: $e');
    }
  }

  // Get transactions for a specific account (one-time fetch)
  Future<List<model.Transaction>> getAccountTransactions(
    String userId,
    String accountId,
  ) async {
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('accountId', isEqualTo: accountId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return model.Transaction.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get account transactions: $e');
    }
  }

  // Get all transactions for a user
  Stream<List<model.Transaction>> watchUserTransactions(String userId) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return model.Transaction.fromMap(data);
          }).toList();
        });
  }

  // Get transactions for a specific account
  Stream<List<model.Transaction>> watchAccountTransactions(
    String userId,
    String accountId,
  ) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('accountId', isEqualTo: accountId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return model.Transaction.fromMap(data);
          }).toList();
        });
  }

  // Get transactions by type
  Stream<List<model.Transaction>> watchTransactionsByType(
    String userId,
    model.TransactionType type,
  ) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return model.Transaction.fromMap(data);
          }).toList();
        });
  }

  // Get transactions for date range
  Stream<List<model.Transaction>> watchTransactionsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return model.Transaction.fromMap(data);
          }).toList();
        });
  }

  // Get a specific transaction
  Future<model.Transaction?> getTransaction(
    String userId,
    String transactionId,
  ) async {
    try {
      final doc = await _transactionsCollection.doc(transactionId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return model.Transaction.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  // Update a transaction
  Future<void> updateTransaction(
    String userId,
    model.Transaction transaction,
  ) async {
    try {
      await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _transactionsCollection.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get transactions summary for an account
  Future<Map<String, double>> getAccountTransactionSummary(
    String userId,
    String accountId,
  ) async {
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('accountId', isEqualTo: accountId)
          .get();

      double totalIncome = 0;
      double totalExpense = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final transaction = model.Transaction.fromMap({...data, 'id': doc.id});

        if (transaction.type == model.TransactionType.income) {
          totalIncome += transaction.amount;
        } else if (transaction.type == model.TransactionType.expense) {
          totalExpense += transaction.amount;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netFlow': totalIncome - totalExpense,
      };
    } catch (e) {
      throw Exception('Failed to get transaction summary: $e');
    }
  }

  // Get monthly transaction summary
  Future<Map<String, Map<String, double>>> getMonthlyTransactionSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      Map<String, Map<String, double>> monthlySummary = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final transaction = model.Transaction.fromMap({...data, 'id': doc.id});

        final monthKey =
            '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

        monthlySummary[monthKey] ??= {'income': 0, 'expense': 0, 'net': 0};

        if (transaction.type == model.TransactionType.income) {
          monthlySummary[monthKey]!['income'] =
              monthlySummary[monthKey]!['income']! + transaction.amount;
        } else if (transaction.type == model.TransactionType.expense) {
          monthlySummary[monthKey]!['expense'] =
              monthlySummary[monthKey]!['expense']! + transaction.amount;
        }

        monthlySummary[monthKey]!['net'] =
            monthlySummary[monthKey]!['income']! -
            monthlySummary[monthKey]!['expense']!;
      }

      return monthlySummary;
    } catch (e) {
      throw Exception('Failed to get monthly summary: $e');
    }
  }
}
