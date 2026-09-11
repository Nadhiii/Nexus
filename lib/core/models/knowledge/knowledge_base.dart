import 'merchant_knowledge.dart';

/// Central repository for all Nexus knowledge
/// This is what makes Nexus "smart" - it remembers and learns
class KnowledgeBase {
  final Map<String, MerchantKnowledge> merchants;
  final Map<String, AccountKnowledge> accounts;
  final Map<String, CategoryRule> categoryRules;

  // Learning preferences
  final bool autoLearnEnabled;
  final double autoLearnThreshold; // Minimum confidence to learn without asking

  const KnowledgeBase({
    this.merchants = const {},
    this.accounts = const {},
    this.categoryRules = const {},
    this.autoLearnEnabled = true,
    this.autoLearnThreshold = 0.90,
  });

  /// Get merchant knowledge by ID
  MerchantKnowledge? getMerchant(String id) => merchants[id];

  /// Find merchant by name (fuzzy match)
  MerchantKnowledge? findMerchant(String name) {
    final normalizedName = name.toLowerCase().trim();

    // Exact match first
    if (merchants.containsKey(normalizedName)) {
      return merchants[normalizedName]!;
    }

    // Try keyword matching
    for (final merchant in merchants.values) {
      if (merchant.keywords.any((k) => normalizedName.contains(k))) {
        return merchant;
      }
      if (normalizedName.contains(merchant.id.toLowerCase())) {
        return merchant;
      }
    }

    return null;
  }

  /// Should we auto-approve this transaction based on knowledge?
  bool shouldAutoApproveTransaction({
    required String merchant,
    required double amount,
    required String? category,
  }) {
    if (!autoLearnEnabled) return false;

    final knownMerchant = findMerchant(merchant);
    if (knownMerchant == null) return false;

    // Check if merchant is recognized and can be auto-categorized
    if (!knownMerchant.canAutoCategorize) return false;

    // Check if amount is within normal range
    if (knownMerchant.isUnusualAmount(amount)) return false;

    return true;
  }

  /// Get explanation for a categorization decision
  String explainCategorization(String merchant, String category) {
    final knownMerchant = findMerchant(merchant);
    if (knownMerchant != null) {
      return knownMerchant.getExplanation();
    }
    return 'This is my best guess based on the merchant name and context';
  }

  KnowledgeBase copyWith({
    Map<String, MerchantKnowledge>? merchants,
    Map<String, AccountKnowledge>? accounts,
    Map<String, CategoryRule>? categoryRules,
    bool? autoLearnEnabled,
    double? autoLearnThreshold,
  }) {
    return KnowledgeBase(
      merchants: merchants ?? this.merchants,
      accounts: accounts ?? this.accounts,
      categoryRules: categoryRules ?? this.categoryRules,
      autoLearnEnabled: autoLearnEnabled ?? this.autoLearnEnabled,
      autoLearnThreshold: autoLearnThreshold ?? this.autoLearnThreshold,
    );
  }
}

/// Knowledge about a user's account
class AccountKnowledge {
  final String id;
  final String name;
  final AccountType type;
  final String? bankName;
  final String? accountNumberLast4;
  final bool isActive;
  final DateTime? lastUsed;
  final int transactionCount;

  const AccountKnowledge({
    required this.id,
    required this.name,
    this.type = AccountType.savings,
    this.bankName,
    this.accountNumberLast4,
    this.isActive = true,
    this.lastUsed,
    this.transactionCount = 0,
  });
}

enum AccountType {
  savings,
  current,
  creditCard,
  cash,
  investment,
  loan,
  wallet,
  other,
}

/// Explicit category rules set by user
class CategoryRule {
  final String id;
  final String merchantPattern; // Can be exact or contains
  final String category;
  final RuleType type;
  final bool isEnabled;
  final DateTime createdAt;

  const CategoryRule({
    required this.id,
    required this.merchantPattern,
    required this.category,
    this.type = RuleType.contains,
    this.isEnabled = true,
    required this.createdAt,
  });

  bool matches(String merchantName) {
    if (!isEnabled) return false;
    final normalized = merchantName.toLowerCase();
    final pattern = merchantPattern.toLowerCase();

    switch (type) {
      case RuleType.exact:
        return normalized == pattern;
      case RuleType.contains:
        return normalized.contains(pattern);
      case RuleType.startsWith:
        return normalized.startsWith(pattern);
      case RuleType.regex:
        // Simplified - in production use proper regex
        return normalized.contains(pattern);
    }
  }
}

enum RuleType { exact, contains, startsWith, regex }
