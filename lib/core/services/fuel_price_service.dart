import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FuelPriceService {
  // Free API options:
  // 1. collectapi.com - Requires API key (free tier available)
  // 2. Manual scraping from IOCL/HPCL websites
  // 3. Using government open data portal

  // Cache configuration
  static const String _cacheKey = 'fuel_price_data';
  static const Duration _cacheValidity = Duration(days: 10);

  // City-based fuel prices (default fallback data)
  static final Map<String, FuelPrice> _defaultPrices = {
    'Mumbai': FuelPrice(petrol: 106.31, diesel: 94.27, city: 'Mumbai'),
    'Delhi': FuelPrice(petrol: 96.72, diesel: 89.62, city: 'Delhi'),
    'Bangalore': FuelPrice(petrol: 102.98, diesel: 87.89, city: 'Bangalore'),
    'Chennai': FuelPrice(petrol: 102.63, diesel: 94.24, city: 'Chennai'),
    'Hyderabad': FuelPrice(petrol: 109.66, diesel: 97.82, city: 'Hyderabad'),
    'Kolkata': FuelPrice(petrol: 106.03, diesel: 92.76, city: 'Kolkata'),
    'Pune': FuelPrice(petrol: 106.09, diesel: 94.15, city: 'Pune'),
    'Ahmedabad': FuelPrice(petrol: 96.42, diesel: 92.17, city: 'Ahmedabad'),
  };

  /// Get fuel prices for a specific city
  /// First checks cache, then tries API, falls back to defaults
  Future<FuelPrice> getFuelPriceForCity(String city) async {
    try {
      // Check cache first
      final cachedPrice = await _getCachedPrice(city);
      if (cachedPrice != null) {
        return cachedPrice;
      }

      // Try to fetch from API
      final apiPrice = await _fetchFromAPI(city);
      if (apiPrice != null) {
        await _cachePrice(city, apiPrice);
        return apiPrice;
      }

      // Fallback to default prices
      return _defaultPrices[city] ??
          FuelPrice(petrol: 100.0, diesel: 90.0, city: city);
    } catch (e) {
      // Return default on error
      return _defaultPrices[city] ??
          FuelPrice(petrol: 100.0, diesel: 90.0, city: city);
    }
  }

  /// Get list of all supported cities
  List<String> getSupportedCities() {
    return _defaultPrices.keys.toList()..sort();
  }

  /// Fetch price from API (RapidAPI)
  Future<FuelPrice?> _fetchFromAPI(String city) async {
    try {
      // Hardcoded RapidAPI key
      const apiKey = 'e356771fa0msh6b1eb9d872bd6b0p1f57f2jsn9f014540309f';

      // RapidAPI endpoint for India fuel prices
      final url = Uri.parse(
        'https://india-fuel-price.p.rapidapi.com/fuel-prices',
      );

      final response = await http
          .get(
            url,
            headers: {
              'X-RapidAPI-Key': apiKey,
              'X-RapidAPI-Host': 'india-fuel-price.p.rapidapi.com',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse response - format may vary by API
        // Expected format: {"city": "Mumbai", "petrol": 106.31, "diesel": 94.27}
        if (data is Map) {
          // Try different response structures
          var cityData = data[city] ?? data['data']?[city] ?? data;

          if (cityData != null) {
            return FuelPrice(
              petrol:
                  double.tryParse(cityData['petrol']?.toString() ?? '0') ?? 0,
              diesel:
                  double.tryParse(cityData['diesel']?.toString() ?? '0') ?? 0,
              city: city,
              lastUpdated: DateTime.now(),
            );
          }
        } else if (data is List && data.isNotEmpty) {
          // If response is a list, find the city
          final cityData = data.firstWhere(
            (item) =>
                item['city']?.toString().toLowerCase() == city.toLowerCase(),
            orElse: () => null,
          );

          if (cityData != null) {
            return FuelPrice(
              petrol:
                  double.tryParse(cityData['petrol']?.toString() ?? '0') ?? 0,
              diesel:
                  double.tryParse(cityData['diesel']?.toString() ?? '0') ?? 0,
              city: city,
              lastUpdated: DateTime.now(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching fuel price from RapidAPI: $e');
    }
    return null;
  }

  /// Cache price data locally
  Future<void> _cachePrice(String city, FuelPrice price) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'petrol': price.petrol,
        'diesel': price.diesel,
        'city': price.city,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('${_cacheKey}_$city', json.encode(cacheData));
    } catch (e) {
      debugPrint('Error caching fuel price: $e');
    }
  }

  /// Get cached price if still valid
  Future<FuelPrice?> _getCachedPrice(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_cacheKey}_$city');

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = DateTime.parse(data['timestamp']);

        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheValidity) {
          return FuelPrice(
            petrol: data['petrol'],
            diesel: data['diesel'],
            city: data['city'],
            lastUpdated: timestamp,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reading cached fuel price: $e');
    }
    return null;
  }

  /// Save API key for fuel price service
  Future<void> setAPIKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuel_api_key', apiKey);
  }

  /// Clear cached prices
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKey)) {
        await prefs.remove(key);
      }
    }
  }

  /// Manually update price for a city (for admin/testing)
  Future<void> updatePrice(String city, double petrol, double diesel) async {
    final price = FuelPrice(
      petrol: petrol,
      diesel: diesel,
      city: city,
      lastUpdated: DateTime.now(),
    );
    await _cachePrice(city, price);
  }
}

/// Fuel price data model
class FuelPrice {
  final double petrol;
  final double diesel;
  final String city;
  final DateTime? lastUpdated;

  FuelPrice({
    required this.petrol,
    required this.diesel,
    required this.city,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'petrol': petrol,
    'diesel': diesel,
    'city': city,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory FuelPrice.fromJson(Map<String, dynamic> json) => FuelPrice(
    petrol: json['petrol'],
    diesel: json['diesel'],
    city: json['city'],
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'])
        : null,
  );
}
