import 'package:crypto/crypto.dart';
import '../models/pdf_statement.dart';
import '../models/transaction.dart';

/// Detects duplicates between PDF transactions and existing transactions
class DuplicateDetector {
  /// Signature-based duplicate detection
  /// Compares: date (within 1 day) + amount + merchant
  static DuplicateCheckResult checkDuplicate(
    ExtractedTransaction pdfTx,
    List<Transaction> existingTransactions,
  ) {
    for (final existing in existingTransactions) {
      final result = _compareTransactions(pdfTx, existing);
      if (result.isDuplicate) {
        return result;
      }
    }

    return DuplicateCheckResult(
      isDuplicate: false,
      confidenceScore: 0,
      reason: 'No matching transaction found',
    );
  }

  /// Compare two transactions for duplication
  static DuplicateCheckResult _compareTransactions(
    ExtractedTransaction pdfTx,
    Transaction existingTx,
  ) {
    final matchingFields = <String>[];
    double scorePoints = 0;

    // 1. Amount match (most important)
    if ((pdfTx.amount - existingTx.amount).abs() < 0.01) {
      matchingFields.add('amount');
      scorePoints += 40;
    } else if ((pdfTx.amount - existingTx.amount).abs() < 1.0) {
      // Close but not exact (might be after fees)
      scorePoints += 15;
    }

    // 2. Date match (within 1 day for processing delays)
    final pdfDate = DateTime.tryParse(pdfTx.date);
    if (pdfDate != null) {
      final daysDiff = existingTx.date.difference(pdfDate).inDays.abs();
      if (daysDiff == 0) {
        matchingFields.add('exact_date');
        scorePoints += 35;
      } else if (daysDiff <= 1) {
        matchingFields.add('date_±1day');
        scorePoints += 20;
      } else if (daysDiff <= 3) {
        scorePoints += 10;
      }
    }

    // 3. Merchant/Description match
    final pdfMerchant = pdfTx.description.toLowerCase().trim();
    final existingDescription = (existingTx.description ?? '')
        .toLowerCase()
        .trim();

    if (pdfMerchant == existingDescription) {
      matchingFields.add('exact_merchant');
      scorePoints += 25;
    } else if (_merchantSimilarity(pdfMerchant, existingDescription) > 0.8) {
      matchingFields.add('similar_merchant');
      scorePoints += 15;
    }

    // Decision: Consider duplicate if confidence >= 70%
    final confidence = scorePoints.clamp(0.0, 100.0);

    if (confidence >= 70 && matchingFields.length >= 2) {
      return DuplicateCheckResult(
        isDuplicate: true,
        matchingTransactionId: existingTx.id,
        confidenceScore: confidence,
        reason:
            'Found matching transaction with ${matchingFields.length} matching fields',
        matchingFields: matchingFields,
      );
    }

    return DuplicateCheckResult(
      isDuplicate: false,
      confidenceScore: confidence,
      reason: 'Below confidence threshold',
      matchingFields: matchingFields,
    );
  }

  /// Levenshtein distance-based string similarity (0-1)
  static double _merchantSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = [s1.length, s2.length].reduce((a, b) => a > b ? a : b);

    return 1.0 - (distance / maxLength);
  }

  /// Levenshtein distance algorithm
  static int _levenshteinDistance(String s1, String s2) {
    final list1 = s1.split('');
    final list2 = s2.split('');

    final distances = List<List<int>>.generate(
      list1.length + 1,
      (i) => List<int>.generate(list2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= list1.length; i++) {
      distances[i][0] = i;
    }
    for (int j = 0; j <= list2.length; j++) {
      distances[0][j] = j;
    }

    for (int i = 1; i <= list1.length; i++) {
      for (int j = 1; j <= list2.length; j++) {
        final cost = list1[i - 1] == list2[j - 1] ? 0 : 1;
        distances[i][j] = [
          distances[i - 1][j] + 1, // deletion
          distances[i][j - 1] + 1, // insertion
          distances[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return distances[list1.length][list2.length];
  }

  /// Batch check for duplicates
  static Future<Map<ExtractedTransaction, DuplicateCheckResult>> checkBatch(
    List<ExtractedTransaction> pdfTransactions,
    List<Transaction> existingTransactions,
  ) async {
    final results = <ExtractedTransaction, DuplicateCheckResult>{};

    for (final pdfTx in pdfTransactions) {
      results[pdfTx] = checkDuplicate(pdfTx, existingTransactions);
    }

    return results;
  }

  /// Hash file content for duplicate file detection
  static String hashPDFFile(List<int> fileBytes) {
    return sha256.convert(fileBytes).toString();
  }
}
