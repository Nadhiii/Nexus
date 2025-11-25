import 'package:cloud_firestore/cloud_firestore.dart';

class MutualFund {
  final String schemeCode;
  final String schemeName;

  MutualFund({required this.schemeCode, required this.schemeName});

  factory MutualFund.fromJson(Map<String, dynamic> json) {
    return MutualFund(
      schemeCode: json['schemeCode'].toString(), // Always parse as a string
      schemeName: json['schemeName'],
    );
  }
}

class Investment {
  final String id;
  final String userId;
  final String name; // e.g., "My SIP in TATA Digital"
  final String mutualFundSchemeCode;
  final String mutualFundSchemeName;
  final double sipAmount;
  final int sipDay;
  final DateTime startDate;
  final double purchaseNav; // NAV at time of purchase
  final double units; // Total units owned
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated fields (not stored in Firestore)
  double? currentNav; // Fetched from API
  double? currentValue; // units * currentNav
  double? investedAmount; // Total amount invested
  double? gainLoss; // currentValue - investedAmount
  double? gainLossPercentage; // (gainLoss / investedAmount) * 100

  Investment({
    required this.id,
    required this.userId,
    required this.name,
    required this.mutualFundSchemeCode,
    required this.mutualFundSchemeName,
    required this.sipAmount,
    required this.sipDay,
    required this.startDate,
    required this.purchaseNav,
    required this.units,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.currentNav,
    this.currentValue,
    this.investedAmount,
    this.gainLoss,
    this.gainLossPercentage,
  });

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    // Helper function to parse date fields (handles both Timestamp and String)
    DateTime parseDate(dynamic dateField) {
      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is String) {
        return DateTime.parse(dateField);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    return Investment(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      mutualFundSchemeCode: data['mutualFundSchemeCode'],
      mutualFundSchemeName: data['mutualFundSchemeName'],
      sipAmount: (data['sipAmount'] ?? 0).toDouble(),
      sipDay: data['sipDay'],
      startDate: parseDate(data['startDate']),
      purchaseNav: (data['purchaseNav'] ?? 0).toDouble(),
      units: (data['units'] ?? 0).toDouble(),
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'mutualFundSchemeCode': mutualFundSchemeCode,
    'mutualFundSchemeName': mutualFundSchemeName,
    'sipAmount': sipAmount,
    'sipDay': sipDay,
    'startDate': Timestamp.fromDate(startDate),
    'purchaseNav': purchaseNav,
    'units': units,
    'notes': notes,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    String? mutualFundSchemeCode,
    String? mutualFundSchemeName,
    double? sipAmount,
    int? sipDay,
    DateTime? startDate,
    double? purchaseNav,
    double? units,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentNav,
    double? currentValue,
    double? investedAmount,
    double? gainLoss,
    double? gainLossPercentage,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mutualFundSchemeCode: mutualFundSchemeCode ?? this.mutualFundSchemeCode,
      mutualFundSchemeName: mutualFundSchemeName ?? this.mutualFundSchemeName,
      sipAmount: sipAmount ?? this.sipAmount,
      sipDay: sipDay ?? this.sipDay,
      startDate: startDate ?? this.startDate,
      purchaseNav: purchaseNav ?? this.purchaseNav,
      units: units ?? this.units,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentNav: currentNav ?? this.currentNav,
      currentValue: currentValue ?? this.currentValue,
      investedAmount: investedAmount ?? this.investedAmount,
      gainLoss: gainLoss ?? this.gainLoss,
      gainLossPercentage: gainLossPercentage ?? this.gainLossPercentage,
    );
  }
}
