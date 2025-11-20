import 'package:flutter/material.dart';
import 'learning_service.dart';

/// A service to automatically suggest a category for a transaction based on its description.
class TransactionCategorizationService {
  final LearningService _learningService;

  TransactionCategorizationService(this._learningService);

  // A map of keywords to their corresponding category ID.
  // Keywords are checked in a case-insensitive manner.
  static final Map<String, String> _keywordCategoryMap = {
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

  /// Suggests a category based on the transaction description.
  ///
  /// Returns a category ID (e.g., 'Food & Dining') or falls back to 'Miscellaneous'.
  String suggestCategory(String description) {
    // 1. Check for a learned category first
    final learnedCategory = _learningService.suggest(description);
    if (learnedCategory != null) {
      return learnedCategory;
    }

    // 2. Fallback to keyword matching
    final lowerCaseDescription = description.toLowerCase();
    for (final keyword in _keywordCategoryMap.keys) {
      if (lowerCaseDescription.contains(keyword)) {
        return _keywordCategoryMap[keyword]!;
      }
    }

    // 3. If no match, return 'Miscellaneous'
    return 'Miscellaneous';
  }
}
