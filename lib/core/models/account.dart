import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AccountType { savings, salary, checking, investment, cash, other }

class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final String? bankName;
  final double balance;
  final String currency;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? accountNumber;
  final String? notes;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.bankName,
    required this.balance,
    this.currency = '₹',
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.accountNumber,
    this.notes,
  });

  String get typeDisplayName {
    switch (type) {
      case AccountType.savings:
        return 'Savings';
      case AccountType.salary:
        return 'Salary';
      case AccountType.checking:
        return 'Checking';
      case AccountType.investment:
        return 'Investment';
      case AccountType.cash:
        return 'Cash';
      case AccountType.other:
        return 'Other';
    }
  }

  factory Account.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'],
      type: AccountType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AccountType.other,
      ),
      bankName: data['bankName'],
      balance: (data['balance'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₹',
      color: Color(data['color'] ?? Colors.blue.value),
      icon: IconData(
        data['icon'] ?? Icons.account_balance.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      accountNumber: data['accountNumber'],
      notes: data['notes'],
    );
  }

  factory Account.fromMap(Map<String, dynamic> data) {
    return Account(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AccountType.other,
      ),
      bankName: data['bankName'],
      balance: (data['balance'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₹',
      color: Color(data['color'] ?? Colors.blue.value),
      icon: IconData(
        data['icon'] ?? Icons.account_balance.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      accountNumber: data['accountNumber'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'bankName': bankName,
      'balance': balance,
      'currency': currency,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'accountNumber': accountNumber,
      'notes': notes,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      type: AccountType.values[json['type']],
      bankName: json['bankName'],
      balance: json['balance'],
      currency: json['currency'],
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'],
      accountNumber: json['accountNumber'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type.index,
    'bankName': bankName,
    'balance': balance,
    'currency': currency,
    'color': color.value,
    'icon': icon.codePoint,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
    'accountNumber': accountNumber,
    'notes': notes,
  };

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? bankName,
    double? balance,
    String? currency,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? accountNumber,
    String? notes,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      accountNumber: accountNumber ?? this.accountNumber,
      notes: notes ?? this.notes,
    );
  }
}
