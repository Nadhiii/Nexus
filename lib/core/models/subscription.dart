import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String frequency;
  final DateTime nextDueDate;
  final String categoryId;
  final String accountId;
  final String? description;
  final String? notes;
  final bool isActive;
  final String color;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.categoryId,
    required this.accountId,
    this.description,
    this.notes,
    this.isActive = true,
    required this.color,
    required this.createdAt,
  });

  bool get isOverdue => isActive && nextDueDate.isBefore(DateTime.now());

  DateTime calculateNextDueDate() {
    final now = DateTime.now();
    DateTime nextDate = nextDueDate;

    while (nextDate.isBefore(now)) {
      switch (frequency.toLowerCase()) {
        case 'daily':
          nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 1);
          break;
        case 'weekly':
          nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 7);
          break;
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case 'yearly':
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
        default:
          return nextDate;
      }
    }
    return nextDate;
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      amount: (data['amount'] ?? 0).toDouble(),
      frequency: data['frequency'],
      nextDueDate: data['nextDueDate'] is Timestamp
          ? (data['nextDueDate'] as Timestamp).toDate()
          : DateTime.parse(data['nextDueDate']),
      categoryId: data['categoryId'],
      accountId: data['accountId'] ?? 'default',
      description: data['description'],
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      color: data['color'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
    );
  }

  factory Subscription.fromMap(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      frequency: data['frequency'] ?? 'monthly',
      nextDueDate: data['nextDueDate'] is Timestamp
          ? (data['nextDueDate'] as Timestamp).toDate()
          : DateTime.parse(data['nextDueDate']),
      categoryId: data['categoryId'] ?? '',
      accountId: data['accountId'] ?? 'default',
      description: data['description'],
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      color: data['color'] ?? 'blue',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'categoryId': categoryId,
      'accountId': accountId,
      'description': description,
      'notes': notes,
      'isActive': isActive,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      amount: json['amount'],
      frequency: json['frequency'],
      nextDueDate: DateTime.parse(json['nextDueDate']),
      categoryId: json['categoryId'],
      accountId: json['accountId'] ?? 'default',
      description: json['description'],
      notes: json['notes'],
      isActive: json['isActive'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'amount': amount,
    'frequency': frequency,
    'nextDueDate': nextDueDate.toIso8601String(),
    'categoryId': categoryId,
    'accountId': accountId,
    'description': description,
    'notes': notes,
    'isActive': isActive,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
  };

  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? frequency,
    DateTime? nextDueDate,
    String? categoryId,
    String? accountId,
    String? description,
    String? notes,
    bool? isActive,
    String? color,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
