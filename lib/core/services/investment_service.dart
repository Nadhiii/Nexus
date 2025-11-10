import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/investment.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Get user's investment collection reference
  CollectionReference get _investmentsCollection =>
      _firestore.collection('users').doc(_userId).collection('investments');

  /// Get investment transactions collection reference
  CollectionReference get _transactionsCollection => _firestore
      .collection('users')
      .doc(_userId)
      .collection('investmentTransactions');

  // CRUD Operations for Investments

  /// Add a new investment
  Future<void> addInvestment(Investment investment) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Use Firestore auto-generated ID if investment ID is empty
      DocumentReference docRef;
      if (investment.id.isEmpty) {
        docRef = _investmentsCollection.doc();
      } else {
        docRef = _investmentsCollection.doc(investment.id);
      }
      
      // Create investment with the proper ID
      final investmentWithId = investment.copyWith(id: docRef.id);
      
      await docRef.set(investmentWithId.toMap());
      debugPrint('Investment added: ${investment.name}');
    } catch (e) {
      debugPrint('Error adding investment: $e');
      rethrow;
    }
  }

  /// Update an existing investment
  Future<void> updateInvestment(Investment investment) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _investmentsCollection
          .doc(investment.id)
          .update(investment.toMap());
      debugPrint('Investment updated: ${investment.name}');
    } catch (e) {
      debugPrint('Error updating investment: $e');
      rethrow;
    }
  }

  /// Delete an investment
  Future<void> deleteInvestment(String investmentId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Delete the investment
      await _investmentsCollection.doc(investmentId).delete();

      // Delete all related transactions
      final transactions = await _transactionsCollection
          .where('investmentId', isEqualTo: investmentId)
          .get();

      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }

      debugPrint('Investment deleted: $investmentId');
    } catch (e) {
      debugPrint('Error deleting investment: $e');
      rethrow;
    }
  }

  /// Get all investments
  Stream<List<Investment>> watchInvestments() {
    if (_userId == null) return Stream.value([]);

    return _investmentsCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Investment.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get investments for a specific account
  Stream<List<Investment>> watchInvestmentsByAccount(String accountId) {
    if (_userId == null) return Stream.value([]);

    return _investmentsCollection
        .where('accountId', isEqualTo: accountId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Investment.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Get a single investment by ID
  Future<Investment?> getInvestment(String investmentId) async {
    if (_userId == null) return null;

    try {
      final doc = await _investmentsCollection.doc(investmentId).get();
      if (doc.exists) {
        return Investment.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting investment: $e');
      return null;
    }
  }

  // Investment Transaction Operations

  /// Add investment transaction (buy/sell/dividend)
  Future<void> addInvestmentTransaction(
    InvestmentTransaction transaction,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _transactionsCollection
          .doc(transaction.id)
          .set(transaction.toMap());

      // Update investment totals after transaction
      await _updateInvestmentTotals(transaction.investmentId);

      debugPrint('Investment transaction added: ${transaction.type.name}');
    } catch (e) {
      debugPrint('Error adding investment transaction: $e');
      rethrow;
    }
  }

  /// Get investment transactions for a specific investment
  Stream<List<InvestmentTransaction>> watchInvestmentTransactions(
    String investmentId,
  ) {
    if (_userId == null) return Stream.value([]);

    return _transactionsCollection
        .where('investmentId', isEqualTo: investmentId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => InvestmentTransaction.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Update investment totals based on transactions
  Future<void> _updateInvestmentTotals(String investmentId) async {
    final investment = await getInvestment(investmentId);
    if (investment == null) return;

    final transactionsSnapshot = await _transactionsCollection
        .where('investmentId', isEqualTo: investmentId)
        .get();

    double totalUnits = 0;
    double totalInvested = 0;
    double totalSold = 0;

    for (var doc in transactionsSnapshot.docs) {
      final transaction = InvestmentTransaction.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });

      switch (transaction.type) {
        case InvestmentTransactionType.buy:
          totalUnits += transaction.units;
          totalInvested += transaction.amount;
          break;
        case InvestmentTransactionType.sell:
          totalUnits -= transaction.units;
          totalSold += transaction.amount;
          break;
        case InvestmentTransactionType.bonus:
          totalUnits += transaction.units;
          break;
        // For dividends and splits, we don't change units or invested amount
        case InvestmentTransactionType.dividend:
        case InvestmentTransactionType.split:
          break;
      }
    }

    // Calculate average price
    final averagePrice = totalUnits > 0
        ? (totalInvested - totalSold) / totalUnits
        : 0.0;
    final currentValue = totalUnits * investment.currentPrice;

    // Update the investment
    final updatedInvestment = investment.copyWith(
      units: totalUnits,
      averagePrice: averagePrice,
      totalInvested: totalInvested - totalSold,
      currentValue: currentValue,
      updatedAt: DateTime.now(),
    );

    await updateInvestment(updatedInvestment);
  }

  // Portfolio Analysis

  /// Calculate total portfolio value
  Future<double> getTotalPortfolioValue() async {
    if (_userId == null) return 0.0;

    try {
      final snapshot = await _investmentsCollection.get();
      double total = 0.0;

      for (var doc in snapshot.docs) {
        final investment = Investment.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        total += investment.currentValue;
      }

      return total;
    } catch (e) {
      debugPrint('Error calculating portfolio value: $e');
      return 0.0;
    }
  }

  /// Calculate total portfolio gain/loss
  Future<double> getTotalPortfolioGainLoss() async {
    if (_userId == null) return 0.0;

    try {
      final snapshot = await _investmentsCollection.get();
      double totalGainLoss = 0.0;

      for (var doc in snapshot.docs) {
        final investment = Investment.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        totalGainLoss += investment.gainLoss;
      }

      return totalGainLoss;
    } catch (e) {
      debugPrint('Error calculating portfolio gain/loss: $e');
      return 0.0;
    }
  }

  /// Get portfolio summary by investment type
  Future<Map<InvestmentType, double>> getPortfolioByType() async {
    if (_userId == null) return {};

    try {
      final snapshot = await _investmentsCollection.get();
      Map<InvestmentType, double> summary = {};

      for (var doc in snapshot.docs) {
        final investment = Investment.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });

        summary[investment.type] =
            (summary[investment.type] ?? 0.0) + investment.currentValue;
      }

      return summary;
    } catch (e) {
      debugPrint('Error getting portfolio by type: $e');
      return {};
    }
  }

  /// Update current prices (in a real app, this would fetch from market data API)
  Future<void> updateCurrentPrices() async {
    // This is a placeholder - in a real app, you'd integrate with
    // market data APIs like Alpha Vantage, Yahoo Finance, etc.
    debugPrint('Price update functionality would be implemented here');
  }
}
