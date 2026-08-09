import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subscriptionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('subscriptions');
  }

  String _requireUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  Stream<List<Subscription>> watchActiveSubscriptions(String userId) {
    return _subscriptionsCollection(userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList());
  }

  Stream<List<Subscription>> watchDueToday(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _subscriptionsCollection(userId)
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isGreaterThanOrEqualTo: today)
        .where('nextDueDate', isLessThan: tomorrow)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList());
  }

  Future<void> addSubscription(Subscription subscription) async {
    final userId = _requireUserId();
    final docRef = _subscriptionsCollection(userId).doc();
    await docRef.set(subscription.copyWith(id: docRef.id, userId: userId).toMap());
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final userId = _requireUserId();
    await _subscriptionsCollection(userId)
        .doc(subscription.id)
        .update(subscription.copyWith(userId: userId).toMap());
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    final userId = _requireUserId();
    await _subscriptionsCollection(userId).doc(subscriptionId).delete();
  }
  
  Future<void> clearAllSubscriptions(String userId) async {
    final snapshot = await _subscriptionsCollection(userId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreSubscriptions(String userId, List<Subscription> subscriptions) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final subscription in subscriptions) {
      final docRef = _subscriptionsCollection(userId).doc(subscription.id);
      batch.set(docRef, subscription.copyWith(userId: userId).toMap());
    }
    await batch.commit();
  }
}
