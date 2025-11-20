import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';

class FirestoreService {
  static final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Helper to get a user-specific collection reference
  static firestore.CollectionReference<Map<String, dynamic>>? _getCollection(String collectionName) {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  // Helper to get the user document reference
  static firestore.DocumentReference<Map<String, dynamic>>? get _userDocRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // Accounts
  static Future<void> createAccount(Account account) async {
    final ref = _getCollection('accounts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(account.id).set(account.toMap());
  }

  static Future<List<Account>> getAccounts() async {
    final ref = _getCollection('accounts');
    if (ref == null) return [];
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList();
  }

  static Stream<List<Account>> getAccountsStream() {
    final ref = _getCollection('accounts');
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snapshot) => snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList());
  }

  static Future<void> updateAccount(Account account) async {
    final ref = _getCollection('accounts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(account.id).update(account.toMap());
  }

  static Future<void> deleteAccount(String accountId) async {
    final ref = _getCollection('accounts');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(accountId).delete();
  }

  // Transactions
  static Future<void> createTransaction(Transaction transaction) async {
    final ref = _getCollection('transactions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(transaction.id).set(transaction.toMap());
  }

  static Future<List<Transaction>> getTransactions({int? limit, DateTime? startDate, DateTime? endDate}) async {
    final ref = _getCollection('transactions');
    if (ref == null) return [];

    firestore.Query<Map<String, dynamic>> query = ref.orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
  }

  static Stream<List<Transaction>> getTransactionsStream({int? limit}) {
    final ref = _getCollection('transactions');
    if (ref == null) return Stream.value([]);

    firestore.Query<Map<String, dynamic>> query = ref.orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList(),
    );
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final ref = _getCollection('transactions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(transaction.id).update(transaction.toMap());
  }

  static Future<void> deleteTransaction(String transactionId) async {
    final ref = _getCollection('transactions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(transactionId).delete();
  }

  // Goals
  static Future<void> createGoal(Goal goal) async {
    final ref = _getCollection('goals');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(goal.id).set(goal.toMap());
  }

  static Future<List<Goal>> getGoals() async {
    final ref = _getCollection('goals');
    if (ref == null) return [];
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => Goal.fromMap(doc.data())).toList();
  }

  static Stream<List<Goal>> getGoalsStream() {
    final ref = _getCollection('goals');
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snapshot) => snapshot.docs.map((doc) => Goal.fromMap(doc.data())).toList());
  }

  static Future<void> updateGoal(Goal goal) async {
    final ref = _getCollection('goals');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(goal.id).update(goal.toMap());
  }

  static Future<void> deleteGoal(String goalId) async {
    final ref = _getCollection('goals');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(goalId).delete();
  }

  // Subscriptions
  static Future<void> createSubscription(Subscription subscription) async {
    final ref = _getCollection('subscriptions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(subscription.id).set(subscription.toMap());
  }

  static Future<List<Subscription>> getSubscriptions() async {
    final ref = _getCollection('subscriptions');
    if (ref == null) return [];
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList();
  }

  static Stream<List<Subscription>> getSubscriptionsStream() {
    final ref = _getCollection('subscriptions');
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snapshot) => snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList());
  }

  static Future<List<Subscription>> getDueSubscriptions() async {
    final ref = _getCollection('subscriptions');
    if (ref == null) return [];
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String();

    final snapshot = await ref
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isLessThanOrEqualTo: todayString)
        .get();

    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList();
  }

  static Future<void> updateSubscription(Subscription subscription) async {
    final ref = _getCollection('subscriptions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(subscription.id).update(subscription.toMap());
  }

  static Future<void> deleteSubscription(String subscriptionId) async {
    final ref = _getCollection('subscriptions');
    if (ref == null) throw Exception('User not logged in');
    await ref.doc(subscriptionId).delete();
  }

  // Analytics & Reports
  static Future<Map<String, double>> getNetWorth() async {
    final accounts = await getAccounts();
    double assets = 0;
    double liabilities = 0;
    for (final account in accounts) {
      if (account.type == 'asset') {
        assets += account.balance;
      } else if (account.type == 'liability') {
        liabilities += account.balance;
      }
    }
    return {'assets': assets, 'liabilities': liabilities, 'netWorth': assets - liabilities,};
  }

  static Future<Map<String, double>> getCashFlow({DateTime? startDate, DateTime? endDate}) async {
    final transactions = await getTransactions(startDate: startDate, endDate: endDate);
    double income = 0;
    double expenses = 0;
    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expenses += transaction.amount;
      }
    }
    return {'income': income, 'expenses': expenses, 'netCashFlow': income - expenses,};
  }

  // User Profiles
  static Future<UserProfile> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return UserProfile.fromMap(doc.data()!);
  }

  static Future<void> saveUserProfile(UserProfile userProfile) async {
    await _firestore.collection('users').doc(userProfile.uid).set(userProfile.toMap(), firestore.SetOptions(merge: true));
  }

  static Future<void> updateUserProfile(UserProfile userProfile) async {
    await _firestore.collection('users').doc(userProfile.uid).update(userProfile.toMap());
  }

  static Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserProfile.fromMap(doc.data()!) : null,
    );
  }
}
