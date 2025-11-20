import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment.dart';

class InvestmentService {
  final CollectionReference _investmentsCollection = FirebaseFirestore.instance.collection('investments');

  Stream<List<Investment>> watchInvestments(String userId) {
    return _investmentsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList());
  }

  Future<void> addInvestment(Investment investment) {
    return _investmentsCollection.add(investment.toJson());
  }

  Future<void> updateInvestment(Investment investment) {
    return _investmentsCollection.doc(investment.id).update(investment.toJson());
  }

  Future<void> deleteInvestment(String investmentId) {
    return _investmentsCollection.doc(investmentId).delete();
  }
}
