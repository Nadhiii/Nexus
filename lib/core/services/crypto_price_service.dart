import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto.dart';

class CryptoPriceService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  /// Fetch current price for a cryptocurrency in INR
  /// [cryptoId] should be CoinGecko ID (e.g., 'bitcoin', 'ethereum')
  Future<double?> getCurrentPrice(String cryptoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/simple/price?ids=$cryptoId&vs_currencies=inr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[cryptoId] != null) {
          return (data[cryptoId]['inr'] as num).toDouble();
        }
      }
    } catch (e) {
      print('Error fetching price for $cryptoId: $e');
    }
    return null;
  }

  /// Fetch prices for multiple cryptocurrencies at once
  Future<Map<String, double>> getBatchPrices(List<String> cryptoIds) async {
    final Map<String, double> prices = {};

    if (cryptoIds.isEmpty) return prices;

    try {
      final idsString = cryptoIds.join(',');
      final response = await http.get(
        Uri.parse('$baseUrl/simple/price?ids=$idsString&vs_currencies=inr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        for (var cryptoId in cryptoIds) {
          if (data[cryptoId] != null && data[cryptoId]['inr'] != null) {
            prices[cryptoId] = (data[cryptoId]['inr'] as num).toDouble();
          }
        }
      }
    } catch (e) {
      print('Error fetching batch prices: $e');
    }

    return prices;
  }

  /// Search for cryptocurrencies by query
  /// Returns list of {id, symbol, name}
  Future<List<Map<String, String>>> searchCrypto(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coins = data['coins'] as List;

        return coins
            .take(10)
            .map(
              (coin) => {
                'id': coin['id'].toString(),
                'symbol': coin['symbol'].toString().toUpperCase(),
                'name': coin['name'].toString(),
              },
            )
            .toList();
      }
    } catch (e) {
      print('Error searching crypto: $e');
    }
    return [];
  }

  /// Update crypto with current price and calculate portfolio values
  Future<Crypto> enrichCryptoWithPrice(Crypto crypto) async {
    final currentPrice = await getCurrentPrice(crypto.cryptoId);

    // Calculate invested amount
    final investedAmount = crypto.amount * crypto.purchasePrice;

    if (currentPrice == null) {
      // Return with investedAmount calculated even if price fetch failed
      return crypto.copyWith(investedAmount: investedAmount);
    }

    // Calculate current value and gains/losses
    final currentValue = crypto.amount * currentPrice;
    final gainLoss = currentValue - investedAmount;
    final gainLossPercentage = investedAmount > 0
        ? (gainLoss / investedAmount) * 100
        : 0.0;

    return crypto.copyWith(
      currentPrice: currentPrice,
      currentValue: currentValue,
      investedAmount: investedAmount,
      gainLoss: gainLoss,
      gainLossPercentage: gainLossPercentage,
    );
  }

  /// Batch update multiple cryptos with current prices
  Future<List<Crypto>> enrichCryptosWithPrice(List<Crypto> cryptos) async {
    if (cryptos.isEmpty) return cryptos;

    // Get unique crypto IDs
    final cryptoIds = cryptos.map((c) => c.cryptoId).toSet().toList();

    // Fetch all prices at once
    final prices = await getBatchPrices(cryptoIds);

    // Enrich each crypto with its price
    final enrichedCryptos = <Crypto>[];
    for (final crypto in cryptos) {
      final currentPrice = prices[crypto.cryptoId];
      final investedAmount = crypto.amount * crypto.purchasePrice;

      if (currentPrice == null) {
        enrichedCryptos.add(crypto.copyWith(investedAmount: investedAmount));
      } else {
        final currentValue = crypto.amount * currentPrice;
        final gainLoss = currentValue - investedAmount;
        final gainLossPercentage = investedAmount > 0
            ? (gainLoss / investedAmount) * 100
            : 0.0;

        enrichedCryptos.add(
          crypto.copyWith(
            currentPrice: currentPrice,
            currentValue: currentValue,
            investedAmount: investedAmount,
            gainLoss: gainLoss,
            gainLossPercentage: gainLossPercentage,
          ),
        );
      }
    }

    return enrichedCryptos;
  }
}
