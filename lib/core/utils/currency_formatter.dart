import 'package:intl/intl.dart';

/// Safe formatter for values crossing Firestore/JSON and UI boundaries.
class AppCurrency {
  AppCurrency._();

  static final NumberFormat _format = NumberFormat('#,##,##0.00', 'en_IN');

  static String format(Object? value) {
    final amount = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text.trim()),
      _ => null,
    };
    return _format.format(amount ?? 0);
  }
}

/// Compatibility helper for statically typed numeric code.
extension CurrencyFormatting on num {
  String toAppCurrency() => AppCurrency.format(this);
}
