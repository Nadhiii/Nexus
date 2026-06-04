import 'package:flutter/foundation.dart';

@immutable
class DetectedTransaction {
  final String id; // Unique ID (SMS ID or Email ID)
  final String fingerprint; // Content-based hash, survives reinstall
  final double amount;
  final String merchant;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String source; // 'sms' or 'email'
  final String? body; // Full SMS or Email body
  final double confidence; // 0.0 to 1.0, higher = more reliable
  final List<String>
  warnings; // e.g., ["Merchant unclear", "Amount incomplete"]
  final String? detectedCategory; // Auto-detected category, if any

  const DetectedTransaction({
    required this.id,
    required this.fingerprint,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.type,
    required this.source,
    this.body,
    this.confidence = 0.8,
    this.warnings = const [],
    this.detectedCategory,
  });

  // Quick check for reliability
  bool get isHighConfidence => confidence >= 0.85;
  bool get isLowConfidence => confidence < 0.65;
  bool get needsReview => isLowConfidence || warnings.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedTransaction &&
          runtimeType == other.runtimeType &&
          fingerprint == other.fingerprint &&
          source == other.source;

  @override
  int get hashCode => fingerprint.hashCode ^ source.hashCode;

  DetectedTransaction copyWith({
    String? id,
    String? fingerprint,
    double? amount,
    String? merchant,
    DateTime? date,
    String? type,
    String? source,
    String? body,
    double? confidence,
    List<String>? warnings,
    String? detectedCategory,
  }) {
    return DetectedTransaction(
      id: id ?? this.id,
      fingerprint: fingerprint ?? this.fingerprint,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      type: type ?? this.type,
      source: source ?? this.source,
      body: body ?? this.body,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      detectedCategory: detectedCategory ?? this.detectedCategory,
    );
  }
}
