import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service to fetch live mutual fund data from Indian Mutual Fund API
/// Uses the free MFApi - https://www.mfapi.in/
class MutualFundApiService {
  static const String baseUrl = 'https://api.mfapi.in/mf';

  /// Search for mutual funds by scheme name
  /// Returns list of schemes with their codes
  Future<List<MutualFundScheme>> searchSchemes(String query) async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> schemes = json.decode(response.body);

        // Filter schemes by query
        final filtered = schemes
            .where(
              (scheme) => scheme['schemeName']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .map((scheme) => MutualFundScheme.fromJson(scheme))
            .toList();

        return filtered;
      } else {
        throw Exception('Failed to search schemes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching mutual fund schemes: $e');
      rethrow;
    }
  }

  /// Get all available mutual fund schemes
  Future<List<MutualFundScheme>> getAllSchemes() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> schemes = json.decode(response.body);
        return schemes
            .map((scheme) => MutualFundScheme.fromJson(scheme))
            .toList();
      } else {
        throw Exception('Failed to fetch schemes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching mutual fund schemes: $e');
      rethrow;
    }
  }

  /// Get latest NAV (Net Asset Value) for a specific scheme
  Future<MutualFundData?> getSchemeData(String schemeCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$schemeCode'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MutualFundData.fromJson(data);
      } else {
        debugPrint('Failed to fetch scheme data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching scheme data for $schemeCode: $e');
      return null;
    }
  }

  /// Get latest NAV for multiple schemes (batch)
  Future<Map<String, double>> getBatchNAV(List<String> schemeCodes) async {
    final Map<String, double> navMap = {};

    // Fetch data for each scheme
    for (final code in schemeCodes) {
      final data = await getSchemeData(code);
      if (data != null && data.latestNav != null) {
        navMap[code] = data.latestNav!;
      }
    }

    return navMap;
  }

  /// Get historical NAV data for a scheme
  Future<List<NavData>> getHistoricalData(
    String schemeCode, {
    int? limit,
  }) async {
    try {
      final data = await getSchemeData(schemeCode);

      if (data != null && data.navHistory.isNotEmpty) {
        if (limit != null && limit < data.navHistory.length) {
          return data.navHistory.take(limit).toList();
        }
        return data.navHistory;
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching historical data: $e');
      return [];
    }
  }
}

/// Model for mutual fund scheme (minimal info from list)
class MutualFundScheme {
  final String schemeCode;
  final String schemeName;

  MutualFundScheme({required this.schemeCode, required this.schemeName});

  factory MutualFundScheme.fromJson(Map<String, dynamic> json) {
    return MutualFundScheme(
      schemeCode: json['schemeCode'].toString(),
      schemeName: json['schemeName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'schemeCode': schemeCode, 'schemeName': schemeName};
  }
}

/// Model for complete mutual fund data with NAV history
class MutualFundData {
  final Map<String, dynamic> meta;
  final List<NavData> navHistory;
  final String? status;

  MutualFundData({required this.meta, required this.navHistory, this.status});

  String get schemeName => meta['scheme_name'] ?? '';
  String get schemeCode => meta['scheme_code'] ?? '';
  String get schemeType => meta['scheme_type'] ?? '';
  String get schemeCategory => meta['scheme_category'] ?? '';
  String get fundHouse => meta['fund_house'] ?? '';

  /// Get the latest NAV value
  double? get latestNav {
    if (navHistory.isEmpty) { return null; }
    return navHistory.first.nav;
  }

  /// Get the latest NAV date
  DateTime? get latestNavDate {
    if (navHistory.isEmpty) { return null; }
    return navHistory.first.date;
  }

  factory MutualFundData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? [];
    final navHistory = dataList.map((item) => NavData.fromJson(item)).toList();

    return MutualFundData(
      meta: json['meta'] ?? {},
      navHistory: navHistory,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meta': meta,
      'data': navHistory.map((nav) => nav.toJson()).toList(),
      'status': status,
    };
  }
}

/// Model for individual NAV data point
class NavData {
  final DateTime date;
  final double nav;

  NavData({required this.date, required this.nav});

  factory NavData.fromJson(Map<String, dynamic> json) {
    return NavData(
      date: _parseDate(json['date'] ?? ''),
      nav: double.tryParse(json['nav']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': _formatDate(date), 'nav': nav.toString()};
  }

  /// Parse date string (format: "DD-MM-YYYY")
  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr');
    }
    return DateTime.now();
  }

  /// Format date to API format (DD-MM-YYYY)
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}
