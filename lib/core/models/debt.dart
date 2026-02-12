import 'package:cloud_firestore/cloud_firestore.dart';

/// Debt types for formal liabilities (banks, NBFCs, credit cards)
/// For personal IOUs (money lent/borrowed from people), use Family module
enum DebtType {
  // Credit Cards
  creditCard,

  // Loans
  personalLoan,
  homeLoan,
  carLoan,
  educationLoan,
  businessLoan,
  goldLoan,
  twoWheelerLoan,

  // Legacy (kept for backward compatibility with existing data)
  @Deprecated('Use Family module for IOUs')
  owedByMe,
  @Deprecated('Use Family module for IOUs')
  owedToMe,

  custom,
  other,
}

/// Helper extension for DebtType categorization
extension DebtTypeExtension on DebtType {
  bool get isLoan => [
    DebtType.personalLoan,
    DebtType.homeLoan,
    DebtType.carLoan,
    DebtType.educationLoan,
    DebtType.businessLoan,
    DebtType.goldLoan,
    DebtType.twoWheelerLoan,
    DebtType.other,
    DebtType.custom,
  ].contains(this);

  bool get isCreditCard => this == DebtType.creditCard;

  // ignore: deprecated_member_use_from_same_package
  bool get isLegacyIOU =>
      this == DebtType.owedByMe || this == DebtType.owedToMe;

  String get displayName {
    switch (this) {
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
      case DebtType.twoWheelerLoan:
        return 'Two Wheeler Loan';
      case DebtType.owedByMe:
        return 'Personal (Legacy)';
      case DebtType.owedToMe:
        return 'Personal (Legacy)';
      case DebtType.custom:
        return 'Custom';
      case DebtType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DebtType.creditCard:
        return '💳';
      case DebtType.personalLoan:
        return '🏦';
      case DebtType.homeLoan:
        return '🏠';
      case DebtType.carLoan:
        return '🚗';
      case DebtType.educationLoan:
        return '🎓';
      case DebtType.businessLoan:
        return '💼';
      case DebtType.goldLoan:
        return '🥇';
      case DebtType.twoWheelerLoan:
        return '🏍️';
      case DebtType.owedByMe:
      case DebtType.owedToMe:
        return '👤';
      case DebtType.custom:
      case DebtType.other:
        return '📄';
    }
  }
}

enum PaymentStatus { pending, paid, overdue, partiallyPaid }

class Debt {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double originalAmount;
  final double currentBalance;

  // Advanced Loan Fields
  final double? interestRate;
  final double? monthlyEMI;
  final int? totalMonths;
  final int? paidMonths;
  final double? totalInterest;
  final double? interestPaid;
  final double? principalPaid;
  final DateTime? startDate;
  final DateTime? nextPaymentDate;
  final int? paymentDay;
  final String? lenderName; // Used for Bank Name OR Person Name (IOU)
  final String? accountNumber;
  final String? linkedAccountId;
  final String? customTypeName;
  final String? notes;
  final DateTime? dueDate;
  final bool isAutoDebit;

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

  // --- COMPATIBILITY HELPERS ---
  // Alias for new code that might look for 'personName'
  String get personName => lenderName ?? 'Unknown';

  // --- LOGIC GETTERS (Restored for your UI) ---

  int? get remainingMonths {
    if (totalMonths == null) return null;
    final paid = paidMonths ?? 0;
    return (totalMonths! - paid).clamp(0, totalMonths!);
  }

  double get progressByMonths {
    if (totalMonths == null || totalMonths == 0) return 0;
    final paid = paidMonths ?? 0;
    return (paid / totalMonths!).clamp(0.0, 1.0);
  }

  bool get isPaymentDueSoon {
    if (nextPaymentDate == null) return false;
    final daysUntilDue = nextPaymentDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 5;
  }

  bool get isPaymentOverdue {
    if (nextPaymentDate == null) return false;
    // If balance is 0, it's not overdue
    if (currentBalance <= 0) return false;
    return nextPaymentDate!.isBefore(DateTime.now());
  }

  int? get daysUntilNextPayment {
    if (nextPaymentDate == null) return null;
    return nextPaymentDate!.difference(DateTime.now()).inDays;
  }

  DateTime? get estimatedPayoffDate {
    if (remainingMonths == null || remainingMonths == 0) return null;
    return DateTime.now().add(Duration(days: remainingMonths! * 30));
  }

  // --- FACTORIES & SERIALIZATION ---

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Debt.fromMap(data);
  }

  factory Debt.fromMap(Map<String, dynamic> data) {
    return Debt(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      // Handle Integer vs String enum storage
      type: data['type'] is int
          ? DebtType.values[data['type']]
          : DebtType.values.firstWhere(
              (e) => e.toString().split('.').last == data['type'],
              orElse: () => DebtType.other,
            ),
      originalAmount: (data['originalAmount'] ?? 0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0).toDouble(),
      interestRate: data['interestRate']?.toDouble(),
      monthlyEMI: data['monthlyEMI']?.toDouble(),
      totalMonths: data['totalMonths'],
      paidMonths: data['paidMonths'],
      totalInterest: data['totalInterest']?.toDouble(),
      interestPaid: data['interestPaid']?.toDouble(),
      principalPaid: data['principalPaid']?.toDouble(),
      startDate: _parseDate(data['startDate']),
      nextPaymentDate: _parseDate(data['nextPaymentDate']),
      paymentDay: data['paymentDay'],
      lenderName: data['lenderName'] ?? data['personName'], // Fallback for IOU
      accountNumber: data['accountNumber'],
      linkedAccountId: data['linkedAccountId'],
      customTypeName: data['customTypeName'],
      notes: data['notes'],
      dueDate: _parseDate(data['dueDate']),
      isAutoDebit: data['isAutoDebit'] ?? false,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  // Required by your DebtProvider
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.index, // Storing as index to match your old data
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
      'personName': lenderName, // Duplicate for new code compatibility
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

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return null;
  }
}
