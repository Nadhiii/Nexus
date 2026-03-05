// ignore_for_file: avoid_types_as_parameter_names
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_debt.dart';
import '../models/shared_expense.dart';

class FamilyDebtProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<FamilyDebt> _debts = [];
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _debtSubscription;
  StreamSubscription<QuerySnapshot>? _memberSubscription;

  // Getters
  List<FamilyDebt> get debts => _debts;
  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _userId => _auth.currentUser?.uid;

  /// Debts where current user is owed money
  List<FamilyDebt> get debtsOwedToMe =>
      _debts.where((d) => d.creditorId == _userId && !d.isSettled).toList();

  /// Debts where current user owes money
  List<FamilyDebt> get debtsIOweTo =>
      _debts.where((d) => d.debtorId == _userId && !d.isSettled).toList();

  /// Total amount owed to current user
  double get totalOwedToMe =>
      debtsOwedToMe.fold(0, (sum, d) => sum + d.currentAmount);

  /// Total amount current user owes
  double get totalIOweTo =>
      debtsIOweTo.fold(0, (sum, d) => sum + d.currentAmount);

  /// Net balance (positive = others owe me, negative = I owe others)
  double get netBalance => totalOwedToMe - totalIOweTo;

  /// Get summary per family member
  List<FamilyDebtSummary> get summaryByPerson {
    final Map<String, FamilyDebtSummary> summaryMap = {};

    for (final debt in _debts.where((d) => !d.isSettled)) {
      final isCreditor = debt.creditorId == _userId;
      final otherPersonId = isCreditor ? debt.debtorId : debt.creditorId;
      final otherPersonName = isCreditor ? debt.debtorName : debt.creditorName;

      final existing = summaryMap[otherPersonId];
      if (existing == null) {
        summaryMap[otherPersonId] = FamilyDebtSummary(
          personId: otherPersonId,
          personName: otherPersonName,
          theyOweMe: isCreditor ? debt.currentAmount : 0,
          iOweThem: isCreditor ? 0 : debt.currentAmount,
          activeDebts: 1,
        );
      } else {
        summaryMap[otherPersonId] = FamilyDebtSummary(
          personId: otherPersonId,
          personName: otherPersonName,
          theyOweMe: existing.theyOweMe + (isCreditor ? debt.currentAmount : 0),
          iOweThem: existing.iOweThem + (isCreditor ? 0 : debt.currentAmount),
          activeDebts: existing.activeDebts + 1,
        );
      }
    }

    return summaryMap.values.toList()
      ..sort((a, b) => b.netBalance.abs().compareTo(a.netBalance.abs()));
  }

  void initialize() {
    if (_userId == null) { return; }

    _loadFamilyMembers();
    _loadDebts();
  }

  void _loadFamilyMembers() {
    _memberSubscription?.cancel();
    _memberSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .collection('family_members')
        .snapshots()
        .listen((snapshot) {
          _familyMembers = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add the document ID
            return FamilyMember.fromMap(data);
          }).toList();
          notifyListeners();
        }, onError: (e) => _setError('Failed to load family members: $e'));
  }

  void _loadDebts() {
    _debtSubscription?.cancel();
    _setLoading(true);

    _debtSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .collection('family_debts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _debts = snapshot.docs
                .map((doc) => FamilyDebt.fromMap(doc.data(), doc.id))
                .toList();
            _setLoading(false);
            notifyListeners();
          },
          onError: (e) {
            _setError('Failed to load debts: $e');
            _setLoading(false);
          },
        );
  }

  /// Add a new family debt
  Future<void> addDebt(FamilyDebt debt) async {
    if (_userId == null) { return; }

    try {
      _setLoading(true);
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('family_debts')
          .add(debt.toMap());
    } catch (e) {
      _setError('Failed to add debt: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Record a payment for a debt
  Future<void> recordPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    if (_userId == null) { return; }

    try {
      _setLoading(true);
      final debtRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('family_debts')
          .doc(debtId);

      final debtDoc = await debtRef.get();
      if (!debtDoc.exists) { throw Exception('Debt not found'); }

      final debt = FamilyDebt.fromMap(debtDoc.data()!, debtDoc.id);
      final newBalance = (debt.currentAmount - amount).clamp(
        0,
        double.infinity,
      );

      final payment = FamilyDebtPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        notes: notes,
      );

      await debtRef.update({
        'currentAmount': newBalance,
        'payments': FieldValue.arrayUnion([payment.toMap()]),
        'isSettled': newBalance <= 0,
      });
    } catch (e) {
      _setError('Failed to record payment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Settle a debt completely
  Future<void> settleDebt(String debtId) async {
    if (_userId == null) { return; }

    try {
      _setLoading(true);
      final debt = _debts.firstWhere((d) => d.id == debtId);

      if (debt.currentAmount > 0) {
        await recordPayment(
          debtId,
          debt.currentAmount,
          notes: 'Full settlement',
        );
      } else {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('family_debts')
            .doc(debtId)
            .update({'isSettled': true});
      }
    } catch (e) {
      _setError('Failed to settle debt: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a debt
  Future<void> deleteDebt(String debtId) async {
    if (_userId == null) { return; }

    try {
      _setLoading(true);
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('family_debts')
          .doc(debtId)
          .delete();
    } catch (e) {
      _setError('Failed to delete debt: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get debts involving a specific person
  List<FamilyDebt> getDebtsWithPerson(String personId) {
    return _debts
        .where(
          (d) =>
              (d.creditorId == personId || d.debtorId == personId) &&
              !d.isSettled,
        )
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    if (value != null) { debugPrint('FamilyDebtProvider error: $value'); }
    notifyListeners();
  }

  @override
  void dispose() {
    _debtSubscription?.cancel();
    _memberSubscription?.cancel();
    super.dispose();
  }
}
