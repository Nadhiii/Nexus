import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Get user's subscriptions collection reference
  CollectionReference get _subscriptionsCollection =>
      _firestore.collection('users').doc(_userId).collection('subscriptions');

  // CRUD Operations for Subscriptions

  /// Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Use Firestore auto-generated ID if subscription ID is empty
      DocumentReference docRef;
      if (subscription.id.isEmpty) {
        docRef = _subscriptionsCollection.doc();
      } else {
        docRef = _subscriptionsCollection.doc(subscription.id);
      }
      
      // Create subscription with the proper ID
      final subscriptionWithId = subscription.copyWith(id: docRef.id);
      
      await docRef.set(subscriptionWithId.toMap());
      debugPrint('Subscription added: ${subscription.name}');
    } catch (e) {
      debugPrint('Error adding subscription: $e');
      rethrow;
    }
  }

  /// Update an existing subscription
  Future<void> updateSubscription(Subscription subscription) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _subscriptionsCollection
          .doc(subscription.id)
          .update(subscription.toMap());
      debugPrint('Subscription updated: ${subscription.name}');
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _subscriptionsCollection.doc(subscriptionId).delete();
      debugPrint('Subscription deleted: $subscriptionId');
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      rethrow;
    }
  }

  /// Get all subscriptions
  Stream<List<Subscription>> watchSubscriptions() {
    if (_userId == null) return Stream.value([]);

    return _subscriptionsCollection
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Subscription.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get active subscriptions only
  Stream<List<Subscription>> watchActiveSubscriptions() {
    if (_userId == null) return Stream.value([]);

    return _subscriptionsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Subscription.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get subscriptions due today
  Stream<List<Subscription>> watchDueToday() {
    if (_userId == null) return Stream.value([]);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _subscriptionsCollection
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isGreaterThanOrEqualTo: startOfDay)
        .where('nextDueDate', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Subscription.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get subscriptions by frequency
  Stream<List<Subscription>> watchSubscriptionsByFrequency(String frequency) {
    if (_userId == null) return Stream.value([]);

    return _subscriptionsCollection
        .where('frequency', isEqualTo: frequency)
        .where('isActive', isEqualTo: true)
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Subscription.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get a single subscription by ID
  Future<Subscription?> getSubscription(String subscriptionId) async {
    if (_userId == null) return null;

    try {
      final doc = await _subscriptionsCollection.doc(subscriptionId).get();
      if (doc.exists) {
        return Subscription.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting subscription: $e');
      return null;
    }
  }

  /// Update subscription's next due date (after payment)
  Future<void> updateNextDueDate(String subscriptionId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final subscription = await getSubscription(subscriptionId);
      if (subscription != null) {
        final nextDueDate = subscription.calculateNextDueDate();
        await _subscriptionsCollection.doc(subscriptionId).update({
          'nextDueDate': nextDueDate.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('Updated next due date for: ${subscription.name}');
      }
    } catch (e) {
      debugPrint('Error updating next due date: $e');
      rethrow;
    }
  }

  /// Toggle subscription active status
  Future<void> toggleSubscriptionStatus(String subscriptionId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final subscription = await getSubscription(subscriptionId);
      if (subscription != null) {
        await _subscriptionsCollection.doc(subscriptionId).update({
          'isActive': !subscription.isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('Toggled status for: ${subscription.name}');
      }
    } catch (e) {
      debugPrint('Error toggling subscription status: $e');
      rethrow;
    }
  }

  // Analytics and Statistics

  /// Calculate total monthly subscription cost
  Future<double> getTotalMonthlyCost() async {
    if (_userId == null) return 0.0;

    try {
      final snapshot = await _subscriptionsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      double total = 0.0;
      
      for (var doc in snapshot.docs) {
        final subscription = Subscription.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        
        // Convert to monthly cost
        switch (subscription.frequency) {
          case 'daily':
            total += subscription.amount * 30;
            break;
          case 'weekly':
            total += subscription.amount * 4.33; // Approximate weeks per month
            break;
          case 'monthly':
            total += subscription.amount;
            break;
          case 'yearly':
            total += subscription.amount / 12;
            break;
        }
      }
      
      return total;
    } catch (e) {
      debugPrint('Error calculating total monthly cost: $e');
      return 0.0;
    }
  }

  /// Get subscription distribution by frequency
  Future<Map<String, double>> getSubscriptionsByFrequency() async {
    if (_userId == null) return {};

    try {
      final snapshot = await _subscriptionsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      Map<String, double> distribution = {
        'daily': 0.0,
        'weekly': 0.0,
        'monthly': 0.0,
        'yearly': 0.0,
      };
      
      for (var doc in snapshot.docs) {
        final subscription = Subscription.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        
        distribution[subscription.frequency] = 
            (distribution[subscription.frequency] ?? 0.0) + subscription.amount;
      }
      
      return distribution;
    } catch (e) {
      debugPrint('Error getting subscription distribution: $e');
      return {};
    }
  }
}
