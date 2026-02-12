import 'dart:async';

/// Base interface for all repositories
///
/// The Repository pattern abstracts data sources (Firestore, local DB, etc.)
/// from the rest of the application. This provides:
/// - Testability: Easily mock repositories in tests
/// - Flexibility: Switch data sources without changing business logic
/// - Separation of concerns: Data access logic is isolated
abstract class Repository<T, ID> {
  /// Get a single item by its ID
  Future<T?> getById(ID id);

  /// Get all items (with optional pagination)
  Future<List<T>> getAll({int? limit, ID? startAfter});

  /// Create a new item
  Future<T> create(T item);

  /// Update an existing item
  Future<T> update(T item);

  /// Delete an item by its ID
  Future<void> delete(ID id);

  /// Watch all items as a stream
  Stream<List<T>> watchAll();

  /// Watch a single item by ID
  Stream<T?> watchById(ID id);
}

/// Base interface for user-scoped repositories
///
/// Most repositories in this app are scoped to a user, meaning
/// they require a userId to access data.
abstract class UserScopedRepository<T, ID> extends Repository<T, ID> {
  /// The current user ID this repository is scoped to
  String? get userId;

  /// Set the user ID for this repository
  void setUserId(String? userId);

  /// Check if repository is initialized with a user
  bool get isInitialized => userId != null;
}

/// Result wrapper for repository operations
///
/// Provides a consistent way to handle success/failure states
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  RepositoryResult.success(this.data) : error = null, isSuccess = true;

  RepositoryResult.failure(this.error) : data = null, isSuccess = false;

  /// Map the result to a different type
  RepositoryResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      return RepositoryResult.success(mapper(data as T));
    }
    return RepositoryResult.failure(error);
  }

  /// Handle both success and failure cases
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(String?) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error);
  }
}

/// Pagination helper for repository queries
class PaginationParams {
  final int limit;
  final String? startAfterId;
  final DateTime? startAfterDate;

  const PaginationParams({
    this.limit = 20,
    this.startAfterId,
    this.startAfterDate,
  });

  PaginationParams copyWith({
    int? limit,
    String? startAfterId,
    DateTime? startAfterDate,
  }) {
    return PaginationParams(
      limit: limit ?? this.limit,
      startAfterId: startAfterId ?? this.startAfterId,
      startAfterDate: startAfterDate ?? this.startAfterDate,
    );
  }
}

/// Filter parameters for queries
class QueryFilter {
  final String field;
  final QueryOperator operator;
  final dynamic value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

enum QueryOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  arrayContains,
  arrayContainsAny,
  whereIn,
}

/// Sort parameters for queries
class SortParams {
  final String field;
  final bool descending;

  const SortParams({required this.field, this.descending = false});
}
