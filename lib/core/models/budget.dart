import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;
  final String period; // 'monthly', 'yearly', 'weekly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final String accountId;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.accountId,
    this.isActive = true,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => allocatedAmount > 0
      ? (spentAmount / allocatedAmount).clamp(0.0, 1.0)
      : 0.0;

  /// Calculate the remaining budget amount
  double get remainingAmount =>
      (allocatedAmount - spentAmount).clamp(0.0, double.infinity);

  /// Calculate the spent percentage
  double get spentPercentage => allocatedAmount > 0
      ? (spentAmount / allocatedAmount).clamp(0.0, 1.0)
      : 0.0;

  /// Check if budget is overspent
  bool get isOverspent => spentAmount > allocatedAmount;

  /// Check if budget is near limit (80% spent)
  bool get isNearLimit => spentPercentage >= 0.8 && !isOverspent;

  /// Check if budget is within safe range (<= 80% spent)
  bool get isOnTrack => spentPercentage <= 0.8;

  /// Days remaining in budget period
  int get daysRemaining {
    final days = endDate.difference(DateTime.now()).inDays;
    return days.clamp(
      0,
      999999,
    ); // Use a reasonable max value instead of infinity
  }

  /// Days total in budget period
  int get totalDays => endDate.difference(startDate).inDays;

  /// Daily spending rate (spent per day)
  double get dailySpendingRate {
    final daysPassed = totalDays - daysRemaining + 1;
    return daysPassed > 0 ? spentAmount / daysPassed : 0.0;
  }

  /// Projected spending for the period based on current rate
  double get projectedSpending => daysRemaining > 0
      ? spentAmount + (dailySpendingRate * daysRemaining)
      : spentAmount;

  /// Recommended daily spending to stay within budget
  double get recommendedDailySpending =>
      daysRemaining > 0 ? remainingAmount / daysRemaining : 0.0;

  /// Check if budget period is active
  bool get isPeriodActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }

  /// Get status description
  String get statusDescription {
    if (isOverspent) {
      return 'Over Budget';
    }
    if (isNearLimit) {
      return 'Near Limit';
    }
    return 'On Track';
  }

  /// Get spending trend
  SpendingTrend get spendingTrend {
    if (projectedSpending > allocatedAmount * 1.1) {
      return SpendingTrend.high;
    } else if (projectedSpending > allocatedAmount) {
      return SpendingTrend.moderate;
    } else {
      return SpendingTrend.low;
    }
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    // Helper function to parse date fields (handles both Timestamp and String)
    DateTime parseDate(dynamic dateField) {
      if (dateField is String) {
        return DateTime.parse(dateField);
      } else if (dateField is Timestamp) {
        return dateField.toDate();
      }
      return DateTime.now(); // Fallback
    }

    return Budget(
      id: map['id'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      allocatedAmount: map['allocatedAmount'].toDouble(),
      spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
      period: map['period'],
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      accountId: map['accountId'],
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'accountId': accountId,
      'isActive': isActive,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    double? allocatedAmount,
    double? spentAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Enum for spending trends
enum SpendingTrend { low, moderate, high }

/// Budget categories with default allocations (percentage-based)
class BudgetCategory {
  final String id;
  final String name;
  final String description;
  final double defaultPercentage;
  final String icon;
  final String color;
  final bool isEssential;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultPercentage,
    required this.icon,
    required this.color,
    this.isEssential = false,
  });

  static const List<BudgetCategory> defaultCategories = [
    // Essential categories (50% of income)
    BudgetCategory(
      id: 'housing',
      name: 'Housing',
      description: 'Rent, mortgage, utilities',
      defaultPercentage: 25.0,
      icon: 'home',
      color: 'blue',
      isEssential: true,
    ),
    BudgetCategory(
      id: 'food',
      name: 'Food & Groceries',
      description: 'Groceries, dining out',
      defaultPercentage: 15.0,
      icon: 'restaurant',
      color: 'green',
      isEssential: true,
    ),
    BudgetCategory(
      id: 'transportation',
      name: 'Transportation',
      description: 'Fuel, public transport, maintenance',
      defaultPercentage: 10.0,
      icon: 'directions_car',
      color: 'orange',
      isEssential: true,
    ),

    // Savings & Investments (20% of income)
    BudgetCategory(
      id: 'savings',
      name: 'Savings',
      description: 'Emergency fund, general savings',
      defaultPercentage: 10.0,
      icon: 'savings',
      color: 'purple',
    ),
    BudgetCategory(
      id: 'investments',
      name: 'Investments',
      description: 'Stocks, bonds, mutual funds',
      defaultPercentage: 10.0,
      icon: 'trending_up',
      color: 'teal',
    ),

    // Lifestyle (30% of income)
    BudgetCategory(
      id: 'entertainment',
      name: 'Entertainment',
      description: 'Movies, games, subscriptions',
      defaultPercentage: 8.0,
      icon: 'movie',
      color: 'pink',
    ),
    BudgetCategory(
      id: 'shopping',
      name: 'Shopping',
      description: 'Clothes, electronics, miscellaneous',
      defaultPercentage: 10.0,
      icon: 'shopping_bag',
      color: 'red',
    ),
    BudgetCategory(
      id: 'health',
      name: 'Health & Fitness',
      description: 'Medical expenses, gym, supplements',
      defaultPercentage: 5.0,
      icon: 'local_hospital',
      color: 'cyan',
    ),
    BudgetCategory(
      id: 'personal',
      name: 'Personal Care',
      description: 'Grooming, beauty, personal items',
      defaultPercentage: 3.0,
      icon: 'face',
      color: 'amber',
    ),
    BudgetCategory(
      id: 'education',
      name: 'Education',
      description: 'Courses, books, learning',
      defaultPercentage: 2.0,
      icon: 'school',
      color: 'indigo',
    ),
    BudgetCategory(
      id: 'miscellaneous',
      name: 'Miscellaneous',
      description: 'Other expenses',
      defaultPercentage: 2.0,
      icon: 'more_horiz',
      color: 'grey',
    ),
  ];
}
