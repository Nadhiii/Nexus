class ExtractedTransaction {
  final String date;
  final String description;
  final double amount;
  final String type; // 'income' or 'expense'
  final int lineNumber;
  final String? category; // Optional: Food, Travel, etc.

  ExtractedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.lineNumber = 0,
    this.category,
  });

  /// Helper factory to create from JSON (useful if passing data between isolates/services)
  factory ExtractedTransaction.fromJson(Map<String, dynamic> json) {
    return ExtractedTransaction(
      date: json['date'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String?,
      lineNumber: json['line_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'line_number': lineNumber,
    };
  }

  @override
  String toString() {
    return 'ExtractedTransaction(date: $date, desc: $description, amount: $amount, type: $type)';
  }
}
