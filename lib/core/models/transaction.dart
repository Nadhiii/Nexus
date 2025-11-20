import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String? description;
  final String? categoryId;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.metadata,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
      categoryId: data['categoryId'],
      accountId: data['accountId'],
      toAccountId: data['toAccountId'],
      date: (data['date'] as Timestamp).toDate(),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Transaction.fromMap(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
      categoryId: data['categoryId'],
      accountId: data['accountId'] ?? '',
      toAccountId: data['toAccountId'],
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date']),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'date': Timestamp.fromDate(date),
      'metadata': metadata,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      type: TransactionType.values[json['type']],
      amount: json['amount'],
      description: json['description'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      date: DateTime.parse(json['date']),
      metadata: json['metadata'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.index,
    'amount': amount,
    'description': description,
    'categoryId': categoryId,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'date': date.toIso8601String(),
    'metadata': metadata,
    'attachments': attachments,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
