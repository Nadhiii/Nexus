import 'package:cloud_firestore/cloud_firestore.dart';
import '../detected_transaction.dart' show KnowledgeType;

/// Represents what Nexus knows about a merchant/entity
/// This is the core of Nexus's "memory" - it learns from repeated transactions
class MerchantKnowledge {
  final String id; // Unique ID (usually merchant name normalized)
  final String name; // User-friendly name
  final String normalizedName; // Lowercase, trimmed for matching
  final EntityType entityType; // Company, Person, Government, etc.

  // What Nexus has learned
  final String? defaultCategoryId; // Most common category
  final String? purpose; // What this merchant is for (Rent, Shopping, etc.)
  final bool isRecurring; // Is this a recurring payment?
  final RecurrenceFrequency? recurringFrequency;
  final int? recurringDayOfMonth;
  final double? typicalAmountMin;
  final double? typicalAmountMax;

  // Knowledge metadata
  final KnowledgeSource source; // How did we learn this?
  final int transactionCount; // How many times seen
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final double confidence; // How confident is Nexus in this knowledge?

  // User overrides
  final List<String> aliases; // Alternative names
  final String? notes;
  final bool isDisabled; // User marked as "don't use"

  // Relationships
  final String? preferredAccountId; // Preferred account for this merchant

  // Phase 1 intelligence aliases. These retain the richer learning model
  // while mapping cleanly to the persisted merchant document above.
  final List<String> categoryHistory;
  final double? typicalAmount;
  final AmountRange? amountRange;
  final RecurrencePattern? recurrence;
  final KnowledgeType knowledgeType;
  final DateTime firstSeen;
  final List<String> keywords;
  final bool isIgnored;
  final String? userSetCategory;
  final String? userSetName;

  MerchantKnowledge({
    this.id = '',
    String? name,
    String? normalizedName,
    String? displayName,
    String? inferredCategory,
    DateTime? lastSeen,
    this.entityType = EntityType.merchant,
    String? defaultCategoryId,
    this.purpose,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringDayOfMonth,
    this.typicalAmountMin,
    this.typicalAmountMax,
    this.source = KnowledgeSource.observed,
    this.transactionCount = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    this.confidence = 0.5,
    this.aliases = const [],
    this.notes,
    this.isDisabled = false,
    this.preferredAccountId,
    this.categoryHistory = const [],
    this.typicalAmount,
    this.amountRange,
    this.recurrence,
    this.knowledgeType = KnowledgeType.unknown,
    DateTime? firstSeen,
    this.keywords = const [],
    this.isIgnored = false,
    this.userSetCategory,
    this.userSetName,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       firstSeen = firstSeen ?? createdAt ?? DateTime.now(),
       name = displayName ?? name ?? '',
       normalizedName = normalizedName ?? (name ?? '').toLowerCase().trim(),
       defaultCategoryId = inferredCategory ?? defaultCategoryId,
       lastSeenAt = lastSeen ?? lastSeenAt;

  String get displayName => userSetName ?? name;
  String? get inferredCategory => userSetCategory ?? defaultCategoryId;
  String? get category => inferredCategory;
  int get occurrenceCount => transactionCount;
  DateTime? get lastSeen => lastSeenAt;
  bool isUnusualAmount(double amount) => amountRange != null
      ? amount < amountRange!.min || amount > amountRange!.max
      : (typicalAmount != null &&
            (amount - typicalAmount!).abs() > typicalAmount! * .5);
  String getExplanation() => inferredCategory == null
      ? 'Learned from $transactionCount observed transaction(s).'
      : 'Categorized as $inferredCategory from $transactionCount observed transaction(s).';

  /// Is this a recognized/recurring merchant?
  bool get isRecognized => transactionCount >= 3 || defaultCategoryId != null;

  /// Should Nexus auto-categorize transactions from this merchant?
  bool get canAutoCategorize =>
      defaultCategoryId != null && confidence >= 0.85 && !isDisabled;

  MerchantKnowledge copyWith({
    String? id,
    String? name,
    String? normalizedName,
    EntityType? entityType,
    String? defaultCategoryId,
    String? purpose,
    bool? isRecurring,
    RecurrenceFrequency? recurringFrequency,
    int? recurringDayOfMonth,
    double? typicalAmountMin,
    double? typicalAmountMax,
    KnowledgeSource? source,
    int? transactionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    double? confidence,
    List<String>? aliases,
    String? notes,
    bool? isDisabled,
    String? preferredAccountId,
    List<String>? categoryHistory,
    double? typicalAmount,
    AmountRange? amountRange,
    RecurrencePattern? recurrence,
    KnowledgeType? knowledgeType,
    DateTime? firstSeen,
    List<String>? keywords,
    bool? isIgnored,
    String? userSetCategory,
    String? userSetName,
  }) {
    return MerchantKnowledge(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      entityType: entityType ?? this.entityType,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      purpose: purpose ?? this.purpose,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      recurringDayOfMonth: recurringDayOfMonth ?? this.recurringDayOfMonth,
      typicalAmountMin: typicalAmountMin ?? this.typicalAmountMin,
      typicalAmountMax: typicalAmountMax ?? this.typicalAmountMax,
      source: source ?? this.source,
      transactionCount: transactionCount ?? this.transactionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      confidence: confidence ?? this.confidence,
      aliases: aliases ?? this.aliases,
      notes: notes ?? this.notes,
      isDisabled: isDisabled ?? this.isDisabled,
      preferredAccountId: preferredAccountId ?? this.preferredAccountId,
      categoryHistory: categoryHistory ?? this.categoryHistory,
      typicalAmount: typicalAmount ?? this.typicalAmount,
      amountRange: amountRange ?? this.amountRange,
      recurrence: recurrence ?? this.recurrence,
      knowledgeType: knowledgeType ?? this.knowledgeType,
      firstSeen: firstSeen ?? this.firstSeen,
      keywords: keywords ?? this.keywords,
      isIgnored: isIgnored ?? this.isIgnored,
      userSetCategory: userSetCategory ?? this.userSetCategory,
      userSetName: userSetName ?? this.userSetName,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'entity_type': entityType.name,
      'default_category_id': defaultCategoryId,
      'purpose': purpose,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency?.index,
      'recurring_day_of_month': recurringDayOfMonth,
      'typical_amount_min': typicalAmountMin,
      'typical_amount_max': typicalAmountMax,
      'source': source.index,
      'transaction_count': transactionCount,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'last_seen_at': lastSeenAt != null
          ? Timestamp.fromDate(lastSeenAt!)
          : null,
      'confidence': confidence,
      'aliases': aliases,
      'notes': notes,
      'is_disabled': isDisabled,
      'preferred_account_id': preferredAccountId,
    };
  }

  factory MerchantKnowledge.fromFirestore(Map<String, dynamic> data) {
    return MerchantKnowledge(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      normalizedName:
          data['normalized_name'] ??
          (data['name'] ?? '').toString().toLowerCase().trim(),
      entityType: EntityType.values.firstWhere(
        (e) => e.name == data['entity_type'],
        orElse: () => EntityType.merchant,
      ),
      defaultCategoryId: data['default_category_id'],
      purpose: data['purpose'],
      isRecurring: data['is_recurring'] ?? false,
      recurringFrequency: data['recurring_frequency'] != null
          ? RecurrenceFrequency.values[data['recurring_frequency']]
          : null,
      recurringDayOfMonth: data['recurring_day_of_month'],
      typicalAmountMin: data['typical_amount_min']?.toDouble(),
      typicalAmountMax: data['typical_amount_max']?.toDouble(),
      source: KnowledgeSource.values.firstWhere(
        (e) => e.index == data['source'],
        orElse: () => KnowledgeSource.observed,
      ),
      transactionCount: data['transaction_count'] ?? 1,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      lastSeenAt: data['last_seen_at'] != null
          ? (data['last_seen_at'] as Timestamp).toDate()
          : null,
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      aliases: List<String>.from(data['aliases'] ?? []),
      notes: data['notes'],
      isDisabled: data['is_disabled'] ?? false,
      preferredAccountId: data['preferred_account_id'],
    );
  }
}

class AmountRange {
  final double min;
  final double max;
  final double average;
  const AmountRange({
    required this.min,
    required this.max,
    required this.average,
  });
}

class RecurrencePattern {
  final RecurrenceFrequency frequency;
  final double? typicalAmount;
  const RecurrencePattern({required this.frequency, this.typicalAmount});
}

enum EntityType {
  merchant, // Business/company
  person, // Individual person
  government, // Government entity (tax, utilities)
  bank, // Financial institution
  subscription, // Recurring service
  transfer, // Internal transfer
  unknown,
}

enum KnowledgeSource {
  observed, // Learned from patterns
  explicit, // User told us directly
  imported, // Imported from rules
}

enum RecurrenceFrequency { daily, weekly, biweekly, monthly, quarterly, yearly }
