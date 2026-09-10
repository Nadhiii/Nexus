import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer, adjustment }

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

  static DateTime _readDate(Object? value, String field) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException('Invalid transaction $field');
  }

  static double _readAmount(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory Transaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data();
    if (raw == null) throw FormatException('Transaction ${doc.id} has no data');
    final data = Map<String, dynamic>.from(raw);
    return Transaction(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      type: TransactionType.values.firstWhere(
          (e) => e.name == data['type']?.toString(),
        orElse: () => TransactionType.expense,
      ),
      amount: _readAmount(data['amount']),
      description: data['description']?.toString(),
      categoryId: data['categoryId']?.toString(),
      accountId: data['accountId']?.toString() ?? '',
      toAccountId: data['toAccountId']?.toString(),
      date: _readDate(data['date'], 'date'),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
      attachments: data['attachments'] != null
          ? (data['attachments'] as List)
                .map((item) => item.toString())
                .toList()
          : null,
      createdAt: _readDate(data['createdAt'], 'createdAt'),
      updatedAt: _readDate(data['updatedAt'], 'updatedAt'),
    );
  }

  factory Transaction.fromMap(Map<String, dynamic> data) {
    return Transaction(
      id: data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      type: TransactionType.values.firstWhere(
          (e) => e.name == data['type']?.toString(),
        orElse: () => TransactionType.expense,
      ),
      amount: _readAmount(data['amount']),
      description: data['description']?.toString(),
      categoryId: data['categoryId']?.toString(),
      accountId: data['accountId']?.toString() ?? '',
      toAccountId: data['toAccountId']?.toString(),
      date: _readDate(data['date'], 'date'),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
      attachments: data['attachments'] != null
          ? (data['attachments'] as List)
                .map((item) => item.toString())
                .toList()
          : null,
      createdAt: _readDate(data['createdAt'], 'createdAt'),
      updatedAt: _readDate(data['updatedAt'], 'updatedAt'),
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
    final rawType = json['type'];
    final type = rawType is int
        ? TransactionType.values[rawType.clamp(
            0,
            TransactionType.values.length - 1,
          )]
        : TransactionType.values.firstWhere(
            (value) => value.name == rawType?.toString(),
            orElse: () => TransactionType.expense,
          );
    return Transaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: type,
      amount: _readAmount(json['amount']),
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString(),
      accountId: json['accountId']?.toString() ?? '',
      toAccountId: json['toAccountId']?.toString(),
      date: _readDate(json['date'], 'date'),
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata'] as Map),
      attachments: (json['attachments'] as List?)
          ?.map((item) => item.toString())
          .toList(),
      createdAt: _readDate(json['createdAt'], 'createdAt'),
      updatedAt: _readDate(json['updatedAt'], 'updatedAt'),
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
