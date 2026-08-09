import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LegacyDataMigrationService {
  LegacyDataMigrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _migrationVersion = 'v1';

  Future<void> migrateIfNeeded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final doneKey = 'legacy_data_migration_${_migrationVersion}_$uid';
    if (prefs.getBool(doneKey) == true) {
      return;
    }

    try {
      final investmentsMoved = await _migrateCollection(
        uid: uid,
        rootCollection: 'investments',
        userCollection: 'investments',
      );
      final subscriptionsMoved = await _migrateCollection(
        uid: uid,
        rootCollection: 'subscriptions',
        userCollection: 'subscriptions',
      );
      final goalsMoved = await _migrateCollection(
        uid: uid,
        rootCollection: 'goals',
        userCollection: 'goals',
      );

      debugPrint(
        '[LegacyMigration] Completed for $uid '
        '(investments=$investmentsMoved, subscriptions=$subscriptionsMoved, goals=$goalsMoved)',
      );
    } catch (e) {
      debugPrint('[LegacyMigration] Failed: $e');
      return;
    }

    await prefs.setBool(doneKey, true);
  }

  Future<int> _migrateCollection({
    required String uid,
    required String rootCollection,
    required String userCollection,
  }) async {
    final legacySnap = await _firestore
        .collection(rootCollection)
        .where('userId', isEqualTo: uid)
        .get();

    if (legacySnap.docs.isEmpty) {
      return 0;
    }

    final destCollection =
        _firestore.collection('users').doc(uid).collection(userCollection);

    int migrated = 0;
    for (final doc in legacySnap.docs) {
      final destRef = destCollection.doc(doc.id);
      final existing = await destRef.get();
      if (existing.exists) {
        continue;
      }

      final data = Map<String, dynamic>.from(doc.data());
      data['userId'] = uid;
      await destRef.set(data);
      migrated++;
    }

    return migrated;
  }
}
