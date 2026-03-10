/// A universal service to automatically suggest classifications for all app entities
library;
import 'smart_category_resolver.dart';

class UniversalCategorizationService {
  UniversalCategorizationService();

  // ==================== DEBT TYPE SUGGESTION ====================

  static final Map<String, String> _debtTypeKeywords = {
    // Credit Cards
    'credit card': 'creditCard',
    'credit': 'creditCard',
    'card': 'creditCard',

    // Home Loans
    'home loan': 'homeLoan',
    'housing loan': 'homeLoan',
    'housing': 'homeLoan',
    'mortgage': 'homeLoan',
    'property loan': 'homeLoan',

    // Car Loans
    'car loan': 'carLoan',
    'vehicle loan': 'carLoan',
    'auto loan': 'carLoan',
    'bike loan': 'carLoan',

    // Education Loans
    'education loan': 'educationLoan',
    'student loan': 'educationLoan',
    'education': 'educationLoan',
    'student': 'educationLoan',

    // Personal Loans
    'personal loan': 'personalLoan',
    'personal': 'personalLoan',

    // Business Loans
    'business loan': 'businessLoan',
    'business': 'businessLoan',
    'commercial': 'businessLoan',

    // Gold Loans
    'gold loan': 'goldLoan',
    'gold': 'goldLoan',

    // Owed
    'owed to me': 'owedToMe',
    'lent': 'owedToMe',
    'owed by me': 'owedByMe',
    'borrowed': 'owedByMe',
  };

  String? suggestDebtType(String name) {
    // Keyword matching
    final lowerName = name.toLowerCase();
    for (final keyword in _debtTypeKeywords.keys) {
      if (lowerName.contains(keyword)) {
        return _debtTypeKeywords[keyword]!;
      }
    }

    // 3. Default
    return null; // Let user choose
  }

  // ==================== SUBSCRIPTION CATEGORY SUGGESTION ====================

  static final Map<String, String> _subscriptionCategoryKeywords = {
    // Food & Dining
    'zomato': 'Food & Dining',
    'swiggy': 'Food & Dining',
    'ubereats': 'Food & Dining',

    // Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',

    // Entertainment
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'prime video': 'Entertainment',
    'hotstar': 'Entertainment',
    'disney': 'Entertainment',
    'youtube premium': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'apple music': 'Entertainment',

    // Bills & Utilities
    'electricity': 'Bills',
    'water': 'Bills',
    'gas': 'Bills',
    'broadband': 'Bills',
    'internet': 'Bills',
    'mobile': 'Bills',
    'phone': 'Bills',

    // Healthcare
    'gym': 'Healthcare',
    'fitness': 'Healthcare',
    'health': 'Healthcare',
    'insurance': 'Healthcare',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'metro': 'Transportation',

    // Software/Cloud
    'cloud': 'Software',
    'storage': 'Software',
    'office': 'Software',
    'adobe': 'Software',
    'microsoft': 'Software',
    'google one': 'Software',
    'icloud': 'Software',
  };

  String? suggestSubscriptionCategory(String name) {
    // Keyword matching
    final lowerName = name.toLowerCase();
    for (final keyword in _subscriptionCategoryKeywords.keys) {
      if (lowerName.contains(keyword)) {
        return _subscriptionCategoryKeywords[keyword]!;
      }
    }

    // 3. Default
    return 'Miscellaneous';
  }

  // ==================== INVESTMENT SCHEME SUGGESTION ====================

  String? suggestInvestmentScheme(String name) {
    // No auto-suggestion for investment schemes
    return null;
  }

  // ==================== GOAL DESCRIPTION SUGGESTION ====================

  static final Map<String, String> _goalDescriptionTemplates = {
    'emergency': 'Build emergency fund for unexpected expenses',
    'house': 'Save for house down payment',
    'home': 'Save for home purchase',
    'car': 'Save for car purchase',
    'vehicle': 'Save for vehicle purchase',
    'vacation': 'Save for vacation trip',
    'travel': 'Save for travel expenses',
    'wedding': 'Save for wedding expenses',
    'education': 'Save for education expenses',
    'retirement': 'Build retirement corpus',
    'laptop': 'Save for laptop purchase',
    'phone': 'Save for phone purchase',
    'gadget': 'Save for gadget purchase',
  };

  String? suggestGoalDescription(String name) {
    // Template matching
    final lowerName = name.toLowerCase();
    for (final keyword in _goalDescriptionTemplates.keys) {
      if (lowerName.contains(keyword)) {
        return _goalDescriptionTemplates[keyword]!;
      }
    }

    // 3. Default
    return null;
  }

  // ==================== BUDGET CATEGORY SUGGESTION ====================

  String? suggestBudgetCategory(String name) {
    // Keyword matching (reuse subscription keywords)
    final lowerName = name.toLowerCase();
    for (final keyword in _subscriptionCategoryKeywords.keys) {
      if (lowerName.contains(keyword)) {
        return _subscriptionCategoryKeywords[keyword]!;
      }
    }

    // 3. Extract category from name if it follows pattern "X Budget"
    if (lowerName.contains('budget')) {
      final parts = name.split(RegExp(r'\s+budget', caseSensitive: false));
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        // Capitalize first letter
        final categoryName = parts[0].trim();
        return categoryName[0].toUpperCase() + categoryName.substring(1);
      }
    }

    // 4. Default
    return 'Miscellaneous';
  }

  // ==================== ACCOUNT TYPE SUGGESTION ====================

  static final Map<String, String> _accountTypeKeywords = {
    'savings': 'Savings',
    'current': 'Current',
    'checking': 'Checking',
    'credit card': 'Credit Card',
    'wallet': 'Wallet',
    'paytm': 'Wallet',
    'phonepe': 'Wallet',
    'gpay': 'Wallet',
    'cash': 'Cash',
    'investment': 'Investment',
    'trading': 'Investment',
  };

  String? suggestAccountType(String name) {
    // Keyword matching
    final lowerName = name.toLowerCase();
    for (final keyword in _accountTypeKeywords.keys) {
      if (lowerName.contains(keyword)) {
        return _accountTypeKeywords[keyword]!;
      }
    }

    // 3. Default
    return null;
  }

  // ==================== TRANSACTION CATEGORY (Backward Compatibility) ====================

  static final Map<String, String> _transactionCategoryKeywords = {
    // Food & Dining
    'zomato': 'Food & Dining',
    'swiggy': 'Food & Dining',
    'ubereats': 'Food & Dining',
    'restaurant': 'Food & Dining',
    'foodpanda': 'Food & Dining',
    'cafe': 'Food & Dining',
    'dining': 'Food & Dining',

    // Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'e-com': 'Shopping',
    'marketplace': 'Shopping',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'rapido': 'Transportation',
    'metro': 'Transportation',
    'cab': 'Transportation',
    'taxi': 'Transportation',

    // Bills & Utilities
    'bill': 'Bills',
    'recharge': 'Bills',
    'utility': 'Bills',
    'electricity': 'Bills',
    'broadband': 'Bills',

    // Entertainment
    'bookmyshow': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'prime video': 'Entertainment',
    'hotstar': 'Entertainment',
    'youtube': 'Entertainment',

    // Healthcare
    'pharmacy': 'Healthcare',
    'apollo': 'Healthcare',
    'medplus': 'Healthcare',
    'hospital': 'Healthcare',
    'clinic': 'Healthcare',

    // Salary
    'salary': 'Salary',
    'stipend': 'Salary',

    // Investment
    'groww': 'Investment',
    'zerodha': 'Investment',
    'upstox': 'Investment',
    'sip': 'Investment',
    'mutual fund': 'Investment',
  };

  String suggestTransactionCategory(String description) {
    return SmartCategoryResolver.resolve(
      merchant: description,
      body: description,
      transactionType: 'expense',
    );
  }
}
