/// Payday Checklist Model
/// Represents action items to handle after receiving income
library;

enum ChecklistItemType {
  debtEMI,
  familyDebt, // Money you owe someone
  subscription,
  budgetAllocation,
  goalContribution,
  savingsTransfer,
}

enum ChecklistItemPriority {
  urgent, // Due within 3 days or overdue
  high, // Due within 7 days
  medium, // Due within 14 days
  low, // Suggested/optional
}

/// Individual checklist item
class PaydayChecklistItem {
  final String id;
  final ChecklistItemType type;
  final ChecklistItemPriority priority;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime? dueDate;
  final String? personName; // For family debts
  final String? accountId; // Target account for transfers
  final Map<String, dynamic>? metadata;
  final bool isCompleted;

  PaydayChecklistItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.dueDate,
    this.personName,
    this.accountId,
    this.metadata,
    this.isCompleted = false,
  });

  /// Get icon based on type
  String get iconName {
    switch (type) {
      case ChecklistItemType.debtEMI:
        return 'credit_card';
      case ChecklistItemType.familyDebt:
        return 'people';
      case ChecklistItemType.subscription:
        return 'autorenew';
      case ChecklistItemType.budgetAllocation:
        return 'pie_chart';
      case ChecklistItemType.goalContribution:
        return 'flag';
      case ChecklistItemType.savingsTransfer:
        return 'savings';
    }
  }

  /// Days until due (negative if overdue)
  int? get daysUntilDue {
    if (dueDate == null) { return null; }
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Check if overdue
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Human-readable due status
  String get dueStatus {
    if (dueDate == null) { return 'Suggested'; }
    final days = daysUntilDue!;
    if (days < 0) { return 'Overdue by ${days.abs()} days'; }
    if (days == 0) { return 'Due today'; }
    if (days == 1) { return 'Due tomorrow'; }
    return 'Due in $days days';
  }

  PaydayChecklistItem copyWith({
    String? id,
    ChecklistItemType? type,
    ChecklistItemPriority? priority,
    String? title,
    String? subtitle,
    double? amount,
    DateTime? dueDate,
    String? personName,
    String? accountId,
    Map<String, dynamic>? metadata,
    bool? isCompleted,
  }) {
    return PaydayChecklistItem(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      personName: personName ?? this.personName,
      accountId: accountId ?? this.accountId,
      metadata: metadata ?? this.metadata,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Complete payday checklist
class PaydayChecklist {
  final double incomeAmount;
  final String? incomeSource;
  final DateTime incomeDate;
  final List<PaydayChecklistItem> items;
  final double totalObligations; // Sum of all urgent/high priority items
  final double suggestedSavings; // Recommended savings amount

  PaydayChecklist({
    required this.incomeAmount,
    this.incomeSource,
    required this.incomeDate,
    required this.items,
    required this.totalObligations,
    required this.suggestedSavings,
  });

  /// Get items by type
  List<PaydayChecklistItem> getByType(ChecklistItemType type) {
    return items.where((i) => i.type == type).toList();
  }

  /// Get items by priority
  List<PaydayChecklistItem> getByPriority(ChecklistItemPriority priority) {
    return items.where((i) => i.priority == priority).toList();
  }

  /// Get urgent items (due within 3 days)
  List<PaydayChecklistItem> get urgentItems =>
      items.where((i) => i.priority == ChecklistItemPriority.urgent).toList();

  /// Get high priority items
  List<PaydayChecklistItem> get highPriorityItems =>
      items.where((i) => i.priority == ChecklistItemPriority.high).toList();

  /// Total amount for urgent items
  double get urgentTotal =>
      urgentItems.fold(0, (sum, item) => sum + item.amount);

  /// Amount remaining after obligations
  double get remainingAfterObligations => incomeAmount - totalObligations;

  /// Check if income covers all obligations
  bool get canCoverObligations => remainingAfterObligations >= 0;

  /// Percentage of income going to obligations
  double get obligationPercentage =>
      incomeAmount > 0 ? (totalObligations / incomeAmount) * 100 : 0;

  /// Count of pending items
  int get pendingCount => items.where((i) => !i.isCompleted).length;

  /// Count of completed items
  int get completedCount => items.where((i) => i.isCompleted).length;
}
