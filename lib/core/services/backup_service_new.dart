import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Complete backup service rebuilt from scratch
/// Based on actual collection structure analysis
class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Creates a complete backup of all user data
  Future<Map<String, dynamic>> createBackup() async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to create backup');
    }

    try {
      debugPrint('🔄 Starting backup for user: $_currentUserId');

      final backup = <String, dynamic>{
        'version': '2.0.0',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
        'metadata': {
          'createdAt': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0',
          'platform': 'flutter',
        },
      };

      // Backup all data types
      backup['accounts'] = await _backupAccounts();
      backup['transactions'] = await _backupTransactions();
      backup['debts'] = await _backupDebts();
      backup['budgets'] = await _backupBudgets();
      backup['investments'] = await _backupInvestments();
      backup['investmentTransactions'] = await _backupInvestmentTransactions();
      backup['goals'] = await _backupGoals();
      backup['userProfile'] = await _backupUserProfile();

      // Calculate backup size
      final accountsCount = (backup['accounts'] as List).length;
      final transactionsCount = (backup['transactions'] as List).length;
      final debtsCount = (backup['debts'] as List).length;
      final budgetsCount = (backup['budgets'] as List).length;
      final investmentsCount = (backup['investments'] as List).length;
      final investmentTransactionsCount = (backup['investmentTransactions'] as List).length;
      final goalsCount = (backup['goals'] as List).length;
      final hasProfile = backup['userProfile'] != null;

      backup['summary'] = {
        'accounts': accountsCount,
        'transactions': transactionsCount,
        'debts': debtsCount,
        'budgets': budgetsCount,
        'investments': investmentsCount,
        'investmentTransactions': investmentTransactionsCount,
        'goals': goalsCount,
        'userProfile': hasProfile ? 1 : 0,
        'totalItems': accountsCount + transactionsCount + debtsCount + budgetsCount + 
                     investmentsCount + investmentTransactionsCount + goalsCount + (hasProfile ? 1 : 0),
      };

      // Store backup in Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .add(backup);

      debugPrint('✅ Backup completed successfully');
      debugPrint('📊 Summary: ${backup['summary']}');
      
      return backup;
    } catch (e) {
      debugPrint('❌ Error creating backup: $e');
      rethrow;
    }
  }

  // =============================================================================
  // BACKUP METHODS - Based on actual collection structure
  // =============================================================================

  /// Backup accounts (subcollection: /users/{userId}/accounts)
  Future<List<Map<String, dynamic>>> _backupAccounts() async {
    try {
      debugPrint('📦 Backing up accounts...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('accounts')
          .get();

      final accounts = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${accounts.length} accounts');
      return accounts;
    } catch (e) {
      debugPrint('❌ Error backing up accounts: $e');
      return [];
    }
  }

  /// Backup transactions (subcollection: /users/{userId}/transactions)
  Future<List<Map<String, dynamic>>> _backupTransactions() async {
    try {
      debugPrint('📦 Backing up transactions...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .get();

      final transactions = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error backing up transactions: $e');
      return [];
    }
  }

  /// Backup debts (subcollection: /users/{userId}/debts)
  Future<List<Map<String, dynamic>>> _backupDebts() async {
    try {
      debugPrint('📦 Backing up debts...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('debts')
          .get();

      final debts = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${debts.length} debts');
      return debts;
    } catch (e) {
      debugPrint('❌ Error backing up debts: $e');
      return [];
    }
  }

  /// Backup budgets (subcollection: /users/{userId}/budgets)
  Future<List<Map<String, dynamic>>> _backupBudgets() async {
    try {
      debugPrint('📦 Backing up budgets...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('budgets')
          .get();

      final budgets = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${budgets.length} budgets');
      return budgets;
    } catch (e) {
      debugPrint('❌ Error backing up budgets: $e');
      return [];
    }
  }

  /// Backup investments (subcollection: /users/{userId}/investments)
  Future<List<Map<String, dynamic>>> _backupInvestments() async {
    try {
      debugPrint('📦 Backing up investments...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('investments')
          .get();

      final investments = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${investments.length} investments');
      return investments;
    } catch (e) {
      debugPrint('❌ Error backing up investments: $e');
      return [];
    }
  }

  /// Backup investment transactions (subcollection: /users/{userId}/investmentTransactions)
  Future<List<Map<String, dynamic>>> _backupInvestmentTransactions() async {
    try {
      debugPrint('📦 Backing up investment transactions...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('investmentTransactions')
          .get();

      final investmentTransactions = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${investmentTransactions.length} investment transactions');
      return investmentTransactions;
    } catch (e) {
      debugPrint('❌ Error backing up investment transactions: $e');
      return [];
    }
  }

  /// Backup goals (root collection: /goals with userId filter)
  Future<List<Map<String, dynamic>>> _backupGoals() async {
    try {
      debugPrint('📦 Backing up goals...');
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final goals = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      debugPrint('✅ Backed up ${goals.length} goals');
      return goals;
    } catch (e) {
      debugPrint('❌ Error backing up goals: $e');
      return [];
    }
  }

  /// Backup user profile (root collection: /userProfiles/{userId})
  Future<Map<String, dynamic>?> _backupUserProfile() async {
    try {
      debugPrint('📦 Backing up user profile...');
      final snapshot = await _firestore
          .collection('userProfiles')
          .doc(_currentUserId)
          .get();

      if (snapshot.exists) {
        final profile = {
          'id': snapshot.id,
          ...snapshot.data()!,
        };
        debugPrint('✅ Backed up user profile');
        return profile;
      } else {
        debugPrint('ℹ️ No user profile found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error backing up user profile: $e');
      return null;
    }
  }

  // =============================================================================
  // BACKUP HISTORY & MANAGEMENT
  // =============================================================================

  /// Get list of available backups
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
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting backup history: $e');
      return [];
    }
  }

  /// Delete old backups (keep only last 5)
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
        debugPrint('Cleaned up ${snapshot.docs.length - 5} old backups');
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// Quick sync (create backup for cross-device sync)
  Future<void> syncData() async {
    try {
      await createBackup();
      await cleanupOldBackups();
      debugPrint('Data synced successfully');
    } catch (e) {
      debugPrint('Error syncing data: $e');
      rethrow;
    }
  }

  // =============================================================================
  // RESTORE FUNCTIONALITY (Future implementation)
  // =============================================================================

  /// Restore from backup (placeholder for future implementation)
  Future<void> restoreFromBackup(String backupId) async {
    // TODO: Implement restore functionality
    throw UnimplementedError('Restore functionality will be implemented in next phase');
  }
}
