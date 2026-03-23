import 'smart_category_resolver.dart';

/// A service to automatically suggest a category for a transaction based on its description.
class TransactionCategorizationService {
  TransactionCategorizationService();

  /// Suggests a category based on the transaction description.
  /// Returns a valid category id.
  String suggestCategory(String description) {
    return SmartCategoryResolver.resolve(
      merchant: description,
      body: description,
      transactionType: 'expense',
    );
  }
}
