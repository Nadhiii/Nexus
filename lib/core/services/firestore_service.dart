import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/debt.dart';

class FirestoreService {
  static final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;

  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static firestore.CollectionReference<Map<String, dynamic>>? _getCollection(
    String collectionName,
  ) {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  // --- ACCOUNTS, TRANSACTIONS, GOALS (Same as before) ---
  // (I am omitting the unchanged methods for brevity, but they should be in the file)

  // ... (Paste Account, Transaction, Goal, Subscription methods here from previous file) ...

  // ACCOUNTS
  static Future<void> createAccount(Account account) async {
    final ref = _getCollection('accounts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(account.id).set(account.toMap());
  }

  static Stream<List<Account>> getAccountsStream() {
    final ref = _getCollection('accounts');
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map(
      (s) => s.docs.map((d) => Account.fromMap(d.data())).toList(),
    );
  }

  // TRANSACTIONS
  static Stream<List<Transaction>> getTransactionsStream({int? limit}) {
    final ref = _getCollection('transactions');
    if (ref == null) return Stream.value([]);
    var query = ref.orderBy('date', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
      (s) => s.docs.map((d) => Transaction.fromMap(d.data())).toList(),
    );
  }

  // ===========================================================================
  // DEBTS & LOANS (UPDATED)
  // ===========================================================================

  static Future<void> createDebt(Debt debt) async {
    final ref = _getCollection('debts');
    if (ref == null) throw Exception('User not logged in');
    String id = debt.id.isEmpty ? ref.doc().id : debt.id;
    // Uses toFirestore() which is compatible with your Provider
    await ref.doc(id).set(debt.toFirestore());
  }

  static Stream<List<Debt>> getDebtsStream() {
    final ref = _getCollection('debts');
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Debt.fromFirestore(doc); // Uses your factory
          }).toList(),
        );
  }

  static Future<void> updateDebt(Debt debt) async {
    final ref = _getCollection('debts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(debt.id).update(debt.toFirestore());
  }

  static Future<void> deleteDebt(String debtId) async {
    final ref = _getCollection('debts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(debtId).delete();
  }
}
