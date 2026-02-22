import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

class BackupSummary {
  final String id;
  final DateTime createdAt;
  final Map<String, int> counts;

  BackupSummary({
    required this.id,
    required this.createdAt,
    required this.counts,
  });
}

/// Handles snapshot-based backups to Firestore under `users/{uid}/backups/{backupId}`.
/// Each backup document stores the payload (all user collections) plus counts and metadata.
class BackupService {
  BackupService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _backupDoc(String id) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('backups')
        .doc(id);
  }

  CollectionReference<Map<String, dynamic>> _collection(String name) {
    return _firestore.collection('users').doc(_uid).collection(name);
  }

  // --- AUTO BACKUP / RESTORE PREFS ---
  static const _prefAutoBackup = 'auto_backup_enabled';
  static const _prefAutoRestore = 'auto_restore_enabled';
  static const _prefLastBackupMs = 'last_backup_ms';

  Future<bool> getAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAutoBackup) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoBackup, value);
  }

  Future<bool> getAutoRestoreEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAutoRestore) ?? true;
  }

  Future<void> setAutoRestoreEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoRestore, value);
  }

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefLastBackupMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefLastBackupMs, dt.millisecondsSinceEpoch);
  }

  /// Create a full backup of all primary collections for the current user.
  /// If [isAutoBackup] is true, deletes old auto-backups and marks this one as auto.
  Future<BackupSummary> createBackup({bool isAutoBackup = false}) async {
    if (_uid == null) throw Exception('Not authenticated');

    // Expanded backup scope: add all relevant collections
    final collections = <String>[
      'accounts',
      'transactions',
      'budgets',
      'goals',
      'debts',
      'subscriptions',
      'investments',
      'shared_expenses',
      'family_debts',
      'payday_checklists',
    ];

    final payload = <String, List<Map<String, dynamic>>>{};
    final counts = <String, int>{};

    for (final col in collections) {
      final snap = await _collection(col).get();
      final list = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList(growable: false);
      payload[col] = list;
      counts[col] = list.length;
    }

    // Backup bikes with their subcollections (entries and trips)
    await _backupBikesWithSubcollections(payload, counts);

    // If auto-backup, delete previous auto-backup first
    if (isAutoBackup) {
      await _deleteOldAutoBackups();
    }

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('backups')
        .doc();
    final createdAt = DateTime.now();

    // Serialize payload to JSON
    final jsonString = jsonEncode(payload);
    final storage = FirebaseStorage.instance;
    final storagePath = 'backups/$_uid/${docRef.id}.json';
    final storageRef = storage.ref().child(storagePath);
    await storageRef.putString(jsonString, format: PutStringFormat.raw);
    final storageUrl = await storageRef.getDownloadURL();

    await docRef.set({
      'createdAt': Timestamp.fromDate(createdAt),
      'counts': counts,
      'storageUrl': storageUrl,
      'schemaVersion': 2,
      'isAutoBackup': isAutoBackup,
    });

    // Update last-backup timestamp
    await setLastBackupAt(createdAt);

    return BackupSummary(id: docRef.id, createdAt: createdAt, counts: counts);
  }

  /// List backups (latest first).
  Future<List<BackupSummary>> listBackups() async {
    if (_uid == null) throw Exception('Not authenticated');
    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('backups')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map(
          (d) => BackupSummary(
            id: d.id,
            createdAt: (d['createdAt'] as Timestamp).toDate(),
            counts: Map<String, int>.from(d['counts'] ?? {}),
          ),
        )
        .toList(growable: false);
  }

  Future<BackupSummary?> latestBackup() async {
    final list = await listBackups();
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Delete a specific backup (Firestore doc + Storage file).
  Future<void> deleteBackup(String id) async {
    if (_uid == null) throw Exception('Not authenticated');
    final docRef = _backupDoc(id);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final storageUrl = docSnap.data()?['storageUrl'] as String?;
      if (storageUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(storageUrl).delete();
        } catch (e) {
          print('Warning: Failed to delete storage file for backup $id: $e');
        }
      }
      await docRef.delete();
    }
  }

  /// Delete all previous auto-backups (keeps only manual backups)
  Future<void> _deleteOldAutoBackups() async {
    if (_uid == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('backups')
        .where('isAutoBackup', isEqualTo: true)
        .get();

    for (final doc in snap.docs) {
      final storageUrl = doc.data()['storageUrl'] as String?;
      if (storageUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(storageUrl).delete();
        } catch (e) {
          print('Warning: Failed to delete old auto-backup file: $e');
        }
      }
      await doc.reference.delete();
    }

    if (snap.docs.isNotEmpty) {
      print('Deleted ${snap.docs.length} old auto-backup(s)');
    }
  }

  /// Perform auto-backup if enabled and last backup is older than 24 hours.
  /// Replaces the previous auto-backup.
  Future<void> performAutoBackupIfNeeded() async {
    if (_uid == null) return;

    final isEnabled = await getAutoBackupEnabled();
    if (!isEnabled) {
      print('[Auto-Backup] Disabled, skipping');
      return;
    }

    final lastBackup = await getLastBackupAt();
    final now = DateTime.now();

    if (lastBackup != null) {
      final hoursSinceLastBackup = now.difference(lastBackup).inHours;
      if (hoursSinceLastBackup < 24) {
        print(
          '[Auto-Backup] Last backup was $hoursSinceLastBackup hours ago, skipping',
        );
        return;
      }
    }

    print('[Auto-Backup] Creating auto-backup...');
    try {
      await createBackup(isAutoBackup: true);
      print('[Auto-Backup] Successfully created auto-backup');
    } catch (e) {
      print('[Auto-Backup] Error: $e');
    }
  }

  /// Perform auto-restore if enabled and user has no data.
  /// Restores latest backup in merge mode.
  /// Returns true if data was restored, false otherwise.
  Future<bool> performAutoRestoreIfNeeded() async {
    if (_uid == null) return false;

    final isEnabled = await getAutoRestoreEnabled();
    if (!isEnabled) {
      print('[Auto-Restore] Disabled, skipping');
      return false;
    }

    final hasData = await hasAnyUserData();
    if (hasData) {
      print('[Auto-Restore] User has data, skipping');
      return false;
    }

    print('[Auto-Restore] No data found, checking for backups...');
    final latest = await latestBackup();
    if (latest == null) {
      print('[Auto-Restore] No backups available');
      return false;
    }

    print('[Auto-Restore] Restoring latest backup (merge mode)...');
    try {
      await restoreBackup(latest.id, replace: false);
      print('[Auto-Restore] Successfully restored backup');
      return true;
    } catch (e) {
      print('[Auto-Restore] Error: $e');
      return false;
    }
  }

  /// Restore from a backup. If [replace] is true, existing collections are cleared first.
  Future<void> restoreBackup(String backupId, {bool replace = false}) async {
    if (_uid == null) throw Exception('Not authenticated');

    final doc = await _backupDoc(backupId).get();
    if (!doc.exists) throw Exception('Backup not found');
    final data = doc.data()!;

    // Download and parse JSON from Cloud Storage
    final storageUrl = data['storageUrl'] as String?;
    if (storageUrl == null) throw Exception('Backup file missing storageUrl');

    // Download JSON file
    final storage = FirebaseStorage.instance;
    final ref = storage.refFromURL(storageUrl);
    final jsonString = await ref
        .getData(10 * 1024 * 1024) // 10 MiB max
        .then((bytes) => bytes != null ? String.fromCharCodes(bytes) : null);
    if (jsonString == null) throw Exception('Failed to download backup file');

    // Parse JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Backup file is corrupted or invalid JSON: $e');
    }

    final collections = payload.keys.where(
      (key) => key != 'bikes' && key != 'bike_entries' && key != 'bike_trips',
    );

    // Only delete data after successful download/parse
    if (replace) {
      for (final col in collections) {
        await _deleteCollection(col);
      }
    }

    for (final col in collections) {
      final List list = payload[col] as List;
      await _writeBatch(col, list.cast<Map<String, dynamic>>());
    }

    // Restore bikes with their subcollections
    await _restoreBikesWithSubcollections(payload, replace);
  }

  /// Check if the user has any data in primary collections.
  Future<bool> hasAnyUserData() async {
    if (_uid == null) return false;
    final collections = <String>[
      'accounts',
      'transactions',
      'budgets',
      'goals',
      'debts',
      'subscriptions',
      'investments',
      'bikes',
    ];

    for (final col in collections) {
      final snap = await _collection(col).limit(1).get();
      if (snap.docs.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> _deleteCollection(String name) async {
    const chunk = 400;
    while (true) {
      final snap = await _collection(name).limit(chunk).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _writeBatch(
    String name,
    List<Map<String, dynamic>> items,
  ) async {
    const chunk = 400;
    for (var i = 0; i < items.length; i += chunk) {
      final batch = _firestore.batch();
      final part = items.skip(i).take(chunk);
      for (final item in part) {
        final id = item['id'] as String?;
        if (id == null || id.isEmpty) continue;
        final data = Map<String, dynamic>.from(item)..remove('id');
        batch.set(_collection(name).doc(id), data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  /// Backup bikes with their subcollections (entries and trips)
  Future<void> _backupBikesWithSubcollections(
    Map<String, List<Map<String, dynamic>>> payload,
    Map<String, int> counts,
  ) async {
    final bikesSnap = await _collection('bikes').get();
    final bikesList = <Map<String, dynamic>>[];
    final entriesList = <Map<String, dynamic>>[];
    final tripsList = <Map<String, dynamic>>[];

    for (final bikeDoc in bikesSnap.docs) {
      final bikeData = bikeDoc.data();
      // Only backup active bikes (skip deleted ones)
      final isActive = bikeData['isActive'] ?? true;
      if (!isActive) {
        print('Skipping deleted bike: ${bikeData['name']}');
        continue;
      }

      // Add bike itself
      bikesList.add({'id': bikeDoc.id, ...bikeData});

      // Add bike entries
      final entriesSnap = await _collection(
        'bikes',
      ).doc(bikeDoc.id).collection('entries').get();
      for (final entryDoc in entriesSnap.docs) {
        entriesList.add({
          'id': entryDoc.id,
          'bikeId': bikeDoc.id,
          ...entryDoc.data(),
        });
      }

      // Add bike trips
      final tripsSnap = await _collection(
        'bikes',
      ).doc(bikeDoc.id).collection('trips').get();
      for (final tripDoc in tripsSnap.docs) {
        tripsList.add({
          'id': tripDoc.id,
          'bikeId': bikeDoc.id,
          ...tripDoc.data(),
        });
      }
    }

    payload['bikes'] = bikesList;
    payload['bike_entries'] = entriesList;
    payload['bike_trips'] = tripsList;
    counts['bikes'] = bikesList.length;
    counts['bike_entries'] = entriesList.length;
    counts['bike_trips'] = tripsList.length;
  }

  /// Restore bikes with their subcollections
  Future<void> _restoreBikesWithSubcollections(
    Map<String, dynamic> payload,
    bool replace,
  ) async {
    if (replace) {
      await _deleteCollection('bikes');
    }

    // Get bikes list - handle both old and new backup formats
    List<Map<String, dynamic>> bikesList =
        (payload['bikes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Check if we have bike entries - extract unique bikes from entries if needed
    final entriesList =
        (payload['bike_entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    print(
      'Restore: Found ${bikesList.length} bikes and ${entriesList.length} entries',
    );

    // If we have entries but no bikes, try to reconstruct bikes from entries
    if (bikesList.isEmpty && entriesList.isNotEmpty) {
      print(
        'Warning: No bikes found but have entries. Creating bikes from entries...',
      );
      final bikeMap = <String, Map<String, dynamic>>{};

      for (final entry in entriesList) {
        final bikeId = entry['bikeId'] as String?;
        final bikeName = entry['bikeName'] as String?;

        if (bikeId != null && !bikeMap.containsKey(bikeId)) {
          // Create a basic bike structure from the entry
          bikeMap[bikeId] = {
            'id': bikeId,
            'name': bikeName ?? 'Restored Bike',
            'make': '',
            'model': '',
            'year': 2020,
            'registrationNumber': '',
            'currentOdometer': entry['odometerReading'] ?? 0,
            'isActive': true,
            'createdAt': entry['date'] ?? Timestamp.now(),
            'userId': entry['userId'] ?? '',
            'isDashboardBike': false,
            'displayOrder': 0,
          };
        }
      }

      bikesList = bikeMap.values.toList();
      print('Reconstructed ${bikesList.length} bikes from entries');
    }

    // Restore bikes as-is (preserving their isActive status)
    print('Restoring ${bikesList.length} bikes...');
    await _writeBatch('bikes', bikesList);

    // Restore bike entries - wait a bit to ensure bikes are written
    print('Restoring ${entriesList.length} bike entries...');
    int entriesRestored = 0;
    for (final entry in entriesList) {
      final bikeId = entry['bikeId'] as String?;
      if (bikeId == null || bikeId.isEmpty) {
        print('  Skipping entry: missing bikeId');
        continue;
      }

      final entryId = entry['id'] as String?;
      if (entryId == null || entryId.isEmpty) {
        print('  Skipping entry: missing entryId');
        continue;
      }

      final data = Map<String, dynamic>.from(entry)
        ..remove('id')
        ..remove('bikeId');

      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('bikes')
            .doc(bikeId)
            .collection('entries')
            .doc(entryId)
            .set(data, SetOptions(merge: true));
        entriesRestored++;
      } catch (e) {
        print('  Error restoring entry $entryId: $e');
      }
    }
    print('Successfully restored $entriesRestored entries');

    // Restore bike trips
    final tripsList =
        (payload['bike_trips'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    print('Restoring ${tripsList.length} bike trips...');
    int tripsRestored = 0;
    for (final trip in tripsList) {
      final bikeId = trip['bikeId'] as String?;
      if (bikeId == null || bikeId.isEmpty) {
        print('  Skipping trip: missing bikeId');
        continue;
      }

      final tripId = trip['id'] as String?;
      if (tripId == null || tripId.isEmpty) {
        print('  Skipping trip: missing tripId');
        continue;
      }

      final data = Map<String, dynamic>.from(trip)
        ..remove('id')
        ..remove('bikeId');

      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('bikes')
            .doc(bikeId)
            .collection('trips')
            .doc(tripId)
            .set(data, SetOptions(merge: true));
        tripsRestored++;
      } catch (e) {
        print('  Error restoring trip $tripId: $e');
      }
    }
    print('Successfully restored $tripsRestored trips');
  }
}
