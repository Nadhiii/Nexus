class Investment {
  final String id;
  final String name; // Investment name (e.g., "HDFC Equity Fund", "Apple Inc.")
  final String symbol; // Stock symbol or fund code (e.g., "AAPL", "HDFCEQ")
  final InvestmentType type;
  final String accountId; // Which investment account this belongs to
  final double units; // Number of shares/units owned
  final double averagePrice; // Average purchase price per unit
  final double currentPrice; // Current market price per unit
  final double totalInvested; // Total amount invested
  final double currentValue; // Current market value (units * currentPrice)
  final String currency;
  final DateTime lastUpdated; // When price was last updated
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>?
  metadata; // Additional info (sector, fund house, etc.)

  Investment({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.accountId,
    required this.units,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalInvested,
    required this.currentValue,
    this.currency = '₹',
    required this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Calculate gain/loss amount
  double get gainLoss => currentValue - totalInvested;

  /// Calculate gain/loss percentage
  double get gainLossPercentage =>
      totalInvested > 0 ? (gainLoss / totalInvested) * 100 : 0.0;

  /// Check if investment is profitable
  bool get isProfitable => gainLoss > 0;

  /// Formatted gain/loss display
  String get formattedGainLoss {
    final sign = gainLoss >= 0 ? '+' : '';
    return '$sign$currency${gainLoss.toStringAsFixed(2)}';
  }

  /// Formatted percentage display
  String get formattedPercentage {
    final sign = gainLossPercentage >= 0 ? '+' : '';
    return '$sign${gainLossPercentage.toStringAsFixed(2)}%';
  }

  /// Formatted current value
  String get formattedCurrentValue =>
      '$currency${currentValue.toStringAsFixed(2)}';

  /// Formatted total invested
  String get formattedTotalInvested =>
      '$currency${totalInvested.toStringAsFixed(2)}';

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      type: InvestmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvestmentType.stock,
      ),
      accountId: map['accountId'],
      units: map['units']?.toDouble() ?? 0.0,
      averagePrice: map['averagePrice']?.toDouble() ?? 0.0,
      currentPrice: map['currentPrice']?.toDouble() ?? 0.0,
      totalInvested: map['totalInvested']?.toDouble() ?? 0.0,
      currentValue: map['currentValue']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '₹',
      lastUpdated: DateTime.parse(map['lastUpdated']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'type': type.name,
      'accountId': accountId,
      'units': units,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Investment copyWith({
    String? id,
    String? name,
    String? symbol,
    InvestmentType? type,
    String? accountId,
    double? units,
    double? averagePrice,
    double? currentPrice,
    double? totalInvested,
    double? currentValue,
    String? currency,
    DateTime? lastUpdated,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      units: units ?? this.units,
      averagePrice: averagePrice ?? this.averagePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      totalInvested: totalInvested ?? this.totalInvested,
      currentValue: currentValue ?? this.currentValue,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum InvestmentType {
  stock, // Individual stocks
  mutualFund, // Mutual funds
  etf, // Exchange-traded funds
  bond, // Bonds and fixed income
  crypto, // Cryptocurrency
  commodity, // Gold, silver, etc.
  reit, // Real estate investment trusts
  other, // Other investment types
}

extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.stock:
        return 'Stock';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.etf:
        return 'ETF';
      case InvestmentType.bond:
        return 'Bond';
      case InvestmentType.crypto:
        return 'Cryptocurrency';
      case InvestmentType.commodity:
        return 'Commodity';
      case InvestmentType.reit:
        return 'REIT';
      case InvestmentType.other:
        return 'Other';
    }
  }

  String get shortName {
    switch (this) {
      case InvestmentType.stock:
        return 'Stock';
      case InvestmentType.mutualFund:
        return 'MF';
      case InvestmentType.etf:
        return 'ETF';
      case InvestmentType.bond:
        return 'Bond';
      case InvestmentType.crypto:
        return 'Crypto';
      case InvestmentType.commodity:
        return 'Gold';
      case InvestmentType.reit:
        return 'REIT';
      case InvestmentType.other:
        return 'Other';
    }
  }
}

/// Investment transaction model for buy/sell operations
class InvestmentTransaction {
  final String id;
  final String investmentId;
  final InvestmentTransactionType type;
  final double units;
  final double pricePerUnit;
  final double amount; // Total transaction amount
  final double fees; // Brokerage/transaction fees
  final DateTime transactionDate;
  final String? notes;
  final DateTime createdAt;

  InvestmentTransaction({
    required this.id,
    required this.investmentId,
    required this.type,
    required this.units,
    required this.pricePerUnit,
    required this.amount,
    this.fees = 0.0,
    required this.transactionDate,
    this.notes,
    required this.createdAt,
  });

  factory InvestmentTransaction.fromMap(Map<String, dynamic> map) {
    return InvestmentTransaction(
      id: map['id'],
      investmentId: map['investmentId'],
      type: InvestmentTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvestmentTransactionType.buy,
      ),
      units: map['units']?.toDouble() ?? 0.0,
      pricePerUnit: map['pricePerUnit']?.toDouble() ?? 0.0,
      amount: map['amount']?.toDouble() ?? 0.0,
      fees: map['fees']?.toDouble() ?? 0.0,
      transactionDate: DateTime.parse(map['transactionDate']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investmentId': investmentId,
      'type': type.name,
      'units': units,
      'pricePerUnit': pricePerUnit,
      'amount': amount,
      'fees': fees,
      'transactionDate': transactionDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum InvestmentTransactionType {
  buy, // Purchase
  sell, // Sale
  dividend, // Dividend received
  bonus, // Bonus shares
  split, // Stock split
}
