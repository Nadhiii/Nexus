import 'package:flutter/material.dart';

enum AccountType { savings, salary, checking, investment, cash, other }

class Account {
  final String id;
  final String userId; // User ID for filtering
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
  final String? accountNumber; // Last 4 digits for display
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

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'] ?? '', // Handle legacy data without userId
      name: map['name'],
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.other,
      ),
      bankName: map['bankName'],
      balance: map['balance']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '₹',
      color: Color(map['color'] ?? Colors.blue.value),
      icon: IconData(
        map['icon'] ?? Icons.account_balance.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      accountNumber: map['accountNumber'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'bankName': bankName,
      'balance': balance,
      'currency': currency,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'accountNumber': accountNumber,
      'notes': notes,
    };
  }

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

  // Helper methods
  bool get isAsset =>
      true; // All our account types are assets since debts are handled separately
  bool get isLiability => false; // No liability accounts in this enum

  String get typeDisplayName {
    // If user has set a custom name, prioritize that over type
    if (name.isNotEmpty && type != AccountType.other) {
      return name;
    }

    switch (type) {
      case AccountType.savings:
        return name.isNotEmpty ? name : 'Savings Account';
      case AccountType.salary:
        return name.isNotEmpty ? name : 'Salary Account';
      case AccountType.checking:
        return name.isNotEmpty ? name : 'Checking Account';
      case AccountType.investment:
        return name.isNotEmpty ? name : 'Investment Account';
      case AccountType.cash:
        return name.isNotEmpty ? name : 'Cash';
      case AccountType.other:
        return name.isNotEmpty ? name : 'Custom Account';
    }
  }

  String get formattedBalance {
    return '$currency${balance.abs().toStringAsFixed(2)}';
  }

  String get displayName {
    if (bankName != null && bankName!.isNotEmpty) {
      return '$name - $bankName';
    }
    return name;
  }
}
