import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class GoalService {
  final CollectionReference _goalsCollection = FirebaseFirestore.instance.collection('goals');

  Stream<List<Goal>> watchGoals(String userId) {
    return _goalsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }

  Future<void> addGoal(Goal goal) {
    final docRef = _goalsCollection.doc();
    return docRef.set(goal.copyWith(id: docRef.id).toJson());
  }

  Future<void> updateGoal(Goal goal) {
    return _goalsCollection.doc(goal.id).update(goal.toJson());
  }

  Future<void> deleteGoal(String goalId) {
    return _goalsCollection.doc(goalId).delete();
  }

  Future<void> addContribution(String goalId, double amount) {
    return _goalsCollection.doc(goalId).update({
      'currentAmount': FieldValue.increment(amount),
    });
  }
  
  Future<void> clearAllGoals(String userId) async {
    final snapshot = await _goalsCollection.where('userId', isEqualTo: userId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreGoals(String userId, List<Goal> goals) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final goal in goals) {
      final docRef = _goalsCollection.doc();
      batch.set(docRef, goal.copyWith(userId: userId, id: docRef.id).toJson());
    }
    await batch.commit();
  }
}
