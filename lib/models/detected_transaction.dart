class DetectedTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String source; // e.g., bank/SMS sender
  final String smsBody; // Full SMS body for reference
  final String? category; // Auto-detected category

  const DetectedTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.source,
    required this.smsBody,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'date': date.toIso8601String(),
      'source': source,
      'smsBody': smsBody,
      'category': category,
    };
  }

  factory DetectedTransaction.fromMap(Map<String, dynamic> map) {
    return DetectedTransaction(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      amount: map['amount'].toDouble(),
      date: DateTime.parse(map['date']),
      source: map['source'],
      smsBody: map['smsBody'] ?? map['subtitle'], // Fallback to subtitle for old data
      category: map['category'],
    );
  }
}
