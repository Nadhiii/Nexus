import 'package:cloud_firestore/cloud_firestore.dart';

class Crypto {
  final String id;
  final String userId;
  final String cryptoId; // CoinGecko ID (e.g., 'bitcoin', 'ethereum')
  final String name; // User-defined name (e.g., "My BTC Investment")
  final String symbol; // Crypto symbol (e.g., 'BTC', 'ETH')
  final double amount; // Amount of crypto owned
  final double purchasePrice; // Purchase price per unit in USD
  final DateTime purchaseDate;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated fields (not stored in Firestore)
  double? currentPrice; // Fetched from CoinGecko
  double? currentValue; // amount * currentPrice
  double? investedAmount; // amount * purchasePrice
  double? gainLoss; // currentValue - investedAmount
  double? gainLossPercentage; // (gainLoss / investedAmount) * 100

  Crypto({
    required this.id,
    required this.userId,
    required this.cryptoId,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.purchasePrice,
    required this.purchaseDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.currentPrice,
    this.currentValue,
    this.investedAmount,
    this.gainLoss,
    this.gainLossPercentage,
  });

  factory Crypto.fromFirestore(DocumentSnapshot doc) {
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

    return Crypto(
      id: doc.id,
      userId: data['userId'],
      cryptoId: data['cryptoId'],
      name: data['name'],
      symbol: data['symbol'],
      amount: (data['amount'] ?? 0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      purchaseDate: parseDate(data['purchaseDate']),
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'cryptoId': cryptoId,
    'name': name,
    'symbol': symbol,
    'amount': amount,
    'purchasePrice': purchasePrice,
    'purchaseDate': Timestamp.fromDate(purchaseDate),
    'notes': notes,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Crypto copyWith({
    String? id,
    String? userId,
    String? cryptoId,
    String? name,
    String? symbol,
    double? amount,
    double? purchasePrice,
    DateTime? purchaseDate,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentPrice,
    double? currentValue,
    double? investedAmount,
    double? gainLoss,
    double? gainLossPercentage,
  }) {
    return Crypto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cryptoId: cryptoId ?? this.cryptoId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      amount: amount ?? this.amount,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPrice: currentPrice ?? this.currentPrice,
      currentValue: currentValue ?? this.currentValue,
      investedAmount: investedAmount ?? this.investedAmount,
      gainLoss: gainLoss ?? this.gainLoss,
      gainLossPercentage: gainLossPercentage ?? this.gainLossPercentage,
    );
  }
}
