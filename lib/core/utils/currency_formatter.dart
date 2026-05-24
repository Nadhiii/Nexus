import 'package:intl/intl.dart';

extension CurrencyFormatting on double {
  /// Formats a double to currency standard.
  /// If it's an exact integer, it hides the decimals (e.g., 100).
  /// If it has decimals, it preserves exactly 2 decimal places (e.g., 100.50).
  String toAppCurrency() {
    if (this == truncateToDouble()) {
      return NumberFormat('#,##,##0', 'en_IN').format(this);
    } else {
      return NumberFormat('#,##,##0.00', 'en_IN').format(this);
    }
  }
}
