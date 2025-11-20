import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class FirebaseBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxBackupVersions = 5; // Keep last 5 backups
  static const String backupVersion = '1.0.0'; // For future compatibility

  CollectionReference get _backupCollection => _firestore.collection('backups');

  /// Create a new backup with versioning support
  Future<void> createBackup(String userId, Map<String, dynamic> data) async {
    final timestamp = DateTime.now();
    final backupId = timestamp.millisecondsSinceEpoch.toString();

    // Calculate data checksum for integrity verification
    final dataString = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(dataString)).toString();

    // Count items in backup
    final itemCounts = {
      'transactions': (data['transactions'] as List?)?.length ?? 0,
      'accounts': (data['accounts'] as List?)?.length ?? 0,
      'goals': (data['goals'] as List?)?.length ?? 0,
      'subscriptions': (data['subscriptions'] as List?)?.length ?? 0,
      'debts': (data['debts'] as List?)?.length ?? 0,
    };

    final totalItems = itemCounts.values.reduce((a, b) => a + b);

    // Create backup document in versioned subcollection
    await _backupCollection
        .doc(userId)
        .collection('versions')
        .doc(backupId)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'clientTimestamp': timestamp.toIso8601String(),
          'data': data,
          'checksum': checksum,
          'itemCounts': itemCounts,
          'totalItems': totalItems,
          'version': backupVersion,
          'deviceInfo': 'Flutter App', // Could add actual device info
        });

    // Update the main document with latest backup reference
    await _backupCollection.doc(userId).set({
      'latestBackupId': backupId,
      'lastBackupTimestamp': FieldValue.serverTimestamp(),
      'lastBackupClientTimestamp': timestamp.toIso8601String(),
      'totalBackups': FieldValue.increment(1),
      'itemCounts': itemCounts,
      'totalItems': totalItems,
    }, SetOptions(merge: true));

    // Clean up old backups (keep only last maxBackupVersions)
    await _cleanOldBackups(userId);
  }

  /// Clean up old backups, keeping only the most recent ones
  Future<void> _cleanOldBackups(String userId) async {
    try {
      final versions = await _backupCollection
          .doc(userId)
          .collection('versions')
          .orderBy('timestamp', descending: true)
          .get();

      if (versions.docs.length > maxBackupVersions) {
        // Delete oldest backups
        for (int i = maxBackupVersions; i < versions.docs.length; i++) {
          await versions.docs[i].reference.delete();
        }
      }
    } catch (e) {
      print('Error cleaning old backups: $e');
      // Don't throw - this is not critical
    }
  }

  /// Restore from the latest backup
  Future<Map<String, dynamic>?> restoreFromBackup(String userId) async {
    return await restoreFromSpecificBackup(userId, null);
  }

  /// Restore from a specific backup version
  Future<Map<String, dynamic>?> restoreFromSpecificBackup(
    String userId,
    String? backupId,
  ) async {
    try {
      String? targetBackupId = backupId;

      // If no specific backup ID, get the latest one
      if (targetBackupId == null) {
        final mainDoc = await _backupCollection.doc(userId).get();
        if (!mainDoc.exists) return null;
        final mainData = mainDoc.data() as Map<String, dynamic>?;
        targetBackupId = mainData?['latestBackupId'] as String?;
        if (targetBackupId == null) return null;
      }

      // Fetch the backup version
      final backupDoc = await _backupCollection
          .doc(userId)
          .collection('versions')
          .doc(targetBackupId)
          .get();

      if (!backupDoc.exists) return null;

      final backupData = backupDoc.data() as Map<String, dynamic>;

      // Verify checksum if available
      final storedChecksum = backupData['checksum'] as String?;
      if (storedChecksum != null) {
        final data = backupData['data'] as Map<String, dynamic>;
        final dataString = jsonEncode(data);
        final calculatedChecksum = sha256
            .convert(utf8.encode(dataString))
            .toString();

        if (storedChecksum != calculatedChecksum) {
          throw Exception(
            'Backup data integrity check failed. Checksum mismatch.',
          );
        }
      }

      return backupData;
    } catch (e) {
      print('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Get list of all available backups for a user
  Future<List<Map<String, dynamic>>> getBackupHistory(String userId) async {
    try {
      final versions = await _backupCollection
          .doc(userId)
          .collection('versions')
          .orderBy('timestamp', descending: true)
          .limit(maxBackupVersions)
          .get();

      return versions.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return {
          'id': doc.id,
          'timestamp': timestamp?.toDate(),
          'clientTimestamp': data['clientTimestamp'],
          'itemCounts': data['itemCounts'],
          'totalItems': data['totalItems'],
          'version': data['version'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching backup history: $e');
      return [];
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTimestamp(String userId) async {
    try {
      final doc = await _backupCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['lastBackupTimestamp'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get backup statistics
  Future<Map<String, dynamic>?> getBackupStats(String userId) async {
    try {
      final doc = await _backupCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'totalBackups': data?['totalBackups'] ?? 0,
          'lastBackupTimestamp': (data?['lastBackupTimestamp'] as Timestamp?)
              ?.toDate(),
          'itemCounts': data?['itemCounts'] ?? {},
          'totalItems': data?['totalItems'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a specific backup
  Future<void> deleteBackup(String userId, String backupId) async {
    await _backupCollection
        .doc(userId)
        .collection('versions')
        .doc(backupId)
        .delete();
  }

  /// Delete all backups for a user
  Future<void> deleteAllBackups(String userId) async {
    final batch = _firestore.batch();

    final versions = await _backupCollection
        .doc(userId)
        .collection('versions')
        .get();

    for (var doc in versions.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_backupCollection.doc(userId));
    await batch.commit();
  }
}
