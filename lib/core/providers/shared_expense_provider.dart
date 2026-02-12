import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_expense.dart';

class SharedExpenseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SharedExpense> _expenses = [];
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _expenseSubscription;

  List<SharedExpense> get expenses => List.unmodifiable(_expenses);
  List<FamilyMember> get familyMembers => List.unmodifiable(_familyMembers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get current user's Firestore path for shared expenses
  String get _basePath {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');
    return 'users/$userId';
  }

  /// Initialize provider and load data
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      await _loadFamilyMembers();
      _subscribeToExpenses();
    } catch (e) {
      _setError('Failed to initialize shared expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Load family members from Firestore
  Future<void> _loadFamilyMembers() async {
    try {
      final snapshot = await _firestore
          .collection('$_basePath/family_members')
          .where('isActive', isEqualTo: true)
          .get();

      _familyMembers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FamilyMember.fromMap(data);
      }).toList();

      // Add current user as default member if not already in list
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !_familyMembers.any((m) => m.id == user.uid)) {
        _familyMembers.insert(
          0,
          FamilyMember(
            id: user.uid,
            name: user.displayName ?? 'Me',
            email: user.email,
            avatarUrl: user.photoURL,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading family members: $e');
    }
  }

  /// Subscribe to real-time expense updates
  void _subscribeToExpenses() {
    _expenseSubscription?.cancel();

    _expenseSubscription = _firestore
        .collection('$_basePath/shared_expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _expenses = snapshot.docs
                .map((doc) => SharedExpense.fromFirestore(doc))
                .toList();
            notifyListeners();
          },
          onError: (e) {
            _setError('Error loading expenses: $e');
          },
        );
  }

  /// Add a new family member
  Future<void> addFamilyMember(FamilyMember member) async {
    try {
      _setLoading(true);
      await _firestore
          .collection('$_basePath/family_members')
          .doc(member.id)
          .set(member.toMap());

      _familyMembers.add(member);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add family member: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update a family member
  Future<void> updateFamilyMember(FamilyMember member) async {
    try {
      await _firestore
          .collection('$_basePath/family_members')
          .doc(member.id)
          .update(member.toMap());

      final index = _familyMembers.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _familyMembers[index] = member;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update family member: $e');
      rethrow;
    }
  }

  /// Remove a family member (soft delete)
  Future<void> removeFamilyMember(String memberId) async {
    try {
      await _firestore
          .collection('$_basePath/family_members')
          .doc(memberId)
          .update({'isActive': false});

      _familyMembers.removeWhere((m) => m.id == memberId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove family member: $e');
      rethrow;
    }
  }

  /// Add a new shared expense
  Future<void> addSharedExpense(SharedExpense expense) async {
    try {
      _setLoading(true);
      await _firestore
          .collection('$_basePath/shared_expenses')
          .doc(expense.id)
          .set(expense.toMap());
    } catch (e) {
      _setError('Failed to add shared expense: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing shared expense
  Future<void> updateSharedExpense(SharedExpense expense) async {
    try {
      await _firestore
          .collection('$_basePath/shared_expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      _setError('Failed to update shared expense: $e');
      rethrow;
    }
  }

  /// Delete a shared expense
  Future<void> deleteSharedExpense(String expenseId) async {
    try {
      await _firestore
          .collection('$_basePath/shared_expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      _setError('Failed to delete shared expense: $e');
      rethrow;
    }
  }

  /// Mark a split as settled
  Future<void> settleSplit(String expenseId, String personId) async {
    try {
      final expense = _expenses.firstWhere((e) => e.id == expenseId);
      final updatedSplits = expense.splits.map((split) {
        if (split.personId == personId) {
          return split.copyWith(isSettled: true, settledDate: DateTime.now());
        }
        return split;
      }).toList();

      // Check if all splits are settled
      final allSettled = updatedSplits
          .where((s) => s.personId != expense.paidBy)
          .every((s) => s.isSettled);

      final updatedExpense = expense.copyWith(
        splits: updatedSplits,
        isSettled: allSettled,
        updatedAt: DateTime.now(),
      );

      await updateSharedExpense(updatedExpense);
    } catch (e) {
      _setError('Failed to settle split: $e');
      rethrow;
    }
  }

  /// Calculate net balances between all family members
  List<SettlementSummary> calculateSettlements() {
    // Map of personId -> net balance (positive = is owed money)
    final Map<String, double> balances = {};

    // Initialize balances for all members
    for (var member in _familyMembers) {
      balances[member.id] = 0.0;
    }

    // Process each unsettled expense
    for (var expense in _expenses.where((e) => !e.isSettled)) {
      // Payer is owed money
      for (var split in expense.splits) {
        if (split.personId != expense.paidBy && !split.isSettled) {
          // Payer gains credit
          balances[expense.paidBy] =
              (balances[expense.paidBy] ?? 0) + split.amount;
          // Split person owes money
          balances[split.personId] =
              (balances[split.personId] ?? 0) - split.amount;
        }
      }
    }

    // Generate settlement suggestions (who owes whom)
    final List<SettlementSummary> settlements = [];
    final debtors = balances.entries.where((e) => e.value < 0).toList();
    final creditors = balances.entries.where((e) => e.value > 0).toList();

    for (var debtor in debtors) {
      for (var creditor in creditors) {
        if (debtor.value.abs() > 0 && creditor.value > 0) {
          final debtorMember = _familyMembers.firstWhere(
            (m) => m.id == debtor.key,
            orElse: () => FamilyMember(id: debtor.key, name: 'Unknown'),
          );
          final creditorMember = _familyMembers.firstWhere(
            (m) => m.id == creditor.key,
            orElse: () => FamilyMember(id: creditor.key, name: 'Unknown'),
          );

          final amount = debtor.value.abs() < creditor.value
              ? debtor.value.abs()
              : creditor.value;

          if (amount > 0) {
            settlements.add(
              SettlementSummary(
                person1Id: creditor.key,
                person1Name: creditorMember.name,
                person2Id: debtor.key,
                person2Name: debtorMember.name,
                netAmount: amount,
              ),
            );
          }
        }
      }
    }

    return settlements;
  }

  /// Get total amount a person is owed (across all expenses)
  double getTotalOwedTo(String personId) {
    double total = 0;
    for (var expense in _expenses) {
      if (expense.paidBy == personId && !expense.isSettled) {
        for (var split in expense.splits) {
          if (split.personId != personId && !split.isSettled) {
            total += split.amount;
          }
        }
      }
    }
    return total;
  }

  /// Get total amount a person owes to others
  double getTotalOwedBy(String personId) {
    double total = 0;
    for (var expense in _expenses) {
      if (expense.paidBy != personId && !expense.isSettled) {
        final split = expense.splits.firstWhere(
          (s) => s.personId == personId,
          orElse: () => ExpenseSplit(personId: '', personName: '', amount: 0),
        );
        if (!split.isSettled) {
          total += split.amount;
        }
      }
    }
    return total;
  }

  /// Get expenses filtered by date range
  List<SharedExpense> getExpensesInRange(DateTime start, DateTime end) {
    return _expenses
        .where(
          (e) =>
              e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  /// Get spending summary for each family member in a date range
  Map<String, double> getSpendingSummary(DateTime start, DateTime end) {
    final Map<String, double> summary = {};

    for (var member in _familyMembers) {
      summary[member.id] = 0.0;
    }

    for (var expense in getExpensesInRange(start, end)) {
      for (var split in expense.splits) {
        summary[split.personId] = (summary[split.personId] ?? 0) + split.amount;
      }
    }

    return summary;
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
