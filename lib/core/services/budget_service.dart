import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> _budgetsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  // Collection reference for transactions (to calculate spent amounts)
  CollectionReference<Map<String, dynamic>> _transactionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  /// Create a new budget
  Future<String> createBudget(String userId, Budget budget) async {
    try {
      final docRef = await _budgetsCollection(userId).add(budget.toMap());
      
      // Update the budget with the generated ID
      final updatedBudget = budget.copyWith(id: docRef.id);
      await docRef.update(updatedBudget.toMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  /// Get all active budgets for a user
  Stream<List<Budget>> watchUserBudgets(String userId) {
    return _budgetsCollection(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Budget.fromMap(data);
      }).toList();
    });
  }

  /// Get budgets for current period
  Stream<List<Budget>> watchCurrentPeriodBudgets(String userId) {
    final now = DateTime.now();
    return _budgetsCollection(userId)
        .where('isActive', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
        .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
        .orderBy('startDate')
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Budget.fromMap(data);
      }).toList();
    });
  }

  /// Get budgets by period type
  Stream<List<Budget>> watchBudgetsByPeriod(String userId, String period) {
    return _budgetsCollection(userId)
        .where('isActive', isEqualTo: true)
        .where('period', isEqualTo: period)
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Budget.fromMap(data);
      }).toList();
    });
  }

  /// Get a specific budget
  Future<Budget?> getBudget(String userId, String budgetId) async {
    try {
      final doc = await _budgetsCollection(userId).doc(budgetId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Budget.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  /// Update a budget
  Future<void> updateBudget(String userId, Budget budget) async {
    try {
      await _budgetsCollection(userId)
          .doc(budget.id)
          .update(budget.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  /// Update spent amount for a budget
  Future<void> updateSpentAmount(String userId, String budgetId, double newSpentAmount) async {
    try {
      await _budgetsCollection(userId).doc(budgetId).update({
        'spentAmount': newSpentAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update spent amount: $e');
    }
  }

  /// Delete a budget (soft delete)
  Future<void> deleteBudget(String userId, String budgetId) async {
    try {
      await _budgetsCollection(userId).doc(budgetId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  /// Calculate spent amount for a budget category in a specific period
  Future<double> calculateSpentAmount(
    String userId,
    String categoryId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _transactionsCollection(userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      double total = 0.0;
      for (var doc in query.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate spent amount: $e');
    }
  }

  /// Create monthly budgets based on income and default percentages
  Future<List<String>> createMonthlyBudgets(
    String userId,
    double monthlyIncome,
    DateTime startDate,
    {String accountId = 'default'}
  ) async {
    try {
      final endDate = DateTime(startDate.year, startDate.month + 1, 0);
      final List<String> budgetIds = [];

      for (final category in BudgetCategory.defaultCategories) {
        final allocatedAmount = monthlyIncome * (category.defaultPercentage / 100);
        
        final budget = Budget(
          id: '',
          categoryId: category.id,
          categoryName: category.name,
          allocatedAmount: allocatedAmount,
          spentAmount: 0.0,
          period: 'monthly',
          startDate: startDate,
          endDate: endDate,
          accountId: accountId,
          isActive: true,
          metadata: {
            'categoryDescription': category.description,
            'categoryIcon': category.icon,
            'categoryColor': category.color,
            'isEssential': category.isEssential,
            'defaultPercentage': category.defaultPercentage,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final budgetId = await createBudget(userId, budget);
        budgetIds.add(budgetId);
      }

      return budgetIds;
    } catch (e) {
      throw Exception('Failed to create monthly budgets: $e');
    }
  }

  /// Update all budget spent amounts for current period
  Future<void> updateAllSpentAmounts(String userId) async {
    try {
      final budgets = await watchCurrentPeriodBudgets(userId).first;
      
      for (final budget in budgets) {
        final spentAmount = await calculateSpentAmount(
          userId,
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );
        
        await updateSpentAmount(userId, budget.id, spentAmount);
      }
    } catch (e) {
      throw Exception('Failed to update spent amounts: $e');
    }
  }

  /// Get budget analytics for a user
  Stream<Map<String, dynamic>> watchBudgetAnalytics(String userId) {
    return watchCurrentPeriodBudgets(userId).map((budgets) {
      if (budgets.isEmpty) {
        return {
          'totalAllocated': 0.0,
          'totalSpent': 0.0,
          'totalRemaining': 0.0,
          'overallProgress': 0.0,
          'budgetCount': 0,
          'overBudgetCount': 0,
          'nearLimitCount': 0,
          'onTrackCount': 0,
          'averageProgress': 0.0,
          'projectedTotalSpending': 0.0,
        };
      }

      double totalAllocated = budgets.fold(0.0, (sum, budget) => sum + budget.allocatedAmount);
      double totalSpent = budgets.fold(0.0, (sum, budget) => sum + budget.spentAmount);
      double totalRemaining = budgets.fold(0.0, (sum, budget) => sum + budget.remainingAmount);
      double projectedTotalSpending = budgets.fold(0.0, (sum, budget) => sum + budget.projectedSpending);

      int overBudgetCount = budgets.where((budget) => budget.isOverspent).length;
      int nearLimitCount = budgets.where((budget) => budget.isNearLimit).length;
      int onTrackCount = budgets.where((budget) => budget.isOnTrack).length;

      double averageProgress = budgets.isEmpty 
          ? 0.0 
          : budgets.fold(0.0, (sum, budget) => sum + budget.spentPercentage) / budgets.length;

      return {
        'totalAllocated': totalAllocated,
        'totalSpent': totalSpent,
        'totalRemaining': totalRemaining,
        'overallProgress': totalAllocated > 0 ? totalSpent / totalAllocated : 0.0,
        'budgetCount': budgets.length,
        'overBudgetCount': overBudgetCount,
        'nearLimitCount': nearLimitCount,
        'onTrackCount': onTrackCount,
        'averageProgress': averageProgress,
        'projectedTotalSpending': projectedTotalSpending,
      };
    });
  }

  /// Get spending by category for a period
  Future<Map<String, double>> getSpendingByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _transactionsCollection(userId)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      Map<String, double> categorySpending = {};

      for (var doc in query.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] ?? 'uncategorized';
        final amount = (data['amount'] ?? 0.0).toDouble();
        
        categorySpending[categoryId] = (categorySpending[categoryId] ?? 0.0) + amount;
      }

      return categorySpending;
    } catch (e) {
      throw Exception('Failed to get spending by category: $e');
    }
  }

  /// Get budget recommendations based on spending patterns
  Future<List<Map<String, dynamic>>> getBudgetRecommendations(String userId) async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      await getSpendingByCategory(userId, lastMonth, endOfLastMonth);
      final currentBudgets = await watchCurrentPeriodBudgets(userId).first;

      List<Map<String, dynamic>> recommendations = [];

      // Analyze overspending categories
      for (final budget in currentBudgets) {
        if (budget.isOverspent) {
          recommendations.add({
            'type': 'overspending',
            'category': budget.categoryName,
            'message': 'Consider increasing budget for ${budget.categoryName} or reducing spending',
            'currentAllocation': budget.allocatedAmount,
            'suggestedAllocation': budget.spentAmount * 1.1,
            'priority': 'high',
          });
        }
      }

      // Analyze underutilized categories
      for (final budget in currentBudgets) {
        if (budget.spentPercentage < 0.5 && budget.allocatedAmount > 100) {
          recommendations.add({
            'type': 'underutilized',
            'category': budget.categoryName,
            'message': 'Consider reducing budget for ${budget.categoryName} and reallocating funds',
            'currentAllocation': budget.allocatedAmount,
            'suggestedAllocation': budget.spentAmount * 1.5,
            'priority': 'medium',
          });
        }
      }

      return recommendations;
    } catch (e) {
      throw Exception('Failed to get budget recommendations: $e');
    }
  }

  /// Clone budgets from previous period
  Future<List<String>> cloneBudgetsFromPreviousPeriod(
    String userId,
    DateTime newStartDate,
    String period,
  ) async {
    try {
      DateTime previousStartDate;

      switch (period) {
        case 'monthly':
          previousStartDate = DateTime(newStartDate.year, newStartDate.month - 1, 1);
          break;
        case 'yearly':
          previousStartDate = DateTime(newStartDate.year - 1, 1, 1);
          break;
        default:
          throw Exception('Unsupported period for cloning: $period');
      }

      final previousBudgets = await _budgetsCollection(userId)
          .where('isActive', isEqualTo: true)
          .where('period', isEqualTo: period)
          .where('startDate', isEqualTo: previousStartDate.toIso8601String())
          .get();

      final List<String> newBudgetIds = [];
      final newEndDate = period == 'monthly'
          ? DateTime(newStartDate.year, newStartDate.month + 1, 0)
          : DateTime(newStartDate.year, 12, 31);

      for (var doc in previousBudgets.docs) {
        final data = doc.data();
        final previousBudget = Budget.fromMap({...data, 'id': doc.id});

        final newBudget = previousBudget.copyWith(
          id: '',
          startDate: newStartDate,
          endDate: newEndDate,
          spentAmount: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final budgetId = await createBudget(userId, newBudget);
        newBudgetIds.add(budgetId);
      }

      return newBudgetIds;
    } catch (e) {
      throw Exception('Failed to clone budgets from previous period: $e');
    }
  }
}
