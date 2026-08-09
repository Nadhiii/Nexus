import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('goals');
  }

  String _requireUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  Stream<List<Goal>> watchGoals(String userId) {
    return _goalsCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }

  Future<void> addGoal(Goal goal) async {
    final userId = _requireUserId();
    final docRef = _goalsCollection(userId).doc();
    await docRef.set(goal.copyWith(id: docRef.id, userId: userId).toMap());
  }

  Future<void> updateGoal(Goal goal) async {
    final userId = _requireUserId();
    await _goalsCollection(userId)
        .doc(goal.id)
        .update(goal.copyWith(userId: userId).toMap());
  }

  Future<void> deleteGoal(String goalId) async {
    final userId = _requireUserId();
    await _goalsCollection(userId).doc(goalId).delete();
  }

  Future<void> addContribution(String goalId, double amount) async {
    final userId = _requireUserId();
    await _goalsCollection(userId).doc(goalId).update({
      'currentAmount': FieldValue.increment(amount),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  Future<void> clearAllGoals(String userId) async {
    final snapshot = await _goalsCollection(userId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreGoals(String userId, List<Goal> goals) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final goal in goals) {
      final docRef = _goalsCollection(userId).doc();
      batch.set(docRef, goal.copyWith(userId: userId, id: docRef.id).toMap());
    }
    await batch.commit();
  }
}
