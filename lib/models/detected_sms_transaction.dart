/// A data class representing a transaction detected from an SMS message.
class DetectedSmsTransaction {
  /// A unique identifier for the source SMS message.
  final String smsId;

  /// The amount of the transaction.
  final double amount;

  /// The type of transaction (income or expense).
  final String type; // 'income' or 'expense'

  /// The date and time of the transaction, parsed from the SMS.
  final DateTime date;

  /// The name of the merchant or sender (e.g., "Apple Services").
  final String merchant;

  /// A flag indicating if this is a definitive transaction (e.g., "sent," "debited")
  /// versus a non-definitive one (e.g., "request," "due").
  final bool isDefinitive;

  /// The full, original body of the SMS for reference.
  final String smsBody;

  /// The original sender of the SMS (e.g., the bank's shortcode).
  final String sender;

  DetectedSmsTransaction({
    required this.smsId,
    required this.amount,
    required this.type,
    required this.date,
    required this.merchant,
    required this.isDefinitive,
    required this.smsBody,
    required this.sender,
  });
}
