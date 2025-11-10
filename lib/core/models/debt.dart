import 'package:flutter/material.dart';

enum DebtType {
  creditCard,
  personalLoan,
  homeLoan,
  carLoan,
  educationLoan,
  businessLoan,
  goldLoan,
  other,
}

enum DebtPayoffStrategy {
  snowball, // Pay minimum on all, extra on smallest balance
  avalanche, // Pay minimum on all, extra on highest interest
  custom, // User-defined priority
}

enum PaymentFrequency { monthly, biweekly, weekly, quarterly }

class Debt {
  final String id;
  final String name;
  final DebtType type;
  final String? lenderName;
  final double originalAmount; // Total loan amount
  final double currentBalance; // Remaining balance
  final double monthlyEMI; // Monthly EMI payment
  final double interestRate; // Annual percentage rate
  final int totalTenureMonths; // Total loan tenure in months
  final int monthsPaid; // Number of months already paid
  final DateTime startDate; // Loan start date
  final DateTime endDate; // Loan end date
  final String? accountNumber;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? notes;

  // Payoff strategy fields
  final int priority; // 1 = highest priority
  final double? extraPayment; // Additional amount being paid
  final DateTime? targetPayoffDate;

  // Tracking fields
  final DateTime? lastPaymentDate;
  final DateTime? nextDueDate; // Next EMI due date for notifications
  final double totalPaid;
  final double totalInterestPaid;

  Debt({
    required this.id,
    required this.name,
    required this.type,
    this.lenderName,
    required this.originalAmount,
    required this.currentBalance,
    required this.monthlyEMI,
    required this.interestRate,
    required this.totalTenureMonths,
    required this.monthsPaid,
    required this.startDate,
    required this.endDate,
    this.accountNumber,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.notes,
    this.priority = 1,
    this.extraPayment,
    this.targetPayoffDate,
    this.lastPaymentDate,
    this.nextDueDate,
    this.totalPaid = 0.0,
    this.totalInterestPaid = 0.0,
  });

  // Create copy with updated fields
  Debt copyWith({
    String? id,
    String? name,
    DebtType? type,
    String? lenderName,
    double? originalAmount,
    double? currentBalance,
    double? monthlyEMI,
    double? interestRate,
    int? totalTenureMonths,
    int? monthsPaid,
    DateTime? startDate,
    DateTime? endDate,
    String? accountNumber,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? notes,
    int? priority,
    double? extraPayment,
    DateTime? targetPayoffDate,
    DateTime? lastPaymentDate,
    DateTime? nextDueDate,
    double? totalPaid,
    double? totalInterestPaid,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lenderName: lenderName ?? this.lenderName,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      monthlyEMI: monthlyEMI ?? this.monthlyEMI,
      interestRate: interestRate ?? this.interestRate,
      totalTenureMonths: totalTenureMonths ?? this.totalTenureMonths,
      monthsPaid: monthsPaid ?? this.monthsPaid,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountNumber: accountNumber ?? this.accountNumber,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      extraPayment: extraPayment ?? this.extraPayment,
      targetPayoffDate: targetPayoffDate ?? this.targetPayoffDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      totalPaid: totalPaid ?? this.totalPaid,
      totalInterestPaid: totalInterestPaid ?? this.totalInterestPaid,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'lenderName': lenderName,
      'originalAmount': originalAmount,
      'currentBalance': currentBalance,
      'monthlyEMI': monthlyEMI,
      'interestRate': interestRate,
      'totalTenureMonths': totalTenureMonths,
      'monthsPaid': monthsPaid,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'accountNumber': accountNumber,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'notes': notes,
      'priority': priority,
      'extraPayment': extraPayment,
      'targetPayoffDate': targetPayoffDate?.millisecondsSinceEpoch,
      'lastPaymentDate': lastPaymentDate?.millisecondsSinceEpoch,
      'nextDueDate': nextDueDate?.millisecondsSinceEpoch,
      'totalPaid': totalPaid,
      'totalInterestPaid': totalInterestPaid,
    };
  }

  // Create from Map
  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      type: DebtType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DebtType.other,
      ),
      lenderName: map['lenderName'],
      originalAmount: map['originalAmount']?.toDouble() ?? 0.0,
      currentBalance: map['currentBalance']?.toDouble() ?? 0.0,
      monthlyEMI: map['monthlyEMI']?.toDouble() ?? 0.0,
      interestRate: map['interestRate']?.toDouble() ?? 0.0,
      totalTenureMonths: map['totalTenureMonths']?.toInt() ?? 0,
      monthsPaid: map['monthsPaid']?.toInt() ?? 0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      accountNumber: map['accountNumber'],
      color: Color(map['color'] ?? Colors.red.value),
      icon: IconData(
        map['icon'] ?? Icons.credit_card.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
      priority: map['priority'] ?? 1,
      extraPayment: map['extraPayment']?.toDouble(),
      targetPayoffDate: map['targetPayoffDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['targetPayoffDate'])
          : null,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'])
          : null,
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextDueDate'])
          : null,
      totalPaid: map['totalPaid']?.toDouble() ?? 0.0,
      totalInterestPaid: map['totalInterestPaid']?.toDouble() ?? 0.0,
    );
  }

  // Helper methods and calculations
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
      case DebtType.other:
        return 'Other Debt';
    }
  }

  String get formattedBalance {
    return '₹${currentBalance.toStringAsFixed(2)}';
  }

  String get formattedMonthlyEMI {
    return '₹${monthlyEMI.toStringAsFixed(2)}';
  }

  String get formattedInterestRate {
    return '${interestRate.toStringAsFixed(2)}%';
  }

  // New loan-specific properties
  int get remainingMonths {
    return totalTenureMonths - monthsPaid;
  }

  double get progressPercentage {
    if (totalTenureMonths == 0) return 0.0;
    return (monthsPaid / totalTenureMonths * 100).clamp(0.0, 100.0);
  }

  // Calculate expected current balance based on EMI schedule
  double get expectedBalance {
    if (monthsPaid == 0) return originalAmount;

    double balance = originalAmount;
    for (int i = 0; i < monthsPaid; i++) {
      double monthlyInterest = (balance * (interestRate / 100)) / 12;
      double principalPaid = monthlyEMI - monthlyInterest;
      balance -= principalPaid;
    }
    return balance.clamp(0.0, originalAmount);
  }

  // Check if loan is on track
  bool get isOnTrack {
    return (currentBalance - expectedBalance).abs() <
        (monthlyEMI * 0.1); // Within 10% of EMI
  }

  double get progressPercentageAmount {
    if (originalAmount == 0) return 0.0;
    return ((originalAmount - currentBalance) / originalAmount * 100).clamp(
      0.0,
      100.0,
    );
  }

  // Calculate monthly interest payment
  double get monthlyInterestPayment {
    return (currentBalance * (interestRate / 100)) / 12;
  }

  // Calculate how long to pay off with EMI payments
  int get monthsToPayoffWithEMI {
    if (monthlyEMI <= monthlyInterestPayment) {
      return -1; // Never pays off (payment less than interest)
    }

    double balance = currentBalance;
    int months = 0;

    while (balance > 0 && months < 1000) {
      // Limit to prevent infinite loop
      double interestPayment = (balance * (interestRate / 100)) / 12;
      double principalPayment = monthlyEMI - interestPayment;
      balance -= principalPayment;
      months++;
    }

    return months;
  }

  // Calculate total interest with EMI payments
  double get totalInterestWithEMI {
    if (monthlyEMI <= monthlyInterestPayment) {
      return double.infinity; // Never pays off
    }

    double balance = currentBalance;
    double totalInterest = 0.0;
    int months = 0;

    while (balance > 0 && months < 1000) {
      double interestPayment = (balance * (interestRate / 100)) / 12;
      double principalPayment = monthlyEMI - interestPayment;
      totalInterest += interestPayment;
      balance -= principalPayment;
      months++;
    }

    return totalInterest;
  }

  // Calculate payoff with extra payment
  Map<String, dynamic> calculatePayoffWithExtra(double extraAmount) {
    double totalPayment = monthlyEMI + extraAmount;

    if (totalPayment <= monthlyInterestPayment) {
      return {
        'months': -1,
        'totalInterest': double.infinity,
        'monthlySavings': 0.0,
        'totalSavings': 0.0,
      };
    }

    double balance = currentBalance;
    double totalInterest = 0.0;
    int months = 0;

    while (balance > 0 && months < 1000) {
      double interestPayment = (balance * (interestRate / 100)) / 12;
      double principalPayment = totalPayment - interestPayment;

      if (principalPayment >= balance) {
        totalInterest += (balance * (interestRate / 100)) / 12;
        break;
      }

      totalInterest += interestPayment;
      balance -= principalPayment;
      months++;
    }

    double originalTotalInterest = totalInterestWithEMI;
    double savings = originalTotalInterest - totalInterest;
    int originalMonths = monthsToPayoffWithEMI;

    return {
      'months': months,
      'totalInterest': totalInterest,
      'monthlySavings': extraAmount,
      'totalSavings': savings,
      'timeSaved': originalMonths - months,
    };
  }

  bool get isHighInterest => interestRate > 15.0;
  bool get isOverdue {
    if (lastPaymentDate == null) return false;
    return DateTime.now().difference(lastPaymentDate!).inDays >
        35; // Assuming monthly payments
  }

  String get displayName {
    if (lenderName != null && lenderName!.isNotEmpty) {
      return '$name - $lenderName';
    }
    return name;
  }

  String get urgencyLevel {
    if (isOverdue) return 'Overdue';
    if (isHighInterest) return 'High Interest';
    if (interestRate > 10.0) return 'Medium Priority';
    return 'Low Priority';
  }

  Color get urgencyColor {
    if (isOverdue) return Colors.red;
    if (isHighInterest) return Colors.orange;
    if (interestRate > 10.0) return Colors.yellow.shade700;
    return Colors.green;
  }
}
