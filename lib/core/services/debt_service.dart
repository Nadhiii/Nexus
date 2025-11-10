import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/debt.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> _debtsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('debts');
  }

  // Create a new debt
  Future<String> createDebt(String userId, Debt debt) async {
    try {
      final docRef = await _debtsCollection(userId).add(debt.toMap());

      // Update the debt with the generated ID
      final updatedDebt = debt.copyWith(id: docRef.id);
      await docRef.update(updatedDebt.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create debt: $e');
    }
  }

  // Get all debts for a user
  Stream<List<Debt>> watchUserDebts(String userId) {
    return _debtsCollection(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Debt.fromMap(data);
          }).toList();
        });
  }

  // Get debts sorted by different strategies
  Stream<List<Debt>> watchDebtsByStrategy(
    String userId,
    DebtPayoffStrategy strategy,
  ) {
    return watchUserDebts(userId).map((debts) {
      List<Debt> sortedDebts = List.from(debts);

      switch (strategy) {
        case DebtPayoffStrategy.snowball:
          // Sort by current balance (smallest first)
          sortedDebts.sort(
            (a, b) => a.currentBalance.compareTo(b.currentBalance),
          );
          break;
        case DebtPayoffStrategy.avalanche:
          // Sort by interest rate (highest first)
          sortedDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
          break;
        case DebtPayoffStrategy.custom:
          // Sort by user-defined priority
          sortedDebts.sort((a, b) => a.priority.compareTo(b.priority));
          break;
      }

      return sortedDebts;
    });
  }

  // Get a specific debt
  Future<Debt?> getDebt(String userId, String debtId) async {
    try {
      final doc = await _debtsCollection(userId).doc(debtId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Debt.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get debt: $e');
    }
  }

  // Update a debt
  Future<void> updateDebt(String userId, Debt debt) async {
    try {
      await _debtsCollection(
        userId,
      ).doc(debt.id).update(debt.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update debt: $e');
    }
  }

  // Record a payment
  Future<void> recordPayment(
    String userId,
    String debtId,
    double paymentAmount,
  ) async {
    try {
      final debt = await getDebt(userId, debtId);
      if (debt == null) throw Exception('Debt not found');

      // Calculate interest portion and principal portion
      double monthlyInterest =
          (debt.currentBalance * (debt.interestRate / 100)) / 12;
      double principalPayment = paymentAmount - monthlyInterest;
      double newBalance = (debt.currentBalance - principalPayment).clamp(
        0.0,
        double.infinity,
      );

      final updatedDebt = debt.copyWith(
        currentBalance: newBalance,
        lastPaymentDate: DateTime.now(),
        totalPaid: debt.totalPaid + paymentAmount,
        totalInterestPaid:
            debt.totalInterestPaid + monthlyInterest.clamp(0.0, paymentAmount),
        updatedAt: DateTime.now(),
      );

      await updateDebt(userId, updatedDebt);
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  // Delete a debt (soft delete)
  Future<void> deleteDebt(String userId, String debtId) async {
    try {
      await _debtsCollection(userId).doc(debtId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete debt: $e');
    }
  }

  // Calculate total debt
  Stream<double> watchTotalDebt(String userId) {
    return watchUserDebts(userId).map((debts) {
      return debts.fold(0.0, (sum, debt) => sum + debt.currentBalance);
    });
  }

  // Calculate total minimum payments
  Stream<double> watchTotalMinimumPayments(String userId) {
    return watchUserDebts(userId).map((debts) {
      return debts.fold(0.0, (sum, debt) => sum + debt.monthlyEMI);
    });
  }

  // Calculate total monthly interest
  Stream<double> watchTotalMonthlyInterest(String userId) {
    return watchUserDebts(userId).map((debts) {
      return debts.fold(0.0, (sum, debt) => sum + debt.monthlyInterestPayment);
    });
  }

  // Get debt statistics
  Stream<Map<String, dynamic>> watchDebtStatistics(String userId) {
    return watchUserDebts(userId).map((debts) {
      if (debts.isEmpty) {
        return {
          'totalDebt': 0.0,
          'totalMinimumPayments': 0.0,
          'totalMonthlyInterest': 0.0,
          'averageInterestRate': 0.0,
          'highestInterestRate': 0.0,
          'lowestInterestRate': 0.0,
          'debtCount': 0,
          'totalOriginalAmount': 0.0,
          'totalProgress': 0.0,
        };
      }

      double totalDebt = debts.fold(
        0.0,
        (sum, debt) => sum + debt.currentBalance,
      );
      double totalMinimum = debts.fold(
        0.0,
        (sum, debt) => sum + debt.monthlyEMI,
      );
      double totalInterest = debts.fold(
        0.0,
        (sum, debt) => sum + debt.monthlyInterestPayment,
      );
      double totalOriginal = debts.fold(
        0.0,
        (sum, debt) => sum + debt.originalAmount,
      );
      double totalPaid = totalOriginal - totalDebt;
      double totalProgress = totalOriginal > 0
          ? (totalPaid / totalOriginal * 100)
          : 0.0;

      List<double> rates = debts.map((debt) => debt.interestRate).toList();
      double avgRate =
          rates.fold(0.0, (sum, rate) => sum + rate) / rates.length;

      return {
        'totalDebt': totalDebt,
        'totalMinimumPayments': totalMinimum,
        'totalMonthlyInterest': totalInterest,
        'averageInterestRate': avgRate,
        'highestInterestRate': rates.reduce((a, b) => a > b ? a : b),
        'lowestInterestRate': rates.reduce((a, b) => a < b ? a : b),
        'debtCount': debts.length,
        'totalOriginalAmount': totalOriginal,
        'totalProgress': totalProgress,
      };
    });
  }

  // Calculate debt-free date with different strategies
  Map<String, dynamic> calculateDebtFreeDate(
    List<Debt> debts,
    DebtPayoffStrategy strategy,
    double extraPayment,
  ) {
    if (debts.isEmpty) {
      return {
        'date': DateTime.now(),
        'totalInterest': 0.0,
        'totalPayments': 0.0,
        'monthsToFreedom': 0,
      };
    }

    List<Debt> workingDebts = List.from(debts);
    double totalExtraPayment = extraPayment;
    int totalMonths = 0;
    double totalInterestPaid = 0.0;

    // Sort debts based on strategy
    switch (strategy) {
      case DebtPayoffStrategy.snowball:
        workingDebts.sort(
          (a, b) => a.currentBalance.compareTo(b.currentBalance),
        );
        break;
      case DebtPayoffStrategy.avalanche:
        workingDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
        break;
      case DebtPayoffStrategy.custom:
        workingDebts.sort((a, b) => a.priority.compareTo(b.priority));
        break;
    }

    // Simulate payments
    while (workingDebts.isNotEmpty && totalMonths < 1000) {
      totalMonths++;

      // Pay minimum on all debts and calculate interest
      for (int i = 0; i < workingDebts.length; i++) {
        Debt debt = workingDebts[i];
        double monthlyInterest = debt.monthlyInterestPayment;
        double payment = debt.monthlyEMI;

        // Add extra payment to the first debt (highest priority)
        if (i == 0) {
          payment += totalExtraPayment;
        }

        totalInterestPaid += monthlyInterest;
        double principalPayment = (payment - monthlyInterest).clamp(
          0.0,
          debt.currentBalance,
        );

        workingDebts[i] = debt.copyWith(
          currentBalance: debt.currentBalance - principalPayment,
        );
      }

      // Remove paid-off debts and add their minimum payment to extra payment
      workingDebts.removeWhere((debt) {
        if (debt.currentBalance <= 0) {
          totalExtraPayment += debt.monthlyEMI;
          return true;
        }
        return false;
      });
    }

    DateTime debtFreeDate = DateTime.now().add(
      Duration(days: totalMonths * 30),
    );
    double totalPayments =
        debts.fold(0.0, (sum, debt) => sum + debt.currentBalance) +
        totalInterestPaid;

    return {
      'date': debtFreeDate,
      'totalInterest': totalInterestPaid,
      'totalPayments': totalPayments,
      'monthsToFreedom': totalMonths,
    };
  }

  // Get default debt icons and colors
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
        return Icons.star;
      case DebtType.other:
        return Icons.money_off;
    }
  }

  static Color getDefaultColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Colors.red;
      case DebtType.personalLoan:
        return Colors.orange;
      case DebtType.homeLoan:
        return Colors.blue;
      case DebtType.carLoan:
        return Colors.green;
      case DebtType.educationLoan:
        return Colors.purple;
      case DebtType.businessLoan:
        return Colors.teal;
      case DebtType.goldLoan:
        return Colors.amber;
      case DebtType.other:
        return Colors.grey;
    }
  }
}
