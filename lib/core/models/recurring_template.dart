import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'transaction.dart';

/// Frequency for recurring transactions
enum RecurringFrequency { daily, weekly, biweekly, monthly, quarterly, yearly }

/// Template for recurring transactions
class RecurringTemplate {
  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final double amount;
  final String? categoryId;
  final String? accountId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecuted;
  final DateTime nextDueDate;
  final bool isActive;
  final String? notes;
  final bool autoCreate; // Auto-create transaction on due date
  final int? dayOfMonth; // For monthly: which day (1-31)
  final int? dayOfWeek; // For weekly: which day (1-7, Monday=1)

  RecurringTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.amount,
    this.categoryId,
    this.accountId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastExecuted,
    required this.nextDueDate,
    this.isActive = true,
    this.notes,
    this.autoCreate = false,
    this.dayOfMonth,
    this.dayOfWeek,
  });

  /// Check if due today
  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.year == now.year &&
        nextDueDate.month == now.month &&
        nextDueDate.day == now.day;
  }

  /// Check if overdue
  bool get isOverdue =>
      isActive && nextDueDate.isBefore(DateTime.now()) && !isDueToday;

  /// Days until next due
  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  /// Calculate next due date based on frequency
  DateTime calculateNextDueDate() {
    DateTime next = nextDueDate;
    final now = DateTime.now();

    while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      switch (frequency) {
        case RecurringFrequency.daily:
          next = next.add(const Duration(days: 1));
          break;
        case RecurringFrequency.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case RecurringFrequency.biweekly:
          next = next.add(const Duration(days: 14));
          break;
        case RecurringFrequency.monthly:
          next = DateTime(next.year, next.month + 1, dayOfMonth ?? next.day);
          break;
        case RecurringFrequency.quarterly:
          next = DateTime(next.year, next.month + 3, next.day);
          break;
        case RecurringFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  /// Get frequency display name
  String get frequencyDisplayName {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Every 2 weeks';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  /// Create a transaction from this template
  Transaction createTransaction() {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      amount: amount,
      description: name,
      categoryId: categoryId,
      accountId: accountId ?? '',
      date: DateTime.now(),
      metadata: {'fromTemplate': true, 'templateId': id, 'templateName': name},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory RecurringTemplate.fromMap(Map<String, dynamic> map, String id) {
    return RecurringTemplate(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      frequency: RecurringFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null
          ? (map['endDate'] is Timestamp
                ? (map['endDate'] as Timestamp).toDate()
                : DateTime.parse(map['endDate']))
          : null,
      lastExecuted: map['lastExecuted'] != null
          ? (map['lastExecuted'] is Timestamp
                ? (map['lastExecuted'] as Timestamp).toDate()
                : DateTime.parse(map['lastExecuted']))
          : null,
      nextDueDate: map['nextDueDate'] is Timestamp
          ? (map['nextDueDate'] as Timestamp).toDate()
          : DateTime.parse(map['nextDueDate']),
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
      autoCreate: map['autoCreate'] ?? false,
      dayOfMonth: map['dayOfMonth'],
      dayOfWeek: map['dayOfWeek'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'lastExecuted': lastExecuted != null
          ? Timestamp.fromDate(lastExecuted!)
          : null,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
      'notes': notes,
      'autoCreate': autoCreate,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
    };
  }

  RecurringTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecuted,
    DateTime? nextDueDate,
    bool? isActive,
    String? notes,
    bool? autoCreate,
    int? dayOfMonth,
    int? dayOfWeek,
  }) {
    return RecurringTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      autoCreate: autoCreate ?? this.autoCreate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }
}

/// Common transaction templates
class TransactionTemplates {
  static List<Map<String, dynamic>> get commonTemplates => [
    {
      'name': 'Rent',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.monthly,
      'category': 'housing',
      'dayOfMonth': 1,
    },
    {
      'name': 'Electricity Bill',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.monthly,
      'category': 'utilities',
    },
    {
      'name': 'Mobile Recharge',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.monthly,
      'category': 'utilities',
    },
    {
      'name': 'Salary',
      'type': TransactionType.income,
      'frequency': RecurringFrequency.monthly,
      'category': 'salary',
      'dayOfMonth': 1,
    },
    {
      'name': 'Groceries',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.weekly,
      'category': 'food',
    },
    {
      'name': 'Fuel',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.weekly,
      'category': 'transportation',
    },
    {
      'name': 'Internet Bill',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.monthly,
      'category': 'utilities',
    },
    {
      'name': 'Gym Membership',
      'type': TransactionType.expense,
      'frequency': RecurringFrequency.monthly,
      'category': 'health',
    },
  ];
}
