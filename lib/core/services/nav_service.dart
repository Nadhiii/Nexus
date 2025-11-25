import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mutualfunds.dart';

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
    // Calculate months since start date
    final now = DateTime.now();
    final monthsInvested =
        (now.year - investment.startDate.year) * 12 +
        (now.month - investment.startDate.month);

    // Calculate total invested amount (number of SIP installments * sipAmount)
    final installments = monthsInvested > 0 ? monthsInvested : 1;
    final investedAmount = investment.sipAmount * installments;

    final currentNav = await getCurrentNav(investment.mutualFundSchemeCode);

    if (currentNav == null) {
      // Return with investedAmount calculated even if NAV fetch failed
      return investment.copyWith(investedAmount: investedAmount);
    }

    // Calculate current value and gains/losses
    final currentValue = investment.units * currentNav;
    final gainLoss = currentValue - investedAmount;
    final gainLossPercentage = investedAmount > 0
        ? (gainLoss / investedAmount) * 100
        : 0.0;

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
