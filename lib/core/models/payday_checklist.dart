enum ChecklistItemType {
  debtEMI,
  familyDebt,
  subscription,
  goalContribution,
  budgetAllocation,
  savingsTransfer,
}

enum ChecklistItemPriority {
  urgent,
  high,
  medium,
  low,
}

class PaydayChecklistItem {
  final String id;
  final ChecklistItemType type;
  final ChecklistItemPriority priority;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime? dueDate;
  final String? accountId;
  final String? personName;
  final Map<String, dynamic>? metadata;

  const PaydayChecklistItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.dueDate,
    this.accountId,
    this.personName,
    this.metadata,
  });
}

class PaydayChecklist {
  final double incomeAmount;
  final String? incomeSource;
  final DateTime incomeDate;
  final List<PaydayChecklistItem> items;
  final double totalObligations;
  final double suggestedSavings;

  const PaydayChecklist({
    required this.incomeAmount,
    required this.incomeSource,
    required this.incomeDate,
    required this.items,
    required this.totalObligations,
    required this.suggestedSavings,
  });
}