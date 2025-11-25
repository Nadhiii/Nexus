import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtType {
  creditCard,
  personalLoan,
  homeLoan,
  carLoan,
  educationLoan,
  businessLoan,
  goldLoan,
  owedByMe,
  owedToMe,
  other,
}

class Debt {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double originalAmount;
  final double currentBalance;
  final double? interestRate;
  final double? monthlyEMI;
  final String? lenderName;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.originalAmount,
    required this.currentBalance,
    this.interestRate,
    this.monthlyEMI,
    this.lenderName,
    this.notes,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      type: DebtType.values[data['type'] as int],
      originalAmount: (data['originalAmount'] as num).toDouble(),
      currentBalance: (data['currentBalance'] as num).toDouble(),
      interestRate: (data['interestRate'] as num?)?.toDouble(),
      monthlyEMI: (data['monthlyEMI'] as num?)?.toDouble(),
      lenderName: data['lenderName'] as String?,
      notes: data['notes'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.index,
      'originalAmount': originalAmount,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'monthlyEMI': monthlyEMI,
      'lenderName': lenderName,
      'notes': notes,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
