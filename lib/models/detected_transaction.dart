import 'package:flutter/foundation.dart';

@immutable
class DetectedTransaction {
  final String id; // Unique ID (SMS ID or Email ID)
  final double amount;
  final String merchant;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String source; // 'sms' or 'email'
  final String? body; // Full SMS or Email body

  const DetectedTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.source,
    this.body,
  });

  @override
bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          source == other.source;

  @override
int get hashCode => id.hashCode ^ source.hashCode;

  DetectedTransaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    DateTime? date,
    String? type,
    String? source,
    String? body,
  }) {
    return DetectedTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      type: type ?? this.type,
      source: source ?? this.source,
      body: body ?? this.body,
    );
  }
}
