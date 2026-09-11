import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/detected_transaction.dart';
import '../models/knowledge/merchant_knowledge.dart';
import '../models/knowledge/knowledge_base.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/investment_provider.dart';
import '../providers/bike_provider.dart';

/// Central "Brain" for all transaction-related operations
/// This service coordinates between all providers to ensure consistent
/// transaction logging, balance updates, and financial insights across the app.
///
/// PHASE 1 UPDATE: Now includes Knowledge Base for intelligent auto-approval
class TransactionBrainService {
  static final TransactionBrainService _instance =
      TransactionBrainService._internal();

  factory TransactionBrainService() => _instance;

  TransactionBrainService._internal();

  static TransactionBrainService get instance => _instance;

  // Providers (set during initialization)
  TransactionProvider? _transactionProvider;
  AccountProvider? _accountProvider;
  BudgetProvider? _budgetProvider;
  DebtProvider? _debtProvider;
  SubscriptionProvider? _subscriptionProvider;
  GoalProvider? _goalProvider;
  InvestmentProvider? _investmentProvider;
  BikeProvider? _bikeProvider;

  // PHASE 1: Knowledge Base for learning and auto-approval
  KnowledgeBase _knowledgeBase = const KnowledgeBase();
  KnowledgeBase get knowledgeBase => _knowledgeBase;

  // Stream controller for transaction events
  final _transactionEventController =
      StreamController<TransactionEvent>.broadcast();
  Stream<TransactionEvent> get transactionEvents =>
      _transactionEventController.stream;

  // Stream controller for knowledge updates
  final _knowledgeEventController =
      StreamController<KnowledgeEvent>.broadcast();
  Stream<KnowledgeEvent> get knowledgeEvents =>
      _knowledgeEventController.stream;

  // Event types
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the brain with all required providers
  void initialize({
    required TransactionProvider transactionProvider,
    required AccountProvider accountProvider,
    BudgetProvider? budgetProvider,
    DebtProvider? debtProvider,
    SubscriptionProvider? subscriptionProvider,
    GoalProvider? goalProvider,
    InvestmentProvider? investmentProvider,
    BikeProvider? bikeProvider,
  }) {
    if (_isInitialized) return;

    _transactionProvider = transactionProvider;
    _accountProvider = accountProvider;
    _budgetProvider = budgetProvider;
    _debtProvider = debtProvider;
    _subscriptionProvider = subscriptionProvider;
    _goalProvider = goalProvider;
    _investmentProvider = investmentProvider;
    _bikeProvider = bikeProvider;

    _isInitialized = true;
    debugPrint('🧠 TransactionBrain initialized');
  }

  /// Centralized transaction logging - the "brain" way
  /// All screens should use this method instead of directly calling providers
  Future<bool> logTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    required String description,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized || _transactionProvider == null) {
      debugPrint('❌ TransactionBrain not initialized');
      return false;
    }

    try {
      // Create transaction
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        amount: amount,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        date: date,
        description: description,
        attachments: attachments ?? [],
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Log through central provider
      final success = await _transactionProvider!.addTransaction(transaction);

      if (success) {
        // Broadcast event to all listening screens
        _transactionEventController.add(
          TransactionEvent(
            type: TransactionEventType.transactionAdded,
            transaction: transaction,
            timestamp: DateTime.now(),
          ),
        );

        // Trigger balance recalculation
        await _recalculateBalances(accountId);

        // Update related modules based on category/metadata
        await _updateRelatedModules(transaction);

        debugPrint('✅ Transaction logged successfully: ${transaction.id}');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error logging transaction: $e');
      _transactionEventController.add(
        TransactionEvent(
          type: TransactionEventType.error,
          error: e.toString(),
          timestamp: DateTime.now(),
        ),
      );
      return false;
    }
  }

  /// Recalculate balances after transaction
  Future<void> _recalculateBalances(String accountId) async {
    if (_transactionProvider == null) return;
    await _transactionProvider!.recalculateAccountBalance(accountId);
  }

  /// Update related modules (debts, subscriptions, goals, etc.)
  Future<void> _updateRelatedModules(Transaction transaction) async {
    // Check if this transaction relates to any debts
    if (_debtProvider != null && transaction.metadata?['debtId'] != null) {
      // Mark debt payment
      debugPrint('📝 Updating debt: ${transaction.metadata!['debtId']}');
    }

    // Check if this is a subscription payment
    if (_subscriptionProvider != null &&
        transaction.metadata?['subscriptionId'] != null) {
      debugPrint(
        '📝 Updating subscription: ${transaction.metadata!['subscriptionId']}',
      );
    }

    // Check if this is a goal contribution
    if (_goalProvider != null && transaction.metadata?['goalId'] != null) {
      debugPrint('📝 Updating goal: ${transaction.metadata!['goalId']}');
    }

    // Check if this is a bike/fuel expense
    if (_bikeProvider != null && transaction.metadata?['bikeId'] != null) {
      debugPrint(
        '📝 Updating bike expense: ${transaction.metadata!['bikeId']}',
      );
    }
  }

  // ==================== PHASE 1: INTELLIGENCE FEATURES ====================

  /// Auto-approve a detected transaction if confidence is high enough
  /// This bypasses the Smart Approval screen entirely
  Future<bool> autoApproveTransaction(DetectedTransaction detected) async {
    if (!_isInitialized || _transactionProvider == null) {
      return false;
    }

    // Check if knowledge base says we should auto-approve
    if (_knowledgeBase.shouldAutoApproveTransaction(
      merchant: detected.merchant,
      amount: detected.amount,
      category: detected.detectedCategory,
    )) {
      debugPrint(
        '🧠 Auto-approved (knowledge): ${detected.merchant} ₹${detected.amount}',
      );
    } else if (!detected.shouldAutoApprove) {
      debugPrint(
        '⚠️ Transaction needs review: ${detected.merchant} (${detected.questionToAsk})',
      );
      return false;
    } else {
      debugPrint(
        '🧠 Auto-approved (confidence): ${detected.merchant} ₹${detected.amount}',
      );
    }

    // Convert DetectedTransaction to Transaction and log it
    final category = await _getCategoryId(detected.detectedCategory);
    final account = await _getAccountId(detected.accountId);

    if (category == null || account == null) {
      debugPrint('❌ Cannot auto-approve: missing category or account');
      return false;
    }

    final result = await logTransaction(
      amount: detected.amount,
      type: detected.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: category,
      accountId: account,
      date: detected.date,
      description: detected.merchant,
      notes: detected.body,
      metadata: {
        'source': detected.source,
        'detectedCategory': detected.detectedCategory,
        'confidence': detected.confidence.overall,
        'autoApproved': true,
        'isRecurring': detected.isRecurring,
      },
    );

    if (result) {
      // Update knowledge base with this transaction
      _learnFromTransaction(detected);
    }

    return result;
  }

  /// Learn from a transaction to improve future auto-approvals
  void _learnFromTransaction(DetectedTransaction detected) {
    // Only learn from high-confidence or user-corrected transactions
    if (detected.confidence.overall < 0.70) {
      return;
    }

    final merchantId = detected.merchant.toLowerCase().trim();
    final now = DateTime.now();

    // Get existing knowledge or create new
    var knowledge = _knowledgeBase.getMerchant(merchantId);

    if (knowledge == null) {
      // Create new merchant knowledge
      knowledge = MerchantKnowledge(
        id: merchantId,
        displayName: detected.merchant,
        inferredCategory: detected.detectedCategory,
        categoryHistory: detected.detectedCategory != null
            ? [detected.detectedCategory!]
            : [],
        typicalAmount: detected.amount,
        amountRange: AmountRange(
          min: detected.amount,
          max: detected.amount,
          average: detected.amount,
        ),
        recurrence: detected.isRecurring
            ? RecurrencePattern(
                frequency: RecurrenceFrequency.monthly,
                typicalAmount: detected.amount,
              )
            : null,
        knowledgeType: detected.knowledgeType,
        firstSeen: now,
        lastSeenAt: now,
        transactionCount: 1,
        confidence: detected.confidence.merchant,
        keywords: [merchantId],
      );

      _knowledgeBase = _knowledgeBase.copyWith(
        merchants: Map<String, MerchantKnowledge>.from(_knowledgeBase.merchants)
          ..[merchantId] = knowledge,
      );

      _knowledgeEventController.add(
        KnowledgeEvent(
          type: KnowledgeEventType.learned,
          merchantId: merchantId,
          timestamp: now,
        ),
      );

      debugPrint(
        '🧠 Learned new merchant: ${detected.merchant} → ${detected.detectedCategory}',
      );
    } else {
      // Update existing knowledge
      final updatedCategories = List<String>.from(knowledge.categoryHistory);
      if (detected.detectedCategory != null &&
          !updatedCategories.contains(detected.detectedCategory)) {
        updatedCategories.add(detected.detectedCategory!);
      }

      final newAmountRange = knowledge.amountRange != null
          ? AmountRange(
              min: knowledge.amountRange!.min.clamp(0, detected.amount),
              max: knowledge.amountRange!.max.clamp(
                detected.amount,
                double.infinity,
              ),
              average: (knowledge.amountRange!.average + detected.amount) / 2,
            )
          : null;

      knowledge = knowledge.copyWith(
        categoryHistory: updatedCategories,
        typicalAmount:
            ((knowledge.typicalAmount ?? detected.amount) + detected.amount) /
            2,
        amountRange: newAmountRange,
        lastSeenAt: now,
        transactionCount: knowledge.transactionCount + 1,
        confidence: (knowledge.confidence + detected.confidence.merchant) / 2,
      );

      _knowledgeBase = _knowledgeBase.copyWith(
        merchants: Map<String, MerchantKnowledge>.from(_knowledgeBase.merchants)
          ..[merchantId] = knowledge,
      );

      debugPrint(
        '🧠 Updated merchant: ${detected.merchant} (${knowledge.transactionCount}x seen)',
      );
    }
  }

  /// Get category ID from name (helper for auto-approval)
  Future<String?> _getCategoryId(String? categoryName) async {
    if (categoryName == null) return null;
    // In full implementation, query CategoryProvider
    // For now, return a placeholder
    return categoryName.toLowerCase();
  }

  /// Get account ID (helper for auto-approval)
  Future<String?> _getAccountId(String? accountId) async {
    // In full implementation, resolve account ID
    // For now, use default or first account
    return accountId ?? 'default';
  }

  /// Manually update knowledge base (for user corrections)
  void updateMerchantKnowledge({
    required String merchantId,
    String? category,
    String? name,
    bool? ignore,
  }) {
    final knowledge = _knowledgeBase.getMerchant(merchantId);
    if (knowledge == null) return;

    final updated = knowledge.copyWith(
      userSetCategory: category,
      userSetName: name,
      isIgnored: ignore,
      knowledgeType: KnowledgeType.explicit,
    );

    _knowledgeBase = _knowledgeBase.copyWith(
      merchants: Map<String, MerchantKnowledge>.from(_knowledgeBase.merchants)
        ..[merchantId] = updated,
    );

    _knowledgeEventController.add(
      KnowledgeEvent(
        type: KnowledgeEventType.updated,
        merchantId: merchantId,
        timestamp: DateTime.now(),
      ),
    );

    debugPrint('🧠 Updated knowledge for $merchantId');
  }

  /// Get explanation for why a transaction was categorized a certain way
  String explainCategorization(String merchant, String category) {
    return _knowledgeBase.explainCategorization(merchant, category);
  }

  /// Get unified financial summary across all modules
  Future<Map<String, dynamic>> getFinancialSummary() async {
    if (!_isInitialized) return {};

    final summary = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Accounts
    if (_accountProvider != null) {
      final accounts = _accountProvider!.accounts;
      summary['totalBalance'] = accounts.fold<double>(
        0.0,
        (sum, acc) => sum + acc.balance,
      );
      summary['accountCount'] = accounts.length;
    }

    // Transactions
    if (_transactionProvider != null) {
      final transactions = _transactionProvider!.transactions;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final monthlyTxns = transactions
          .where((t) => t.date.isAfter(monthStart))
          .toList();
      summary['monthlyIncome'] = monthlyTxns
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      summary['monthlyExpense'] = monthlyTxns
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
    }

    // Debts
    if (_debtProvider != null) {
      summary['totalDebt'] = _debtProvider!.debts.fold<double>(
        0.0,
        (sum, debt) => sum + debt.outstandingAmount,
      );
    }

    // Subscriptions
    if (_subscriptionProvider != null) {
      summary['monthlySubscriptions'] = _subscriptionProvider!.subscriptions
          .fold<double>(0.0, (sum, sub) => sum + sub.amount);
    }

    return summary;
  }

  /// Dispose resources
  void dispose() {
    _transactionEventController.close();
    _knowledgeEventController.close();
    debugPrint('🧠 TransactionBrain disposed');
  }
}

/// Event types for transaction broadcasting
enum TransactionEventType {
  transactionAdded,
  transactionUpdated,
  transactionDeleted,
  balanceRecalculated,
  error,
}

/// Transaction event data
class TransactionEvent {
  final TransactionEventType type;
  final Transaction? transaction;
  final String? error;
  final DateTime timestamp;

  TransactionEvent({
    required this.type,
    this.transaction,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ==================== PHASE 1: KNOWLEDGE EVENTS ====================

/// Knowledge event types
enum KnowledgeEventType {
  learned, // New merchant/pattern learned
  updated, // Existing knowledge updated
  deleted, // Knowledge removed
  reset, // All knowledge reset
}

/// Knowledge event data
class KnowledgeEvent {
  final KnowledgeEventType type;
  final String? merchantId;
  final String? details;
  final DateTime timestamp;

  KnowledgeEvent({
    required this.type,
    this.merchantId,
    this.details,
    required this.timestamp,
  });
}
