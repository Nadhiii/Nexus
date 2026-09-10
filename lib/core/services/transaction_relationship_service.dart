import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_relationship.dart';

class TransactionRelationshipService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRelationshipService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('transactionRelationships');

  Stream<List<TransactionRelationship>> watchAll() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _collection(uid)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(TransactionRelationship.fromFirestore)
            .toList());
  }

  Future<String> save(TransactionRelationship relationship) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    final ref = relationship.id.isEmpty
        ? _collection(uid).doc()
        : _collection(uid).doc(relationship.id);
    await ref.set(
      TransactionRelationship(
        id: ref.id,
        userId: uid,
        type: relationship.type,
        transactionIds: relationship.transactionIds,
        reason: relationship.reason,
        confidence: relationship.confidence,
        active: true,
        createdAt: relationship.createdAt,
        updatedAt: DateTime.now(),
      ).toMap(),
      SetOptions(merge: true),
    );
    return ref.id;
  }

  Future<String> upsertRelated({
    required TransactionRelationshipType type,
    required List<String> transactionIds,
    required String reason,
    required double confidence,
  }) async {
    if (transactionIds.isEmpty) {
      throw ArgumentError('At least one transaction ID is required');
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');

    final ids = transactionIds.toSet();
    final snapshot = await _collection(uid)
        .where('active', isEqualTo: true)
        .where('type', isEqualTo: type.name)
        .where('transactionIds', arrayContains: transactionIds.first)
        .get();

    TransactionRelationship? existing;
    for (final doc in snapshot.docs) {
      final relationship = TransactionRelationship.fromFirestore(doc);
      final relationshipIds = relationship.transactionIds.toSet();
      if (relationshipIds.length == ids.length &&
          relationshipIds.containsAll(ids)) {
        existing = relationship;
        break;
      }
    }

    final now = DateTime.now();
    return save(TransactionRelationship(
      id: existing?.id ?? '',
      userId: uid,
      type: type,
      transactionIds: transactionIds,
      reason: reason,
      confidence: confidence,
      active: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    ));
  }

  Future<void> deactivate(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    await _collection(uid).doc(id).set({
      'active': false,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await _collection(uid).get();
    if (snapshot.docs.isEmpty) return;
    var batch = _firestore.batch();
    var writes = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      writes++;
      if (writes == 450) {
        await batch.commit();
        batch = _firestore.batch();
        writes = 0;
      }
    }
    if (writes > 0) await batch.commit();
  }
}
