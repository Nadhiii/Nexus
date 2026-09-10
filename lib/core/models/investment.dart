import 'package:cloud_firestore/cloud_firestore.dart';

enum InvestmentType { mutualFund, stock, crypto, gold, realEstate, other }

class Investment {
  final String id;
  final String userId;
  final String name;
  final InvestmentType type;

  // Specific to Mutual Funds (Nullable now)
  final String? mutualFundSchemeCode;
  final String? mutualFundSchemeName;
  final String? folioNumber;
  final double sipAmount; // 0 if not SIP
  final int sipDay; // 0 if not SIP

  // Generic Fields
  final double investedAmount;
  final double currentAmount; // Current Value
  final double quantity; // Units
  final double purchasePrice; // Avg price per unit

  final DateTime startDate;
  final DateTime lastUpdated;
  final bool isActive;
  final String? notes;

  // Symbol for Stocks/Crypto (e.g. AAPL, BTC)
  final String? symbol;

  Investment({
    required this.id,
    required this.userId,
    required this.name,
    this.type = InvestmentType.mutualFund, // Default for backward compatibility
    this.mutualFundSchemeCode,
    this.mutualFundSchemeName,
    this.folioNumber,
    this.sipAmount = 0.0,
    this.sipDay = 0,
    required this.investedAmount,
    required this.currentAmount,
    required this.quantity,
    required this.purchasePrice,
    required this.startDate,
    required this.lastUpdated,
    this.isActive = true,
    this.notes,
    this.symbol,
  });

  // Smart Getters
  double get totalProfit => currentAmount - investedAmount;
  double get profitPercent =>
      investedAmount > 0 ? (totalProfit / investedAmount) * 100 : 0.0;
  bool get isProfitable => totalProfit >= 0;

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle Dates
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      }
      if (val is String) {
        return DateTime.parse(val);
      }
      return DateTime.now();
    }

    // Determine Type (Fallback to MutualFund for old data)
    InvestmentType parseType(String? typeStr) {
      if (typeStr == null) {
        return InvestmentType.mutualFund;
      }
      return InvestmentType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => InvestmentType.other,
      );
    }

    return Investment(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? data['mutualFundSchemeName'] ?? 'Unknown Asset',
      type: parseType(data['type']),
      mutualFundSchemeCode: data['mutualFundSchemeCode'],
      mutualFundSchemeName: data['mutualFundSchemeName'],
      folioNumber: data['folioNumber'],
      sipAmount: (data['sipAmount'] ?? 0).toDouble(),
      sipDay: data['sipDay'] ?? 0,
      investedAmount: (data['investedAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentValue'] ?? data['currentAmount'] ?? 0)
          .toDouble(),
      quantity: (data['units'] ?? data['quantity'] ?? 0).toDouble(),
      purchasePrice: (data['purchaseNav'] ?? data['purchasePrice'] ?? 0)
          .toDouble(),
      startDate: parseDate(data['startDate']),
      lastUpdated: parseDate(data['updatedAt'] ?? data['lastUpdated']),
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      symbol: data['symbol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'mutualFundSchemeCode': mutualFundSchemeCode,
      'mutualFundSchemeName': mutualFundSchemeName,
      'folioNumber': folioNumber,
      'sipAmount': sipAmount,
      'sipDay': sipDay,
      'investedAmount': investedAmount,
      'currentAmount': currentAmount, // Standardized key
      'currentValue': currentAmount, // Keep for backward compat if needed
      'quantity': quantity,
      'units': quantity, // Keep for backward compat
      'purchasePrice': purchasePrice,
      'purchaseNav': purchasePrice, // Keep for backward compat
      'startDate': Timestamp.fromDate(startDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedAt': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
      'notes': notes,
      'symbol': symbol,
    };
  }

  // Helper for JSON serialization if needed
  Map<String, dynamic> toJson() => toMap();

  // Helper copyWith
  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    InvestmentType? type,
    String? mutualFundSchemeCode,
    String? mutualFundSchemeName,
    double? sipAmount,
    int? sipDay,
    double? investedAmount,
    double? currentAmount,
    double? quantity,
    double? purchasePrice,
    DateTime? startDate,
    DateTime? lastUpdated,
    bool? isActive,
    String? notes,
    String? folioNumber,
    String? symbol,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      mutualFundSchemeCode: mutualFundSchemeCode ?? this.mutualFundSchemeCode,
      mutualFundSchemeName: mutualFundSchemeName ?? this.mutualFundSchemeName,
      sipAmount: sipAmount ?? this.sipAmount,
      sipDay: sipDay ?? this.sipDay,
      investedAmount: investedAmount ?? this.investedAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      folioNumber: folioNumber ?? this.folioNumber,
      symbol: symbol ?? this.symbol,
    );
  }
}
