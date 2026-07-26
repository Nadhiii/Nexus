import '../../models/detected_transaction.dart';

abstract class BankStatementParser {
  String get bankLabel;
  bool canParse(String rawText);
  List<DetectedTransaction> parse(String rawText, String sourceFileName);

  String makeFingerprint(DateTime date, double amount, String merchant) {
    final key = '${date.toIso8601String()}|${amount.toStringAsFixed(2)}|$merchant';
    return key.hashCode.toRadixString(16);
  }

  double parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('₹', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}