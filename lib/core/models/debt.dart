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
  custom, // User-defined custom type
  other,
}

enum PaymentStatus { pending, paid, overdue, partiallyPaid }

class Debt {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double originalAmount;
  final double currentBalance;
  final double? interestRate;
  final double? monthlyEMI;
  final int? totalMonths; // Total tenure in months
  final int? paidMonths; // Number of months paid
  final double? totalInterest; // Total interest to be paid over loan tenure
  final double? interestPaid; // Interest already paid
  final double? principalPaid; // Principal already paid
  final DateTime? startDate; // Loan start date
  final DateTime? nextPaymentDate; // Next EMI due date
  final int? paymentDay; // Day of month when EMI is due (1-31)
  final String? lenderName;
  final String? accountNumber; // Loan account number
  final String? linkedAccountId; // Link to a bank account in the app
  final String? customTypeName; // Custom type name when type is 'custom'
  final String? notes;
  final DateTime? dueDate; // Final loan end date
  final bool isAutoDebit; // Whether EMI is auto-debited
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
    this.totalMonths,
    this.paidMonths,
    this.totalInterest,
    this.interestPaid,
    this.principalPaid,
    this.startDate,
    this.nextPaymentDate,
    this.paymentDay,
    this.lenderName,
    this.accountNumber,
    this.linkedAccountId,
    this.customTypeName,
    this.notes,
    this.dueDate,
    this.isAutoDebit = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate remaining months
  int? get remainingMonths {
    if (totalMonths == null) return null;
    final paid = paidMonths ?? 0;
    return (totalMonths! - paid).clamp(0, totalMonths!);
  }

  // Calculate progress based on months (if available) or amount
  double get progressByMonths {
    if (totalMonths == null || totalMonths == 0) return 0;
    final paid = paidMonths ?? 0;
    return (paid / totalMonths!).clamp(0.0, 1.0);
  }

  // Calculate progress based on amount paid
  double get progressByAmount {
    if (originalAmount <= 0) return 0;
    return ((originalAmount - currentBalance) / originalAmount).clamp(0.0, 1.0);
  }

  // Check if payment is due soon (within 5 days)
  bool get isPaymentDueSoon {
    if (nextPaymentDate == null) return false;
    final daysUntilDue = nextPaymentDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 5;
  }

  // Check if payment is overdue
  bool get isPaymentOverdue {
    if (nextPaymentDate == null) return false;
    return nextPaymentDate!.isBefore(DateTime.now());
  }

  // Get payment status
  PaymentStatus get paymentStatus {
    if (currentBalance <= 0) return PaymentStatus.paid;
    if (isPaymentOverdue) return PaymentStatus.overdue;
    if (isPaymentDueSoon) return PaymentStatus.pending;
    return PaymentStatus.pending;
  }

  // Days until next payment
  int? get daysUntilNextPayment {
    if (nextPaymentDate == null) return null;
    return nextPaymentDate!.difference(DateTime.now()).inDays;
  }

  // Estimated payoff date
  DateTime? get estimatedPayoffDate {
    if (remainingMonths == null || remainingMonths == 0) return null;
    return DateTime.now().add(Duration(days: remainingMonths! * 30));
  }

  // Total amount to be paid (principal + interest)
  double get totalAmountPayable {
    if (totalInterest != null) {
      return originalAmount + totalInterest!;
    }
    if (monthlyEMI != null && totalMonths != null) {
      return monthlyEMI! * totalMonths!;
    }
    return originalAmount;
  }

  // Amount saved if paid early
  double get potentialSavingsIfPaidNow {
    if (totalInterest == null || interestPaid == null) return 0;
    return totalInterest! - interestPaid!;
  }

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
      totalMonths: data['totalMonths'] as int?,
      paidMonths: data['paidMonths'] as int?,
      totalInterest: (data['totalInterest'] as num?)?.toDouble(),
      interestPaid: (data['interestPaid'] as num?)?.toDouble(),
      principalPaid: (data['principalPaid'] as num?)?.toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      paymentDay: data['paymentDay'] as int?,
      lenderName: data['lenderName'] as String?,
      accountNumber: data['accountNumber'] as String?,
      linkedAccountId: data['linkedAccountId'] as String?,
      customTypeName: data['customTypeName'] as String?,
      notes: data['notes'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      isAutoDebit: data['isAutoDebit'] as bool? ?? false,
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
      'totalMonths': totalMonths,
      'paidMonths': paidMonths,
      'totalInterest': totalInterest,
      'interestPaid': interestPaid,
      'principalPaid': principalPaid,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'nextPaymentDate': nextPaymentDate != null
          ? Timestamp.fromDate(nextPaymentDate!)
          : null,
      'paymentDay': paymentDay,
      'lenderName': lenderName,
      'accountNumber': accountNumber,
      'linkedAccountId': linkedAccountId,
      'customTypeName': customTypeName,
      'notes': notes,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isAutoDebit': isAutoDebit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Debt copyWith({
    String? id,
    String? userId,
    String? name,
    DebtType? type,
    double? originalAmount,
    double? currentBalance,
    double? interestRate,
    double? monthlyEMI,
    int? totalMonths,
    int? paidMonths,
    double? totalInterest,
    double? interestPaid,
    double? principalPaid,
    DateTime? startDate,
    DateTime? nextPaymentDate,
    int? paymentDay,
    String? lenderName,
    String? accountNumber,
    String? linkedAccountId,
    String? customTypeName,
    String? notes,
    DateTime? dueDate,
    bool? isAutoDebit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      monthlyEMI: monthlyEMI ?? this.monthlyEMI,
      totalMonths: totalMonths ?? this.totalMonths,
      paidMonths: paidMonths ?? this.paidMonths,
      totalInterest: totalInterest ?? this.totalInterest,
      interestPaid: interestPaid ?? this.interestPaid,
      principalPaid: principalPaid ?? this.principalPaid,
      startDate: startDate ?? this.startDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      paymentDay: paymentDay ?? this.paymentDay,
      lenderName: lenderName ?? this.lenderName,
      accountNumber: accountNumber ?? this.accountNumber,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      customTypeName: customTypeName ?? this.customTypeName,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      isAutoDebit: isAutoDebit ?? this.isAutoDebit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
