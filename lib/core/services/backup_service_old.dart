import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Creates a complete backup of user data
  Future<Map<String, dynamic>> createBackup() async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to create backup');
    }

    try {
      debugPrint('Creating backup for user: $_currentUserId');

      final backup = <String, dynamic>{
        'version': '1.0.0',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
        'accounts': await _backupAccounts(),
        'transactions': await _backupTransactions(),
        'debts': await _backupDebts(),
        'goals': await _backupGoals(),
        'subscriptions': await _backupSubscriptions(),
        'investments': await _backupInvestments(),
        'budgets': await _backupBudgets(),
        'userProfile': await _backupUserProfile(),
      };

      // Store backup in Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .add(backup);

      debugPrint('Backup created successfully');
      return backup;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Backs up all user accounts
  Future<List<Map<String, dynamic>>> _backupAccounts() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('accounts')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up accounts: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user transactions
  Future<List<Map<String, dynamic>>> _backupTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up transactions: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user debts
  Future<List<Map<String, dynamic>>> _backupDebts() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('debts')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up debts: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user goals
  Future<List<Map<String, dynamic>>> _backupGoals() async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up goals: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user subscriptions
  Future<List<Map<String, dynamic>>> _backupSubscriptions() async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up subscriptions: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user investments
  Future<List<Map<String, dynamic>>> _backupInvestments() async {
    try {
      final snapshot = await _firestore
          .collection('investments')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up investments: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up all user budgets
  Future<List<Map<String, dynamic>>> _backupBudgets() async {
    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error backing up budgets: $e');
      return []; // Return empty list if collection doesn't exist or has no data
    }
  }

  /// Backs up user profile
  Future<Map<String, dynamic>?> _backupUserProfile() async {
    try {
      final snapshot = await _firestore
          .collection('userProfiles')
          .doc(_currentUserId)
          .get();

      if (snapshot.exists) {
        return {'id': snapshot.id, ...snapshot.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Error backing up user profile: $e');
      return null;
    }
  }

  /// Gets list of available backups
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to get backup history');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .limit(10) // Last 10 backups
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'timestamp': doc.data()['timestamp'],
              'version': doc.data()['version'],
              'accountsCount': (doc.data()['accounts'] as List?)?.length ?? 0,
              'transactionsCount':
                  (doc.data()['transactions'] as List?)?.length ?? 0,
              'debtsCount': (doc.data()['debts'] as List?)?.length ?? 0,
              'goalsCount': (doc.data()['goals'] as List?)?.length ?? 0,
              'subscriptionsCount': (doc.data()['subscriptions'] as List?)?.length ?? 0,
              'investmentsCount': (doc.data()['investments'] as List?)?.length ?? 0,
              'budgetsCount': (doc.data()['budgets'] as List?)?.length ?? 0,
              'hasUserProfile': doc.data()['userProfile'] != null,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting backup history: $e');
      rethrow;
    }
  }

  /// Restores data from a specific backup
  Future<void> restoreFromBackup(String backupId) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to restore backup');
    }

    try {
      debugPrint('Restoring backup: $backupId');

      // Get backup data
      final backupDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      final backupData = backupDoc.data()!;

      // Clear existing data first (optional - you might want to ask user)
      await _clearUserData();

      // Restore accounts
      if (backupData['accounts'] != null) {
        await _restoreAccounts(backupData['accounts']);
      }

      // Restore transactions
      if (backupData['transactions'] != null) {
        await _restoreTransactions(backupData['transactions']);
      }

      // Restore debts
      if (backupData['debts'] != null) {
        await _restoreDebts(backupData['debts']);
      }

      // Restore goals
      if (backupData['goals'] != null) {
        await _restoreGoals(backupData['goals']);
      }

      // Restore subscriptions
      if (backupData['subscriptions'] != null) {
        await _restoreSubscriptions(backupData['subscriptions']);
      }

      // Restore investments
      if (backupData['investments'] != null) {
        await _restoreInvestments(backupData['investments']);
      }

      // Restore budgets
      if (backupData['budgets'] != null) {
        await _restoreBudgets(backupData['budgets']);
      }

      // Restore user profile
      if (backupData['userProfile'] != null) {
        await _restoreUserProfile(backupData['userProfile']);
      }

      debugPrint('Backup restored successfully');
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Clears all user data before restore
  Future<void> _clearUserData() async {
    final batch = _firestore.batch();

    // Clear accounts
    final accountsSnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('accounts')
        .get();

    for (final doc in accountsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear transactions
    final transactionsSnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('transactions')
        .get();

    for (final doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear debts
    final debtsSnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('debts')
        .get();

    for (final doc in debtsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear goals
    final goalsSnapshot = await _firestore
        .collection('goals')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    for (final doc in goalsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear subscriptions  
    final subscriptionsSnapshot = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    for (final doc in subscriptionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear investments
    final investmentsSnapshot = await _firestore
        .collection('investments')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    for (final doc in investmentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear budgets
    final budgetsSnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    for (final doc in budgetsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Clear user profile (separate operation as it might not exist)
    try {
      await _firestore
          .collection('userProfiles')
          .doc(_currentUserId)
          .delete();
    } catch (e) {
      debugPrint('Error clearing user profile: $e');
    }
  }

  /// Restores accounts from backup
  Future<void> _restoreAccounts(List<dynamic> accountsData) async {
    final batch = _firestore.batch();

    for (final accountData in accountsData) {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('accounts')
          .doc(accountData['id']);

      final data = Map<String, dynamic>.from(accountData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores transactions from backup
  Future<void> _restoreTransactions(List<dynamic> transactionsData) async {
    final batch = _firestore.batch();

    for (final transactionData in transactionsData) {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(transactionData['id']);

      final data = Map<String, dynamic>.from(transactionData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores debts from backup
  Future<void> _restoreDebts(List<dynamic> debtsData) async {
    final batch = _firestore.batch();

    for (final debtData in debtsData) {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('debts')
          .doc(debtData['id']);

      final data = Map<String, dynamic>.from(debtData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores goals from backup
  Future<void> _restoreGoals(List<dynamic> goalsData) async {
    final batch = _firestore.batch();

    for (final goalData in goalsData) {
      final docRef = _firestore
          .collection('goals')
          .doc(goalData['id']);

      final data = Map<String, dynamic>.from(goalData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores subscriptions from backup
  /// Restores subscriptions from backup
  Future<void> _restoreSubscriptions(List<dynamic> subscriptionsData) async {
    final batch = _firestore.batch();

    for (final subscriptionData in subscriptionsData) {
      final docRef = _firestore
          .collection('subscriptions')
          .doc(subscriptionData['id']);

      final data = Map<String, dynamic>.from(subscriptionData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores investments from backup
  Future<void> _restoreInvestments(List<dynamic> investmentsData) async {
    final batch = _firestore.batch();

    for (final investmentData in investmentsData) {
      final docRef = _firestore
          .collection('investments')
          .doc(investmentData['id']);

      final data = Map<String, dynamic>.from(investmentData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores budgets from backup
  Future<void> _restoreBudgets(List<dynamic> budgetsData) async {
    final batch = _firestore.batch();

    for (final budgetData in budgetsData) {
      final docRef = _firestore
          .collection('budgets')
          .doc(budgetData['id']);

      final data = Map<String, dynamic>.from(budgetData);
      data.remove('id'); // Remove id from data since it's used as document ID

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Restores user profile from backup
  Future<void> _restoreUserProfile(Map<String, dynamic> userProfileData) async {
    final data = Map<String, dynamic>.from(userProfileData);
    data.remove('id'); // Remove id from data since it's used as document ID

    await _firestore
        .collection('userProfiles')
        .doc(_currentUserId)
        .set(data);
  }

  /// Syncs data across devices (essentially creates a backup)
  Future<void> syncData() async {
    try {
      await createBackup();
      debugPrint('Data synced successfully');
    } catch (e) {
      debugPrint('Error syncing data: $e');
      rethrow;
    }
  }

  /// Deletes old backups (keep only last 5)
  Future<void> cleanupOldBackups() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > 5) {
        final batch = _firestore.batch();

        // Delete backups beyond the 5 most recent
        for (int i = 5; i < snapshot.docs.length; i++) {
          batch.delete(snapshot.docs[i].reference);
        }

        await batch.commit();
        debugPrint('Old backups cleaned up');
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Gets backup status and statistics
  Future<Map<String, dynamic>> getBackupStatus() async {
    if (_currentUserId == null) {
      return {
        'isLoggedIn': false,
        'lastBackup': null,
        'totalBackups': 0,
        'canBackup': false,
      };
    }

    try {
      final backups = await getBackupHistory();

      return {
        'isLoggedIn': true,
        'lastBackup': backups.isNotEmpty ? backups.first['timestamp'] : null,
        'totalBackups': backups.length,
        'canBackup': true,
        'userId': _currentUserId,
      };
    } catch (e) {
      return {
        'isLoggedIn': true,
        'lastBackup': null,
        'totalBackups': 0,
        'canBackup': false,
        'error': e.toString(),
      };
    }
  }
}
