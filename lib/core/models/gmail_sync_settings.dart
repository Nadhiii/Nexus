import 'package:flutter/foundation.dart';

enum SyncFrequency {
  manual(0, 'Manual'),
  sixHours(6, 'Every 6 Hours'),
  twelveHours(12, 'Every 12 Hours'),
  daily(24, 'Daily');

  final int hours;
  final String displayName;

  const SyncFrequency(this.hours, this.displayName);

  Duration get interval => Duration(hours: hours);
}

@immutable
class GmailSyncSettings {
  final bool autoSyncEnabled;
  final SyncFrequency syncFrequency;
  final int daysToScan; // 7, 14, 30, 90
  final bool scanPromotions;
  final bool scanSocial;
  final List<String> excludedSenders;
  final bool autoApproveLowValue; // Auto-approve transactions < ₹500
  final bool autoApproveHighConfidence; // Auto-approve confidence >= 90%

  const GmailSyncSettings({
    this.autoSyncEnabled = false,
    this.syncFrequency = SyncFrequency.manual,
    this.daysToScan = 30,
    this.scanPromotions = false,
    this.scanSocial = false,
    this.excludedSenders = const [],
    this.autoApproveLowValue = false,
    this.autoApproveHighConfidence = false,
  });

  GmailSyncSettings copyWith({
    bool? autoSyncEnabled,
    SyncFrequency? syncFrequency,
    int? daysToScan,
    bool? scanPromotions,
    bool? scanSocial,
    List<String>? excludedSenders,
    bool? autoApproveLowValue,
    bool? autoApproveHighConfidence,
  }) {
    return GmailSyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      daysToScan: daysToScan ?? this.daysToScan,
      scanPromotions: scanPromotions ?? this.scanPromotions,
      scanSocial: scanSocial ?? this.scanSocial,
      excludedSenders: excludedSenders ?? this.excludedSenders,
      autoApproveLowValue: autoApproveLowValue ?? this.autoApproveLowValue,
      autoApproveHighConfidence:
          autoApproveHighConfidence ?? this.autoApproveHighConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoSyncEnabled': autoSyncEnabled,
    'syncFrequency': syncFrequency.name,
    'daysToScan': daysToScan,
    'scanPromotions': scanPromotions,
    'scanSocial': scanSocial,
    'excludedSenders': excludedSenders,
    'autoApproveLowValue': autoApproveLowValue,
    'autoApproveHighConfidence': autoApproveHighConfidence,
  };

  factory GmailSyncSettings.fromJson(Map<String, dynamic> json) {
    return GmailSyncSettings(
      autoSyncEnabled: json['autoSyncEnabled'] ?? false,
      syncFrequency: SyncFrequency.values.firstWhere(
        (e) => e.name == json['syncFrequency'],
        orElse: () => SyncFrequency.manual,
      ),
      daysToScan: json['daysToScan'] ?? 30,
      scanPromotions: json['scanPromotions'] ?? false,
      scanSocial: json['scanSocial'] ?? false,
      excludedSenders: List<String>.from(json['excludedSenders'] ?? []),
      autoApproveLowValue: json['autoApproveLowValue'] ?? false,
      autoApproveHighConfidence: json['autoApproveHighConfidence'] ?? false,
    );
  }
}
