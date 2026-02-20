import 'package:flutter/foundation.dart';

@immutable
class NboxSettings {
  final bool smsReadingEnabled;

  const NboxSettings({this.smsReadingEnabled = true});

  NboxSettings copyWith({bool? smsReadingEnabled}) {
    return NboxSettings(
      smsReadingEnabled: smsReadingEnabled ?? this.smsReadingEnabled,
    );
  }

  Map<String, dynamic> toJson() => {'smsReadingEnabled': smsReadingEnabled};

  factory NboxSettings.fromJson(Map<String, dynamic> json) {
    return NboxSettings(smsReadingEnabled: json['smsReadingEnabled'] ?? true);
  }
}
