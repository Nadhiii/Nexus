import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionRelationshipType {
  transferPair,
  refund,
  recurringSeries,
  relatedPayment,
  duplicate,
}

class TransactionRelationship {
  final String id;
  final String userId;
  final TransactionRelationshipType type;
  final List<String> transactionIds;
  final String reason;
  final double confidence;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionRelationship({
    required this.id,
    required this.userId,
    required this.type,
    required this.transactionIds,
    required this.reason,
    required this.confidence,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionRelationship.fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return TransactionRelationship(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: TransactionRelationshipType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => TransactionRelationshipType.relatedPayment,
      ),
      transactionIds: List<String>.from(data['transactionIds'] as List? ?? const []),
      reason: data['reason'] as String? ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      active: data['active'] as bool? ?? true,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'transactionIds': transactionIds,
        'reason': reason,
        'confidence': confidence,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
