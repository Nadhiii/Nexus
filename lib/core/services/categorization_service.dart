import 'package:flutter/foundation.dart';
import '../providers/category_provider.dart';
import 'smart_category_resolver.dart';

/// Result of AI categorization suggestion
class CategorySuggestion {
  final String category;
  final double confidence; // 0.0 to 1.0
  final String? reasoning; // AI explanation (optional)
  final bool isAiGenerated; // true if AI used, false if fallback

  CategorySuggestion({
    required this.category,
    required this.confidence,
    this.reasoning,
    required this.isAiGenerated,
  });
}

/// AI-powered transaction categorization service with graceful fallback
class AICategorizationService {
  final CategoryProvider categoryProvider;

  // Cache to avoid repeated lookups for same merchant
  final Map<String, CategorySuggestion> _cache = {};

  AICategorizationService({required this.categoryProvider});

  /// Suggest category for a transaction using keyword matching only
  Future<CategorySuggestion> suggestCategory({
    required String merchantName,
    String? description,
    required double amount,
    required String transactionType,
    String? fullMessageBody,
  }) async {
    // amount is included because SmartCategoryResolver uses it as a
    // fallback signal (e.g. amount <= 50 -> food, recharge-shaped
    // amounts -> bills) when merchant/body don't match anything. Without
    // it here, the first amount seen for a given merchant+description+
    // type gets cached and wrongly reused for every later amount.
    final cacheKey = '$merchantName|$description|$transactionType|$amount'
        .toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      debugPrint('[AICategorizationService] Cache hit for: $merchantName');
      return _cache[cacheKey]!;
    }

    final category = SmartCategoryResolver.resolve(
      merchant: merchantName,
      body: fullMessageBody ?? description,
      amount: amount,
      transactionType: transactionType,
    );
    final suggestion = CategorySuggestion(
      category: category,
      confidence: 0.6,
      reasoning: 'Keyword matching',
      isAiGenerated: false,
    );

    _cache[cacheKey] = suggestion;
    return suggestion;
  }

  // AI-based helpers removed — categorization uses keyword fallback only.

  /// Normalize merchant name using AI (removes transaction IDs, clean format)
  Future<String> normalizeMerchantName(String rawMerchant) async {
    // Simple regex cleaning as fallback
    String cleaned = rawMerchant
        .replaceAll(RegExp(r'\*[A-Z0-9]+'), '') // Remove *ABC123 patterns
        .replaceAll(RegExp(r'\s{2,}'), ' ') // Remove extra spaces
        .trim();
    return cleaned;
  }

  /// Clear cache (call when categories change)
  void clearCache() {
    _cache.clear();
    debugPrint('[AICategorizationService] Cache cleared');
  }

  /// Get cache size for debugging
  int get cacheSize => _cache.length;
}