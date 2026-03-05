import 'package:crypto/crypto.dart';
import '../models/pdf_statement.dart';
import '../models/transaction.dart';

class DuplicateDetector {
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

  static DuplicateCheckResult _compareTransactions(
    ExtractedTransaction pdfTx,
    Transaction existingTx,
  ) {
    final matchingFields = <String>[];
    double scorePoints = 0;

    // 1. Amount match (Absolute check)
    if ((pdfTx.amount - existingTx.amount.abs()).abs() < 0.01) {
      matchingFields.add('amount');
      scorePoints += 40;
    } else if ((pdfTx.amount - existingTx.amount.abs()).abs() < 1.0) {
      scorePoints += 15;
    }

    // 2. Date match (Ignore Time)
    final pdfDate = DateTime.tryParse(pdfTx.date);
    if (pdfDate != null) {
      final d1 = DateTime.utc(pdfDate.year, pdfDate.month, pdfDate.day);
      final d2 = DateTime.utc(
        existingTx.date.year,
        existingTx.date.month,
        existingTx.date.day,
      );

      final daysDiff = d1.difference(d2).inDays.abs();
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

    // 3. Merchant match
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

    final confidence = scorePoints.clamp(0.0, 100.0);

    if (confidence >= 70 && matchingFields.length >= 2) {
      // Check if Type Mismatch (e.g. Existing=Income, PDF=Debit/Expense)
      final pdfIsExpense =
          pdfTx.type.toLowerCase() == 'debit' ||
          pdfTx.type.toLowerCase() == 'expense';
      final existingIsExpense = existingTx.type == TransactionType.expense;

      final needsTypeUpdate = pdfIsExpense != existingIsExpense;

      return DuplicateCheckResult(
        isDuplicate: true,
        matchingTransactionId: existingTx.id,
        confidenceScore: confidence,
        reason: needsTypeUpdate ? 'Type mismatch' : 'Duplicate found',
        matchingFields: matchingFields,
        needsTypeUpdate: needsTypeUpdate,
      );
    }

    return DuplicateCheckResult(
      isDuplicate: false,
      confidenceScore: confidence,
      reason: 'Below threshold',
      matchingFields: matchingFields,
    );
  }

  static double _merchantSimilarity(String s1, String s2) {
    if (s1 == s2) { return 1.0; }
    if (s1.isEmpty || s2.isEmpty) { return 0.0; }
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = [s1.length, s2.length].reduce((a, b) => a > b ? a : b);
    return 1.0 - (distance / maxLength);
  }

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
          distances[i - 1][j] + 1,
          distances[i][j - 1] + 1,
          distances[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return distances[list1.length][list2.length];
  }

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

  static String hashPDFFile(List<int> fileBytes) {
    return sha256.convert(fileBytes).toString();
  }
}
