import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import 'firestore_repository.dart';
import 'base_repository.dart';

/// Repository for Transaction data
///
/// Handles all CRUD operations for transactions using Firestore.
/// Provides additional query methods specific to transactions.
class TransactionRepository extends FirestoreRepository<Transaction> {
  @override
  final String collectionName = 'transactions';

  TransactionRepository({super.firestore});

  @override
  Transaction fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Transaction.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Transaction item) {
    return item.toMap();
  }

  @override
  String getId(Transaction item) => item.id;

  @override
  Transaction withId(Transaction item, String id) {
    return item.copyWith(id: id);
  }

  /// Get transactions for a specific account
  Future<List<Transaction>> getByAccount(String accountId) async {
    return query(
      filters: [
        QueryFilter(
          field: 'accountId',
          operator: QueryOperator.equals,
          value: accountId,
        ),
      ],
      sort: const SortParams(field: 'date', descending: true),
    );
  }

  /// Get transactions for a date range
  Future<List<Transaction>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return query(
      filters: [
        QueryFilter(
          field: 'date',
          operator: QueryOperator.greaterThanOrEqual,
          value: startDate.toIso8601String(),
        ),
        QueryFilter(
          field: 'date',
          operator: QueryOperator.lessThanOrEqual,
          value: endDate.toIso8601String(),
        ),
      ],
      sort: const SortParams(field: 'date', descending: true),
    );
  }

  /// Get transactions by type (income, expense, transfer)
  Future<List<Transaction>> getByType(TransactionType type) async {
    return query(
      filters: [
        QueryFilter(
          field: 'type',
          operator: QueryOperator.equals,
          value: type.name,
        ),
      ],
      sort: const SortParams(field: 'date', descending: true),
    );
  }

  /// Get transactions by category
  Future<List<Transaction>> getByCategory(String categoryId) async {
    return query(
      filters: [
        QueryFilter(
          field: 'categoryId',
          operator: QueryOperator.equals,
          value: categoryId,
        ),
      ],
      sort: const SortParams(field: 'date', descending: true),
    );
  }

  /// Get recent transactions with limit
  Future<List<Transaction>> getRecent({int limit = 10}) async {
    return query(
      sort: const SortParams(field: 'date', descending: true),
      pagination: PaginationParams(limit: limit),
    );
  }

  /// Watch transactions for a specific account
  Stream<List<Transaction>> watchByAccount(String accountId) {
    return watchQuery(
      filters: [
        QueryFilter(
          field: 'accountId',
          operator: QueryOperator.equals,
          value: accountId,
        ),
      ],
      sort: const SortParams(field: 'date', descending: true),
    );
  }

  /// Get total income for a date range
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final transactions = await getByDateRange(startDate, endDate);
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final transactions = await getByDateRange(startDate, endDate);
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Get spending by category for analytics
  Future<Map<String, double>> getSpendingByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await getByDateRange(startDate, endDate);
    final categoryTotals = <String, double>{};

    for (final t in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final category = t.categoryId ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + t.amount;
    }

    return categoryTotals;
  }

  /// Search transactions by description
  Future<List<Transaction>> search(String query, {int limit = 50}) async {
    // Note: Firestore doesn't support full-text search
    // For production, consider using Algolia or similar
    final allTransactions = await getAll(limit: limit * 3);
    final lowerQuery = query.toLowerCase();

    return allTransactions
        .where(
          (t) =>
              (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              (t.categoryId?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .take(limit)
        .toList();
  }
}
