import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a debt/loan between family members
/// Can be either "I owe them" or "They owe me"
class FamilyDebt {
  final String id;
  final String creatorId; // Who created this record
  final String creditorId; // Who is owed money
  final String creditorName;
  final String debtorId; // Who owes money
  final String debtorName;
  final double originalAmount;
  final double currentAmount; // Remaining balance
  final String? description;
  final String? notes;
  final DateTime createdAt;
  final DateTime? dueDate;
  final List<FamilyDebtPayment> payments;
  final bool isSettled;

  FamilyDebt({
    required this.id,
    required this.creatorId,
    required this.creditorId,
    required this.creditorName,
    required this.debtorId,
    required this.debtorName,
    required this.originalAmount,
    required this.currentAmount,
    this.description,
    this.notes,
    required this.createdAt,
    this.dueDate,
    this.payments = const [],
    this.isSettled = false,
  });

  /// Calculate total paid so far
  double get totalPaid => originalAmount - currentAmount;

  /// Calculate progress percentage
  double get progressPercent =>
      originalAmount > 0 ? (totalPaid / originalAmount) * 100 : 0;

  /// Check if overdue
  bool get isOverdue =>
      !isSettled && dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Days until due (negative if overdue)
  int? get daysUntilDue {
    if (dueDate == null) {
      return null;
    }
    return dueDate!.difference(DateTime.now()).inDays;
  }

  factory FamilyDebt.fromMap(Map<String, dynamic> map, String id) {
    return FamilyDebt(
      id: id,
      creatorId: map['creatorId'] ?? '',
      creditorId: map['creditorId'] ?? '',
      creditorName: map['creditorName'] ?? '',
      debtorId: map['debtorId'] ?? '',
      debtorName: map['debtorName'] ?? '',
      originalAmount: (map['originalAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      description: map['description'],
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] is Timestamp
                ? (map['dueDate'] as Timestamp).toDate()
                : DateTime.parse(map['dueDate']))
          : null,
      payments:
          (map['payments'] as List<dynamic>?)
              ?.map((p) => FamilyDebtPayment.fromMap(p))
              .toList() ??
          [],
      isSettled: map['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creditorId': creditorId,
      'creditorName': creditorName,
      'debtorId': debtorId,
      'debtorName': debtorName,
      'originalAmount': originalAmount,
      'currentAmount': currentAmount,
      'description': description,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'payments': payments.map((p) => p.toMap()).toList(),
      'isSettled': isSettled,
    };
  }

  FamilyDebt copyWith({
    String? id,
    String? creatorId,
    String? creditorId,
    String? creditorName,
    String? debtorId,
    String? debtorName,
    double? originalAmount,
    double? currentAmount,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? dueDate,
    List<FamilyDebtPayment>? payments,
    bool? isSettled,
  }) {
    return FamilyDebt(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creditorId: creditorId ?? this.creditorId,
      creditorName: creditorName ?? this.creditorName,
      debtorId: debtorId ?? this.debtorId,
      debtorName: debtorName ?? this.debtorName,
      originalAmount: originalAmount ?? this.originalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      payments: payments ?? this.payments,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}

/// Individual payment record for a family debt
class FamilyDebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  FamilyDebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory FamilyDebtPayment.fromMap(Map<String, dynamic> map) {
    return FamilyDebtPayment(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }
}

/// Summary of what one person owes/is owed by another
class FamilyDebtSummary {
  final String personId;
  final String personName;
  final double theyOweMe; // Amount they owe the current user
  final double iOweThem; // Amount current user owes them
  final int activeDebts;

  FamilyDebtSummary({
    required this.personId,
    required this.personName,
    required this.theyOweMe,
    required this.iOweThem,
    required this.activeDebts,
  });

  /// Net balance (positive = they owe me, negative = I owe them)
  double get netBalance => theyOweMe - iOweThem;

  /// Who owes whom
  String get summary {
    if (netBalance > 0) {
      return '$personName owes you ₹${netBalance.abs().toStringAsFixed(0)}';
    } else if (netBalance < 0) {
      return 'You owe $personName ₹${netBalance.abs().toStringAsFixed(0)}';
    }
    return 'Settled with $personName';
  }
}
