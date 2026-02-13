enum NotificationType {
  billReminder,
  goalAchievement,
  unusualSpending,
  transactionAlert,
  systemUpdate,
  goalProgress,
  budgetWarning,
  subscriptionReminder,
  fuelLogged,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionText;
  final String? actionRoute;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.actionText,
    this.actionRoute,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      actionText: map['actionText'],
      actionRoute: map['actionRoute'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'actionText': actionText,
      'actionRoute': actionRoute,
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionText,
    String? actionRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  static AppNotification budgetWarning({
    required String category,
    required String cycle,
    required double spentAmount,
    required double budgetAmount,
  }) {
    final percentage = (spentAmount / budgetAmount * 100).toStringAsFixed(0);
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.budgetWarning,
      title: 'Budget Warning',
      message:
          'You have spent $percentage% of your $cycle budget for $category.',
      createdAt: DateTime.now(),
      actionText: 'View Budget',
      actionRoute: '/budgets',
      data: {'category': category},
    );
  }

  static AppNotification subscriptionReminder({
    required String subscriptionName,
    required DateTime dueDate,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.subscriptionReminder,
      title: 'Subscription Reminder',
      message: '$subscriptionName is due on ${dueDate.day}/${dueDate.month}.',
      createdAt: DateTime.now(),
      actionText: 'View Subscriptions',
      actionRoute: '/subscriptions',
      data: {'subscriptionName': subscriptionName},
    );
  }

  static AppNotification billReminder({
    required String billName,
    required DateTime dueDate,
    required double amount,
  }) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.billReminder,
      title: 'Bill Reminder',
      message:
          '$billName is due in $daysUntilDue days (₹${amount.toStringAsFixed(2)})',
      createdAt: DateTime.now(),
      actionText: 'Pay Now',
      actionRoute: '/bills',
      data: {
        'billName': billName,
        'dueDate': dueDate.toIso8601String(),
        'amount': amount,
      },
    );
  }

  static AppNotification goalAchievement({
    required String goalName,
    required double targetAmount,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.goalAchievement,
      title: 'Goal Achieved! 🎉',
      message:
          'Congratulations! You\'ve reached your goal: $goalName (₹${targetAmount.toStringAsFixed(2)})',
      createdAt: DateTime.now(),
      actionText: 'View Goals',
      actionRoute: '/goals',
      data: {'goalName': goalName, 'targetAmount': targetAmount},
    );
  }

  static AppNotification unusualSpending({
    required double amount,
    required String category,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.unusualSpending,
      title: 'Unusual Spending Alert',
      message:
          'High spending detected in $category: ₹${amount.toStringAsFixed(2)}',
      createdAt: DateTime.now(),
      actionText: 'View Transactions',
      actionRoute: '/transactions',
      data: {'amount': amount, 'category': category},
    );
  }

  static AppNotification transactionAlert({
    required String description,
    required double amount,
    required bool isIncome,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.transactionAlert,
      title: isIncome ? 'Income Received' : 'Payment Made',
      message: '$description: ₹${amount.toStringAsFixed(2)}',
      createdAt: DateTime.now(),
      actionText: 'View Details',
      actionRoute: '/transactions',
      data: {
        'description': description,
        'amount': amount,
        'isIncome': isIncome,
      },
    );
  }

  static AppNotification goalProgress({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    required double progressPercentage,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.goalProgress,
      title: 'Goal Progress Update',
      message:
          '$goalName is ${progressPercentage.toStringAsFixed(1)}% complete (₹${currentAmount.toStringAsFixed(2)} / ₹${targetAmount.toStringAsFixed(2)})',
      createdAt: DateTime.now(),
      actionText: 'View Goal',
      actionRoute: '/goals',
      data: {
        'goalName': goalName,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
        'progressPercentage': progressPercentage,
      },
    );
  }

  static AppNotification fuelLogged({
    required String vehicleName,
    required double mileage,
    required double fuelAmount,
    required double cost,
  }) {
    String performanceEmoji = '⛽';
    String performanceMessage = '';

    if (mileage > 25) {
      performanceEmoji = '🌟';
      performanceMessage = 'Excellent fuel efficiency!';
    } else if (mileage > 20) {
      performanceEmoji = '✅';
      performanceMessage = 'Good fuel efficiency!';
    } else if (mileage > 15) {
      performanceEmoji = '⚠️';
      performanceMessage = 'Average fuel efficiency';
    } else {
      performanceEmoji = '⛽';
      performanceMessage = 'Low fuel efficiency';
    }

    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.fuelLogged,
      title: '$performanceEmoji Fuel Logged - $vehicleName',
      message:
          '$performanceMessage\nMileage: ${mileage.toStringAsFixed(2)} km/L\nFilled: ${fuelAmount.toStringAsFixed(2)}L for ₹${cost.toStringAsFixed(2)}',
      createdAt: DateTime.now(),
      actionText: 'View Garage',
      actionRoute: '/garage',
      data: {
        'vehicleName': vehicleName,
        'mileage': mileage,
        'fuelAmount': fuelAmount,
        'cost': cost,
      },
    );
  }
}
