import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/debt.dart';

class DebtProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Debt> _debts = [];
  bool _isLoading = false;
  String? _error;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalDebt => _debts.where((d) => d.type != DebtType.owedToMe).fold(0.0, (sum, debt) => sum + debt.currentBalance);

  DebtProvider() {
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('debts') // Corrected collection name
          .snapshots()
          .listen((snapshot) {
        _debts = snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Error loading debts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .add(debt.toFirestore());
    } catch (e) {
      _error = 'Error adding debt: $e';
      notifyListeners();
    }
  }

  Future<void> updateDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .doc(debt.id)
          .update(debt.toFirestore());
    } catch (e) {
      _error = 'Error updating debt: $e';
      notifyListeners();
    }
  }

  Future<void> deleteDebt(String debtId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .doc(debtId)
          .delete();
    } catch (e) {
      _error = 'Error deleting debt: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    final snapshot = await _firestore.collection('users').doc(user.uid).collection('debts').get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _debts.clear();
    notifyListeners();
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    for (final item in data) {
      // This assumes the data is already in a Map<String, dynamic> format
      final debtData = Map<String, dynamic>.from(item);
      final docRef = _firestore.collection('users').doc(user.uid).collection('debts').doc();
      batch.set(docRef, debtData);
    }
    await batch.commit();
  }
}
