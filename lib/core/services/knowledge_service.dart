import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/knowledge_entry.dart';

/// Persists and retrieves the user's financial Knowledge.
///
/// All reads and writes are scoped to the authenticated user. Knowledge can
/// therefore be rebuilt or deleted without touching transaction history.
class KnowledgeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  KnowledgeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('knowledge');

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<KnowledgeEntry>> watchAll() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(const []);
    return _collection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(KnowledgeEntry.fromFirestore)
              .where((entry) => entry.active)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  Future<List<KnowledgeEntry>> find({
    String? subject,
    String? predicate,
    KnowledgeKind? kind,
  }) async {
    final userId = currentUserId;
    if (userId == null) return const [];

    // Filter locally instead of requiring Firestore composite indexes.
    final snapshot = await _collection(userId).get();
    final normalizedSubject = subject?.trim().toLowerCase();
    final normalizedPredicate = predicate?.trim().toLowerCase();
    return snapshot.docs
        .map(KnowledgeEntry.fromFirestore)
        .where((entry) => entry.active)
        .where((entry) => normalizedSubject == null || entry.subject == normalizedSubject)
        .where((entry) => normalizedPredicate == null || entry.predicate == normalizedPredicate)
        .where((entry) => kind == null || entry.kind == kind)
        .toList();
  }

  Future<String> save(KnowledgeEntry entry) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('User not authenticated');

    final collection = _collection(userId);
    final ref = entry.id.isEmpty ? collection.doc() : collection.doc(entry.id);
    await ref.set(entry.copyWith(id: ref.id).toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deactivate(String id) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('User not authenticated');
    await _collection(userId).doc(id).set({
      'active': false,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAll() async {
    final userId = currentUserId;
    if (userId == null) return;

    final snapshot = await _collection(userId).get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
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
