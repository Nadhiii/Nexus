
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum DebtPayoffStrategy {
  snowball, // Pay minimum on all, extra on smallest balance
  avalanche, // Pay minimum on all, extra on highest interest
  custom, // User-defined priority
}

enum DebtType {
  creditCard,
  personalLoan,
  homeLoan,
  carLoan,
  educationLoan,
  businessLoan,
  goldLoan,
  other,
  owedToMe,
  owedByMe,
}

class Debt {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double originalAmount;
  final double currentBalance;

  final String? person;
  final DateTime? dueDate;

  final String? lenderName;
  final double? monthlyEMI;
  final double? interestRate;
  final int? totalTenureMonths;
  final int? monthsPaid;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? accountNumber;
  final Color? color;
  final IconData? icon;
  final String? notes;
  final int? priority;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalPaid;
  final double totalInterestPaid;
  final DateTime? lastPaymentDate;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.originalAmount,
    required this.currentBalance,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.person,
    this.isPaid = false,
    this.lenderName,
    this.monthlyEMI,
    this.interestRate,
    this.totalTenureMonths,
    this.monthsPaid,
    this.startDate,
    this.endDate,
    this.accountNumber,
    this.color,
    this.icon,
    this.notes,
    this.priority,
    this.totalPaid = 0.0,
    this.totalInterestPaid = 0.0,
    this.lastPaymentDate,
  });

    String get typeDisplayName {
    switch (type) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.owedByMe:
        return 'Owed by Me';
      case DebtType.owedToMe:
        return 'Owed to Me';
      case DebtType.other:
        return 'Other';
    }
  }

    double get monthlyInterestPayment {
    if (interestRate == null || interestRate == 0) return 0;
    return (currentBalance * (interestRate! / 100)) / 12;
  }

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] != null ? DebtType.values[data['type']] : DebtType.other,
      originalAmount: (data['originalAmount'] ?? 0.0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      person: data['person'],
      isPaid: data['isPaid'] ?? false,
      lenderName: data['lenderName'],
      monthlyEMI: (data['monthlyEMI'] ?? 0.0).toDouble(),
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      totalTenureMonths: data['totalTenureMonths'],
      monthsPaid: data['monthsPaid'],
      startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      accountNumber: data['accountNumber'],
      color: data['color'] != null ? Color(data['color']) : null,
      icon: data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : null,
      notes: data['notes'],
      priority: data['priority'],
      totalPaid: (data['totalPaid'] ?? 0.0).toDouble(),
      totalInterestPaid: (data['totalInterestPaid'] ?? 0.0).toDouble(),
      lastPaymentDate: data['lastPaymentDate'] != null ? (data['lastPaymentDate'] as Timestamp).toDate() : null,
    );
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
     return Debt(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      type: DebtType.values[json['type']],
      originalAmount: json['originalAmount'],
      currentBalance: json['currentBalance'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      person: json['person'],
      isPaid: json['isPaid'],
      lenderName: json['lenderName'],
      monthlyEMI: json['monthlyEMI'],
      interestRate: json['interestRate'],
      totalTenureMonths: json['totalTenureMonths'],
      monthsPaid: json['monthsPaid'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      accountNumber: json['accountNumber'],
      color: json['color'] != null ? Color(json['color']) : null,
      icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
      notes: json['notes'],
      priority: json['priority'],
      totalPaid: json['totalPaid'],
      totalInterestPaid: json['totalInterestPaid'],
      lastPaymentDate: json['lastPaymentDate'] != null ? DateTime.parse(json['lastPaymentDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'type': type.index,
        'originalAmount': originalAmount,
        'currentBalance': currentBalance,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'person': person,
        'isPaid': isPaid,
        'lenderName': lenderName,
        'monthlyEMI': monthlyEMI,
        'interestRate': interestRate,
        'totalTenureMonths': totalTenureMonths,
        'monthsPaid': monthsPaid,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'accountNumber': accountNumber,
        'color': color?.value,
        'icon': icon?.codePoint,
        'notes': notes,
        'priority': priority,
        'totalPaid': totalPaid,
        'totalInterestPaid': totalInterestPaid,
        'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      };
      
  Debt copyWith({
    String? id,
    String? userId,
    String? name,
    DebtType? type,
    double? originalAmount,
    double? currentBalance,
    DateTime? dueDate,
    bool? isPaid,
    String? lenderName,
    double? monthlyEMI,
    double? interestRate,
    int? totalTenureMonths,
    int? monthsPaid,
    DateTime? startDate,
    DateTime? endDate,
    String? accountNumber,
    Color? color,
    IconData? icon,
    String? notes,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalPaid,
    double? totalInterestPaid,
    DateTime? lastPaymentDate,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      lenderName: lenderName ?? this.lenderName,
      monthlyEMI: monthlyEMI ?? this.monthlyEMI,
      interestRate: interestRate ?? this.interestRate,
      totalTenureMonths: totalTenureMonths ?? this.totalTenureMonths,
      monthsPaid: monthsPaid ?? this.monthsPaid,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountNumber: accountNumber ?? this.accountNumber,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPaid: totalPaid ?? this.totalPaid,
      totalInterestPaid: totalInterestPaid ?? this.totalInterestPaid,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }
}
