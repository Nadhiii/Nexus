class Subscription {
  final String id;
  final String name;
  final String? description;
  final double amount;
  final String frequency; // 'monthly', 'yearly', 'weekly', 'daily'
  final DateTime nextDueDate;
  final String accountId;
  final String? categoryId;
  final bool isActive;
  final Map<String, dynamic>? metadata; // Store additional info
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.accountId,
    this.categoryId,
    required this.isActive,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate the next due date based on frequency
  DateTime calculateNextDueDate() {
    switch (frequency) {
      case 'daily':
        return nextDueDate.add(const Duration(days: 1));
      case 'weekly':
        return nextDueDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case 'yearly':
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      default:
        return nextDueDate.add(const Duration(days: 30)); // Default to monthly
    }
  }

  /// Check if subscription is due today
  bool get isDueToday {
    final today = DateTime.now();
    return nextDueDate.year == today.year &&
           nextDueDate.month == today.month &&
           nextDueDate.day == today.day;
  }

  /// Check if subscription is overdue
  bool get isOverdue => DateTime.now().isAfter(nextDueDate) && isActive;

  /// Days until next payment
  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      frequency: map['frequency'],
      nextDueDate: DateTime.parse(map['nextDueDate']),
      accountId: map['accountId'],
      categoryId: map['categoryId'],
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'frequency': frequency,
      'nextDueDate': nextDueDate.toIso8601String(),
      'accountId': accountId,
      'categoryId': categoryId,
      'isActive': isActive,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    String? frequency,
    DateTime? nextDueDate,
    String? accountId,
    String? categoryId,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
