import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('Error fetching NAV for scheme $schemeCode: $e');
    }
    return null;
  }

  /// Update investment with current NAV and recalculate its market value.
  ///
  /// IMPORTANT: This only ever touches `currentAmount`. `investedAmount` is
  /// what the user actually typed in when they logged the purchase — it is
  /// ground truth and must never be recalculated or overwritten here.
  Future<Investment> enrichInvestmentWithNav(Investment investment) async {
    // Only enrich Mutual Fund investments that have a scheme code.
    // Other asset types (stock/crypto/gold/real estate/other) have no
    // live-price source wired up yet, so they pass through unchanged.
    if (investment.mutualFundSchemeCode == null) {
      return investment;
    }

    // Fetch current NAV for the scheme
    final currentNav = await getCurrentNav(investment.mutualFundSchemeCode!);

    if (currentNav == null) {
      // NAV fetch failed — leave the investment exactly as it was.
      // Do NOT touch investedAmount or currentAmount here.
      return investment;
    }

    // Only recalculate the current market value. investedAmount is
    // intentionally left untouched — it's user-entered, not derived.
    final currentValue = investment.quantity * currentNav;

    return investment.copyWith(
      currentAmount: currentValue,
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
