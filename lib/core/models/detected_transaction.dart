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
  final String? bankName; // e.g., "IDFC FIRST Bank" - identified source bank
  final double?
  balanceAfter; // Account balance after this transaction, if the alert included one
  final String? accountNumber; // Last-4 digits of account/card, if present
  final Map<String, dynamic>? analysis; // Latest interpretation/evidence
  final String? matchedTransactionId;
  final String? statementImportId;

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
    this.bankName,
    this.balanceAfter,
    this.accountNumber,
    this.analysis,
    this.matchedTransactionId,
    this.statementImportId,
  });

  // Quick check for reliability
  bool get isHighConfidence => confidence >= 0.85;
  bool get isLowConfidence => confidence < 0.65;
  bool get needsReview => isLowConfidence || warnings.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fingerprint': fingerprint,
    'amount': amount,
    'merchant': merchant,
    'date': date.toIso8601String(),
    'type': type,
    'source': source,
    'body': body,
    'confidence': confidence,
    'warnings': warnings,
    'detectedCategory': detectedCategory,
    'bankName': bankName,
    'balanceAfter': balanceAfter,
    'accountNumber': accountNumber,
    'analysis': analysis,
    'matchedTransactionId': matchedTransactionId,
    'statementImportId': statementImportId,
  };

  factory DetectedTransaction.fromJson(Map<String, dynamic> json) {
    return DetectedTransaction(
      id: json['id'] as String,
      fingerprint: json['fingerprint'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      source: json['source'] as String,
      body: json['body'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      warnings: List<String>.from(json['warnings'] as List? ?? const []),
      detectedCategory: json['detectedCategory'] as String?,
      bankName: json['bankName'] as String?,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      accountNumber: json['accountNumber'] as String?,
      analysis: json['analysis'] != null
          ? Map<String, dynamic>.from(json['analysis'] as Map)
          : null,
      matchedTransactionId: json['matchedTransactionId'] as String?,
      statementImportId: json['statementImportId'] as String?,
    );
  }

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
    String? bankName,
    double? balanceAfter,
    String? accountNumber,
    Map<String, dynamic>? analysis,
    String? matchedTransactionId,
    String? statementImportId,
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
      bankName: bankName ?? this.bankName,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      accountNumber: accountNumber ?? this.accountNumber,
      analysis: analysis ?? this.analysis,
      matchedTransactionId: matchedTransactionId ?? this.matchedTransactionId,
      statementImportId: statementImportId ?? this.statementImportId,
    );
  }
}
