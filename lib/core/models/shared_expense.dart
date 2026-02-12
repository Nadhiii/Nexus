import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a shared expense among family members
class SharedExpense {
  final String id;
  final String userId; // Who created this expense
  final String description;
  final double totalAmount;
  final DateTime date;
  final String paidBy; // UserId who paid
  final String paidByName; // Display name
  final List<ExpenseSplit> splits; // Who owes what
  final bool isSettled;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedExpense({
    required this.id,
    required this.userId,
    required this.description,
    required this.totalAmount,
    required this.date,
    required this.paidBy,
    required this.paidByName,
    required this.splits,
    this.isSettled = false,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate how much a specific person owes
  double getAmountOwedBy(String personId) {
    final split = splits.firstWhere(
      (s) => s.personId == personId,
      orElse: () => ExpenseSplit(personId: '', personName: '', amount: 0),
    );
    return split.amount;
  }

  /// Get total amount that needs to be collected (excluding payer)
  double get totalOwed {
    return splits
        .where((s) => s.personId != paidBy)
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  /// Get total settled amount
  double get settledAmount {
    return splits
        .where((s) => s.isSettled && s.personId != paidBy)
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  /// Get remaining amount to be collected
  double get remainingAmount => totalOwed - settledAmount;

  factory SharedExpense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SharedExpense(
      id: doc.id,
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date'] as String),
      paidBy: data['paidBy'] ?? '',
      paidByName: data['paidByName'] ?? '',
      splits:
          (data['splits'] as List<dynamic>?)
              ?.map((s) => ExpenseSplit.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      isSettled: data['isSettled'] ?? false,
      category: data['category'],
      notes: data['notes'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'paidByName': paidByName,
      'splits': splits.map((s) => s.toMap()).toList(),
      'isSettled': isSettled,
      'category': category,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SharedExpense copyWith({
    String? id,
    String? userId,
    String? description,
    double? totalAmount,
    DateTime? date,
    String? paidBy,
    String? paidByName,
    List<ExpenseSplit>? splits,
    bool? isSettled,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      splits: splits ?? this.splits,
      isSettled: isSettled ?? this.isSettled,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents how an expense is split among participants
class ExpenseSplit {
  final String personId;
  final String personName;
  final double amount;
  final bool isSettled;
  final DateTime? settledDate;

  ExpenseSplit({
    required this.personId,
    required this.personName,
    required this.amount,
    this.isSettled = false,
    this.settledDate,
  });

  factory ExpenseSplit.fromMap(Map<String, dynamic> data) {
    return ExpenseSplit(
      personId: data['personId'] ?? '',
      personName: data['personName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      isSettled: data['isSettled'] ?? false,
      settledDate: data['settledDate'] != null
          ? (data['settledDate'] is Timestamp
                ? (data['settledDate'] as Timestamp).toDate()
                : DateTime.parse(data['settledDate'] as String))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'personName': personName,
      'amount': amount,
      'isSettled': isSettled,
      'settledDate': settledDate != null
          ? Timestamp.fromDate(settledDate!)
          : null,
    };
  }

  ExpenseSplit copyWith({
    String? personId,
    String? personName,
    double? amount,
    bool? isSettled,
    DateTime? settledDate,
  }) {
    return ExpenseSplit(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledDate: settledDate ?? this.settledDate,
    );
  }
}

/// Represents a family member for shared expenses
class FamilyMember {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final bool isActive;

  FamilyMember({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.isActive = true,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      avatarUrl: data['avatarUrl'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }
}

/// Summary of settlements between two people
class SettlementSummary {
  final String person1Id;
  final String person1Name;
  final String person2Id;
  final String person2Name;
  final double netAmount; // Positive = person2 owes person1

  SettlementSummary({
    required this.person1Id,
    required this.person1Name,
    required this.person2Id,
    required this.person2Name,
    required this.netAmount,
  });
}
