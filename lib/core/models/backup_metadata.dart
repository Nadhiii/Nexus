import 'package:cloud_firestore/cloud_firestore.dart';

class BackupMetadata {
  final String id;
  final DateTime createdAt;
  final DateTime? restoredAt;
  final int transactionCount;
  final String appVersion;
  final bool isAutomatic;
  final String notes;
  final Map<String, dynamic> dataInfo;

  BackupMetadata({
    required this.id,
    required this.createdAt,
    this.restoredAt,
    required this.transactionCount,
    required this.appVersion,
    this.isAutomatic = false,
    this.notes = '',
    required this.dataInfo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': Timestamp.fromDate(createdAt),
    'restoredAt': restoredAt != null ? Timestamp.fromDate(restoredAt!) : null,
    'transactionCount': transactionCount,
    'appVersion': appVersion,
    'isAutomatic': isAutomatic,
    'notes': notes,
    'dataInfo': dataInfo,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    id: json['id'] as String,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    restoredAt: json['restoredAt'] != null
        ? (json['restoredAt'] as Timestamp).toDate()
        : null,
    transactionCount: json['transactionCount'] as int,
    appVersion: json['appVersion'] as String,
    isAutomatic: json['isAutomatic'] as bool? ?? false,
    notes: json['notes'] as String? ?? '',
    dataInfo: json['dataInfo'] as Map<String, dynamic>? ?? {},
  );
}

class BackupData {
  final List<Map<String, dynamic>> transactions;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> appState;

  BackupData({
    required this.transactions,
    required this.settings,
    required this.appState,
  });

  Map<String, dynamic> toJson() => {
    'transactions': transactions,
    'settings': settings,
    'appState': appState,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    transactions: List<Map<String, dynamic>>.from(
      json['transactions'] as List? ?? [],
    ),
    settings: json['settings'] as Map<String, dynamic>? ?? {},
    appState: json['appState'] as Map<String, dynamic>? ?? {},
  );
}

class RestoreConflictResolution {
  final bool mergeTransactions;
  final bool overwriteSettings;
  final bool overwriteAppState;

  RestoreConflictResolution({
    this.mergeTransactions = true,
    this.overwriteSettings = false,
    this.overwriteAppState = false,
  });
}
