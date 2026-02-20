import 'package:cloud_firestore/cloud_firestore.dart' as fs;

/// CascadeService: Handles atomic deletion of accounts and their transactions
class CascadeService {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;

  /// Atomically delete an account and all its transactions
  Future<void> deleteAccountAndTransactions({
    required String userId,
    required String accountId,
  }) async {
    final accountRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId);
    final transactionsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');

    // Query all transactions for this account
    final txnSnapshot = await transactionsRef
        .where('accountId', isEqualTo: accountId)
        .get();

    final batch = _firestore.batch();
    // Delete all transactions
    for (final doc in txnSnapshot.docs) {
      batch.delete(doc.reference);
    }
    // Delete the account
    batch.delete(accountRef);
    await batch.commit();
  }
}
