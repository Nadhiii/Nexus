import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final CollectionReference _subscriptionsCollection = FirebaseFirestore.instance.collection('subscriptions');

  Stream<List<Subscription>> watchActiveSubscriptions(String userId) {
    return _subscriptionsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList());
  }

  Stream<List<Subscription>> watchDueToday(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _subscriptionsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isGreaterThanOrEqualTo: today)
        .where('nextDueDate', isLessThan: tomorrow)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList());
  }

  Future<void> addSubscription(Subscription subscription) {
    return _subscriptionsCollection.add(subscription.toJson());
  }

  Future<void> updateSubscription(Subscription subscription) {
    return _subscriptionsCollection.doc(subscription.id).update(subscription.toJson());
  }

  Future<void> deleteSubscription(String subscriptionId) {
    return _subscriptionsCollection.doc(subscriptionId).delete();
  }
  
  Future<void> clearAllSubscriptions(String userId) async {
    final snapshot = await _subscriptionsCollection.where('userId', isEqualTo: userId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreSubscriptions(String userId, List<Subscription> subscriptions) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final subscription in subscriptions) {
      final docRef = _subscriptionsCollection.doc(subscription.id);
      batch.set(docRef, subscription.toJson());
    }
    await batch.commit();
  }
}
