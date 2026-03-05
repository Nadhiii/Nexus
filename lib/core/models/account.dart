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
  final int iconCodePoint;
  final String iconFontFamily;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? accountNumber;
  final String? notes;

  // New Card Fields
  final String? cardNumber;
  final String? cardExpiry;
  // Note: CVV is stored locally in SecureCardService, NOT in Firestore
  final String? cardHolderName;

  // Account Details for Flip Card
  final String? ifscCode;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.bankName,
    required this.balance,
    this.currency = '₹',
    required this.color,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.accountNumber,
    this.notes,
    this.cardNumber,
    this.cardExpiry,
    this.cardHolderName,
    this.ifscCode,
  });

  // Map known icon code points to constant IconData instances
  static final Map<int, IconData> _iconLookup = {
    Icons.account_balance.codePoint: Icons.account_balance,
    Icons.savings.codePoint: Icons.savings,
    Icons.credit_card.codePoint: Icons.credit_card,
    Icons.wallet.codePoint: Icons.wallet,
    Icons.pie_chart.codePoint: Icons.pie_chart,
    Icons.attach_money.codePoint: Icons.attach_money,
    Icons.diamond.codePoint: Icons.diamond,
    Icons.lock.codePoint: Icons.lock,
  };

  IconData get icon => _iconLookup[iconCodePoint] ?? Icons.account_balance;

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
      color: Color(data['color'] ?? Colors.blue.toARGB32()),
      iconCodePoint: data['icon'] ?? Icons.account_balance.codePoint,
      iconFontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      accountNumber: data['accountNumber'],
      notes: data['notes'],
      cardNumber: data['cardNumber'],
      cardExpiry: data['cardExpiry'],
      cardHolderName: data['cardHolderName'],
      ifscCode: data['ifscCode'],
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
      color: Color(data['color'] ?? Colors.blue.toARGB32()),
      iconCodePoint: data['icon'] ?? Icons.account_balance.codePoint,
      iconFontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      accountNumber: data['accountNumber'],
      notes: data['notes'],
      cardNumber: data['cardNumber'],
      cardExpiry: data['cardExpiry'],
      cardHolderName: data['cardHolderName'],
      ifscCode: data['ifscCode'],
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
      'color': color.toARGB32(),
      'icon': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'accountNumber': accountNumber,
      'notes': notes,
      'cardNumber': cardNumber,
      'cardExpiry': cardExpiry,
      'cardHolderName': cardHolderName,
      'ifscCode': ifscCode,
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
      iconCodePoint: json['icon'],
      iconFontFamily: json['iconFontFamily'] ?? 'MaterialIcons',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'],
      accountNumber: json['accountNumber'],
      notes: json['notes'],
      cardNumber: json['cardNumber'],
      cardExpiry: json['cardExpiry'],
      cardHolderName: json['cardHolderName'],
      ifscCode: json['ifscCode'],
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
    'color': color.toARGB32(),
    'icon': icon.codePoint,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
    'accountNumber': accountNumber,
    'notes': notes,
    'cardNumber': cardNumber,
    'cardExpiry': cardExpiry,
    'cardHolderName': cardHolderName,
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
    int? iconCodePoint,
    String? iconFontFamily,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? accountNumber,
    String? notes,
    String? cardNumber,
    String? cardExpiry,
    String? cardHolderName,
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
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      accountNumber: accountNumber ?? this.accountNumber,
      notes: notes ?? this.notes,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardHolderName: cardHolderName ?? this.cardHolderName,
    );
  }
}
