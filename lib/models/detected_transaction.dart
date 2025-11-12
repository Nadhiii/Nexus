class DetectedTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String source;
  final String smsBody;
  final String? category;
  final String type;
  final bool isDefinitive;

  const DetectedTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.source,
    required this.smsBody,
    this.category,
    required this.type,
    this.isDefinitive = false,
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
      'type': type,
      'isDefinitive': isDefinitive,
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
      smsBody: map['smsBody'] ?? map['subtitle'],
      category: map['category'],
      type: map['type'] ?? 'expense',
      isDefinitive: map['isDefinitive'] ?? false,
    );
  }
}
