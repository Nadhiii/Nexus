import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment.dart';

class NavService {
  static const String baseUrl = 'https://api.mfapi.in/mf';

  /// Fetch current NAV for a mutual fund scheme
  Future<double?> getCurrentNav(String schemeCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$schemeCode'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final navData = data['data'] as List?;

        if (navData != null && navData.isNotEmpty) {
          return double.parse(navData[0]['nav'].toString());
        }
      }
    } catch (e) {
      print('Error fetching NAV for scheme $schemeCode: $e');
    }
    return null;
  }

  /// Update investment with current NAV and calculate portfolio values
  Future<Investment> enrichInvestmentWithNav(Investment investment) async {
    // Only enrich Mutual Fund investments that have a scheme code
    if (investment.mutualFundSchemeCode == null) {
      return investment;
    }

    // Calculate total invested amount based on actual purchase
    // (quantity owned * purchase price per unit)
    final investedAmount = investment.quantity * investment.purchasePrice;

    // Fetch current NAV for the scheme
    final currentNav = await getCurrentNav(investment.mutualFundSchemeCode!);

    if (currentNav == null) {
      // Return with investedAmount calculated even if NAV fetch failed
      return investment.copyWith(
        investedAmount: investedAmount,
        lastUpdated: DateTime.now(),
      );
    }

    // Calculate current value
    final currentValue = investment.quantity * currentNav;

    return investment.copyWith(
      currentAmount: currentValue,
      investedAmount: investedAmount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Batch update multiple investments with current NAV
  Future<List<Investment>> enrichInvestmentsWithNav(
    List<Investment> investments,
  ) async {
    final enrichedInvestments = <Investment>[];

    for (final investment in investments) {
      final enriched = await enrichInvestmentWithNav(investment);
      enrichedInvestments.add(enriched);
    }

    return enrichedInvestments;
  }
}
