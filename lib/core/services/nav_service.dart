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
    final currentNav = await getCurrentNav(investment.mutualFundSchemeCode);

    if (currentNav == null) {
      return investment; // Return as-is if NAV fetch failed
    }

    // Calculate current value and gains/losses
    final currentValue = investment.units * currentNav;
    final investedAmount = investment
        .sipAmount; // For single SIP (will need to update for multiple installments)
    final gainLoss = currentValue - investedAmount;
    final gainLossPercentage = (gainLoss / investedAmount) * 100;

    return investment.copyWith(
      currentNav: currentNav,
      currentValue: currentValue,
      investedAmount: investedAmount,
      gainLoss: gainLoss,
      gainLossPercentage: gainLossPercentage,
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
