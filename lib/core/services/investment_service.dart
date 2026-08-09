import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _investmentsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('investments');
  }

  String _requireUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  Stream<List<Investment>> watchInvestments(String userId) {
    return _investmentsCollection(userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Investment.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addInvestment(Investment investment) async {
    final userId = _requireUserId();
    final docRef = _investmentsCollection(userId).doc();
    await docRef.set(investment.copyWith(id: docRef.id, userId: userId).toMap());
  }

  Future<void> updateInvestment(Investment investment) async {
    final userId = _requireUserId();
    await _investmentsCollection(userId)
        .doc(investment.id)
        .update(investment.copyWith(userId: userId).toMap());
  }

  Future<void> deleteInvestment(String investmentId) async {
    final userId = _requireUserId();
    await _investmentsCollection(userId).doc(investmentId).delete();
  }
}
