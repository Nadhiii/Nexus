import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/debt.dart';

class DebtService {
  final CollectionReference _debtsCollection = FirebaseFirestore.instance.collection('debts');

  Stream<List<Debt>> watchDebts(String userId) {
    return _debtsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList());
  }

  Future<void> addDebt(Debt debt) async {
    await _debtsCollection.doc(debt.id).set(debt.toJson());
  }

  Future<void> updateDebt(Debt debt) {
    return _debtsCollection.doc(debt.id).update(debt.toJson());
  }

  Future<void> deleteDebt(String debtId) {
    return _debtsCollection.doc(debtId).delete();
  }

  Future<void> addRepayment(String debtId, double amount) {
    return _debtsCollection.doc(debtId).update({
      'currentBalance': FieldValue.increment(-amount),
      'totalPaid': FieldValue.increment(amount),
      'lastPaymentDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearAllDebts(String userId) async {
    final snapshot = await _debtsCollection.where('userId', isEqualTo: userId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> restoreDebts(String userId, List<Debt> debts) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final debt in debts) {
      final docRef = _debtsCollection.doc(debt.id);
      batch.set(docRef, debt.toJson());
    }
    await batch.commit();
  }
  
  static String getDebtTypeDisplayName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.other:
        return 'Other';
      case DebtType.owedByMe:
        return 'Owed By Me';
      case DebtType.owedToMe:
        return 'Owed To Me';
    }
  }

  static IconData getDefaultIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      case DebtType.businessLoan:
        return Icons.business;
      case DebtType.goldLoan:
        return Icons.attach_money;
      case DebtType.other:
        return Icons.money_off;
      case DebtType.owedByMe:
        return Icons.arrow_downward;
      case DebtType.owedToMe:
        return Icons.arrow_upward;
    }
  }

  static Color getDefaultColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Colors.red;
      case DebtType.personalLoan:
        return Colors.orange;
      case DebtType.homeLoan:
        return Colors.green;
      case DebtType.carLoan:
        return Colors.blue;
      case DebtType.educationLoan:
        return Colors.purple;
      case DebtType.businessLoan:
        return Colors.teal;
      case DebtType.goldLoan:
        return Colors.yellow;
      case DebtType.other:
        return Colors.grey;
      case DebtType.owedByMe:
        return Colors.red.shade300;
      case DebtType.owedToMe:
        return Colors.green.shade300;
    }
  }
}
