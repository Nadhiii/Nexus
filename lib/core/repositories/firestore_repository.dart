import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';

/// Base Firestore repository implementation
///
/// Provides common Firestore operations for user-scoped collections.
/// Extend this class for specific model repositories.
abstract class FirestoreRepository<T>
    implements UserScopedRepository<T, String> {
  final FirebaseFirestore _firestore;
  String? _userId;

  /// The name of the collection in Firestore
  abstract final String collectionName;

  FirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String? get userId => _userId;

  @override
  bool get isInitialized => _userId != null;

  @override
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Get the collection reference for the current user
  CollectionReference<Map<String, dynamic>> get collection {
    if (_userId == null) {
      throw StateError('Repository not initialized with userId');
    }
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
  }

  /// Convert a Firestore document to a model
  T fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);

  /// Convert a model to a Firestore map
  Map<String, dynamic> toFirestore(T item);

  /// Get the ID from a model (for updates)
  String getId(T item);

  /// Create a copy of the model with a new ID
  T withId(T item, String id);

  @override
  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;
    return fromFirestore(doc);
  }

  @override
  Future<List<T>> getAll({int? limit, String? startAfter}) async {
    Query<Map<String, dynamic>> query = collection;

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      final startDoc = await collection.doc(startAfter).get();
      if (startDoc.exists) {
        query = query.startAfterDocument(startDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  @override
  Future<T> create(T item) async {
    final docRef = collection.doc();
    final itemWithId = withId(item, docRef.id);
    await docRef.set(toFirestore(itemWithId));
    return itemWithId;
  }

  @override
  Future<T> update(T item) async {
    final id = getId(item);
    await collection.doc(id).update(toFirestore(item));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  @override
  Stream<List<T>> watchAll() {
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<T?> watchById(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return fromFirestore(doc);
    });
  }

  /// Query with filters and sorting
  Future<List<T>> query({
    List<QueryFilter>? filters,
    SortParams? sort,
    PaginationParams? pagination,
  }) async {
    Query<Map<String, dynamic>> query = collection;

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    // Apply sorting
    if (sort != null) {
      query = query.orderBy(sort.field, descending: sort.descending);
    }

    // Apply pagination
    if (pagination != null) {
      query = query.limit(pagination.limit);

      if (pagination.startAfterId != null) {
        final startDoc = await collection.doc(pagination.startAfterId).get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Watch with filters and sorting
  Stream<List<T>> watchQuery({
    List<QueryFilter>? filters,
    SortParams? sort,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = collection;

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    // Apply sorting
    if (sort != null) {
      query = query.orderBy(sort.field, descending: sort.descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>),
          )
          .toList();
    });
  }

  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case QueryOperator.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case QueryOperator.notEquals:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case QueryOperator.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case QueryOperator.lessThanOrEqual:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case QueryOperator.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case QueryOperator.greaterThanOrEqual:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case QueryOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case QueryOperator.arrayContainsAny:
        return query.where(filter.field, arrayContainsAny: filter.value);
      case QueryOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value);
    }
  }

  /// Batch operations for efficiency
  Future<void> createBatch(List<T> items) async {
    final batch = _firestore.batch();

    for (final item in items) {
      final docRef = collection.doc();
      final itemWithId = withId(item, docRef.id);
      batch.set(docRef, toFirestore(itemWithId));
    }

    await batch.commit();
  }

  Future<void> deleteBatch(List<String> ids) async {
    final batch = _firestore.batch();

    for (final id in ids) {
      batch.delete(collection.doc(id));
    }

    await batch.commit();
  }

  /// Clear all documents in the collection (use carefully!)
  Future<void> clearAll() async {
    final snapshot = await collection.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
