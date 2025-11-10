import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';

class FirestoreService {
  static final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  
  // Get current user ID
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // Collections
  static const String _accountsCollection = 'accounts';
  static const String _transactionsCollection = 'transactions';
  static const String _goalsCollection = 'goals';
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _userProfilesCollection = 'userProfiles';
  
  // Accounts
  static Future<void> createAccount(Account account) async {
    await _firestore.collection(_accountsCollection).doc(account.id).set(account.toMap());
  }
  
  static Future<List<Account>> getAccounts() async {
    if (currentUserId == null) return [];
    final snapshot = await _firestore
        .collection(_accountsCollection)
        .where('userId', isEqualTo: currentUserId)
        .get();
    return snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList();
  }
  
  static Stream<List<Account>> getAccountsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection(_accountsCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList());
  }
  
  static Future<void> updateAccount(Account account) async {
    await _firestore.collection(_accountsCollection).doc(account.id).update(account.toMap());
  }
  
  static Future<void> deleteAccount(String accountId) async {
    await _firestore.collection(_accountsCollection).doc(accountId).delete();
  }
  
  // Transactions
  static Future<void> createTransaction(Transaction transaction) async {
    await _firestore.collection(_transactionsCollection).doc(transaction.id).set(transaction.toMap());
  }
  
  static Future<List<Transaction>> getTransactions({int? limit, DateTime? startDate, DateTime? endDate}) async {
    if (currentUserId == null) return [];
    
    firestore.Query query = _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true);
    
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
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
  
  static Stream<List<Transaction>> getTransactionsStream({int? limit}) {
    if (currentUserId == null) return Stream.value([]);
    
    firestore.Query query = _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>)).toList(),
    );
  }
  
  static Future<void> updateTransaction(Transaction transaction) async {
    await _firestore.collection(_transactionsCollection).doc(transaction.id).update(transaction.toMap());
  }
  
  static Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection(_transactionsCollection).doc(transactionId).delete();
  }
  
  // Goals
  static Future<void> createGoal(Goal goal) async {
    await _firestore.collection(_goalsCollection).doc(goal.id).set(goal.toMap());
  }
  
  static Future<List<Goal>> getGoals() async {
    final snapshot = await _firestore.collection(_goalsCollection).get();
    return snapshot.docs.map((doc) => Goal.fromMap(doc.data())).toList();
  }
  
  static Stream<List<Goal>> getGoalsStream() {
    return _firestore.collection(_goalsCollection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Goal.fromMap(doc.data())).toList(),
    );
  }
  
  static Future<void> updateGoal(Goal goal) async {
    await _firestore.collection(_goalsCollection).doc(goal.id).update(goal.toMap());
  }
  
  static Future<void> deleteGoal(String goalId) async {
    await _firestore.collection(_goalsCollection).doc(goalId).delete();
  }
  
  // Subscriptions
  static Future<void> createSubscription(Subscription subscription) async {
    await _firestore.collection(_subscriptionsCollection).doc(subscription.id).set(subscription.toMap());
  }
  
  static Future<List<Subscription>> getSubscriptions() async {
    final snapshot = await _firestore.collection(_subscriptionsCollection).get();
    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList();
  }
  
  static Stream<List<Subscription>> getSubscriptionsStream() {
    return _firestore.collection(_subscriptionsCollection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList(),
    );
  }
  
  static Future<List<Subscription>> getDueSubscriptions() async {
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day).toIso8601String();
    
    final snapshot = await _firestore
        .collection(_subscriptionsCollection)
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isLessThanOrEqualTo: todayString)
        .get();
    
    return snapshot.docs.map((doc) => Subscription.fromMap(doc.data())).toList();
  }
  
  static Future<void> updateSubscription(Subscription subscription) async {
    await _firestore.collection(_subscriptionsCollection).doc(subscription.id).update(subscription.toMap());
  }
  
  static Future<void> deleteSubscription(String subscriptionId) async {
    await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).delete();
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
    
    return {
      'assets': assets,
      'liabilities': liabilities,
      'netWorth': assets - liabilities,
    };
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
    
    return {
      'income': income,
      'expenses': expenses,
      'netCashFlow': income - expenses,
    };
  }

  // User Profiles
  static Future<UserProfile> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_userProfilesCollection).doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return UserProfile.fromMap(doc.data()!);
  }

  static Future<void> saveUserProfile(UserProfile userProfile) async {
    await _firestore.collection(_userProfilesCollection).doc(userProfile.uid).set(userProfile.toMap());
  }

  static Future<void> updateUserProfile(UserProfile userProfile) async {
    await _firestore.collection(_userProfilesCollection).doc(userProfile.uid).update(userProfile.toMap());
  }

  static Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection(_userProfilesCollection).doc(uid).snapshots().map(
      (doc) => doc.exists ? UserProfile.fromMap(doc.data()!) : null,
    );
  }
}
