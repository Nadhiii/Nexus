import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../modules/Nex/providers/Nex_assistant_provider.dart';
import '../providers/category_provider.dart';
import 'transaction_categorization_service.dart';

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
  final AIAssistantProvider? aiProvider;
  final CategoryProvider categoryProvider;
  final TransactionCategorizationService _fallbackService;

  // Cache to avoid repeated API calls for same merchant
  final Map<String, CategorySuggestion> _cache = {};

  AICategorizationService({this.aiProvider, required this.categoryProvider})
    : _fallbackService = TransactionCategorizationService();

  /// Suggest category for a transaction using AI or fallback to keyword matching
  Future<CategorySuggestion> suggestCategory({
    required String merchantName,
    String? description,
    required double amount,
    required String transactionType,
    String? fullMessageBody,
  }) async {
    // Check cache first
    final cacheKey = '$merchantName|$description|$transactionType'
        .toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      debugPrint('[AICategorizationService] Cache hit for: $merchantName');
      return _cache[cacheKey]!;
    }

    // Try AI if available
    if (aiProvider != null && aiProvider!.isReady) {
      try {
        debugPrint('[AICategorizationService] Using AI for: $merchantName');
        final aiSuggestion =
            await _categorizeWithAI(
              merchantName: merchantName,
              description: description,
              amount: amount,
              transactionType: transactionType,
              fullMessageBody: fullMessageBody,
            ).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint(
                  '[AICategorizationService] AI timeout, using fallback',
                );
                throw TimeoutException('AI categorization timed out');
              },
            );

        // Cache result
        _cache[cacheKey] = aiSuggestion;
        return aiSuggestion;
      } catch (e) {
        debugPrint(
          '[AICategorizationService] AI categorization failed: $e, falling back to keywords',
        );
      }
    } else {
      debugPrint(
        '[AICategorizationService] AI not ready, using keyword fallback',
      );
    }

    // Fallback to keyword matching
    final category = _fallbackService.suggestCategory(merchantName);
    final suggestion = CategorySuggestion(
      category: category,
      confidence: 0.6, // Lower confidence for keyword matching
      reasoning: 'Keyword matching',
      isAiGenerated: false,
    );

    _cache[cacheKey] = suggestion;
    return suggestion;
  }

  /// Categorize using AI model
  Future<CategorySuggestion> _categorizeWithAI({
    required String merchantName,
    required String? description,
    required double amount,
    required String transactionType,
    String? fullMessageBody,
  }) async {
    // Get available categories
    final categories = categoryProvider.categories.map((c) => c.name).toList();

    if (categories.isEmpty) {
      // No categories available, use default
      return CategorySuggestion(
        category: 'Miscellaneous',
        confidence: 0.5,
        reasoning: 'No categories available',
        isAiGenerated: false,
      );
    }

    // Build AI prompt
    final prompt =
        '''
You are a financial transaction categorization expert for an Indian personal finance app.

Categorize this transaction:
- Merchant: $merchantName
- Description: ${description ?? 'N/A'}
- Amount: ₹${amount.toStringAsFixed(2)}
- Type: $transactionType${fullMessageBody != null ? '\n- Context: ${fullMessageBody.length > 500 ? fullMessageBody.substring(0, 500) : fullMessageBody}' : ''}

Available categories:
${categories.join(', ')}

IMPORTANT RULES:
1. Return ONLY valid JSON, no extra text before or after
2. Use EXACT category name from the list above
3. If uncertain, use "Miscellaneous"
4. Consider Indian context (UPI, local merchants)

Return this exact JSON format:
{
  "category": "exact category name from list",
  "confidence": 0.85,
  "reasoning": "brief 1-sentence explanation"
}
''';

    // Call AI service (raw prompt - no conversation history needed)
    final response = await aiProvider!.sendRawPrompt(prompt);

    // Parse JSON response
    final parsed = _parseAIResponse(response, categories);

    return CategorySuggestion(
      category: parsed['category'] ?? 'Miscellaneous',
      confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.7,
      reasoning: parsed['reasoning'],
      isAiGenerated: true,
    );
  }

  /// Parse AI response and validate category
  Map<String, dynamic> _parseAIResponse(
    String response,
    List<String> availableCategories,
  ) {
    try {
      // Extract JSON from response (AI might include extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        debugPrint('[AICategorizationService] No JSON found in AI response');
        return {'category': 'Miscellaneous', 'confidence': 0.5};
      }

      final jsonStr = jsonMatch.group(0)!;
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate category exists in available categories
      final suggestedCategory = parsed['category'] as String?;
      if (suggestedCategory != null &&
          availableCategories.contains(suggestedCategory)) {
        return parsed;
      }

      // Try case-insensitive match
      if (suggestedCategory != null) {
        final matchedCategory = availableCategories.firstWhere(
          (cat) => cat.toLowerCase() == suggestedCategory.toLowerCase(),
          orElse: () => 'Miscellaneous',
        );
        parsed['category'] = matchedCategory;
        return parsed;
      }

      debugPrint(
        '[AICategorizationService] Invalid category in AI response: $suggestedCategory',
      );
      return {'category': 'Miscellaneous', 'confidence': 0.5};
    } catch (e) {
      debugPrint('[AICategorizationService] Failed to parse AI response: $e');
      return {'category': 'Miscellaneous', 'confidence': 0.5};
    }
  }

  /// Normalize merchant name using AI (removes transaction IDs, clean format)
  Future<String> normalizeMerchantName(String rawMerchant) async {
    // Simple regex cleaning as fallback
    String cleaned = rawMerchant
        .replaceAll(RegExp(r'\*[A-Z0-9]+'), '') // Remove *ABC123 patterns
        .replaceAll(RegExp(r'\s{2,}'), ' ') // Remove extra spaces
        .trim();

    // If AI available, use it for better normalization
    if (aiProvider != null && aiProvider!.isReady) {
      try {
        final prompt =
            '''
Normalize this merchant name by removing transaction IDs and cleaning format:
"$rawMerchant"

Return ONLY the clean merchant name, nothing else.
Examples:
- "ZOMATO*ORDER123" → "Zomato"
- "AMZ*Amazon.in" → "Amazon"
- "GOOGLE *YouTubePrem" → "YouTube Premium"
''';

        final response = await aiProvider!
            .sendRawPrompt(prompt)
            .timeout(const Duration(seconds: 3));

        return response.trim();
      } catch (e) {
        debugPrint(
          '[AICategorizationService] Merchant normalization failed: $e',
        );
      }
    }

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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
