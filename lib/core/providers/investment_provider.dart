import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import '../services/nav_service.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentService _investmentService = InvestmentService();
  final NavService _navService = NavService();
  List<Investment> _investments = [];
  bool _isLoading = false;
  String? _error;

  List<Investment> get investments => _investments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  InvestmentProvider() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadInvestments(user.uid);
    }
  }

  Future<void> loadInvestments(String userId) async {
    _setLoading(true);
    try {
      _investmentService
          .watchInvestments(userId)
          .listen(
            (investments) async {
              // Enrich investments with current NAV data
              _investments = await _navService.enrichInvestmentsWithNav(
                investments,
              );
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Error loading investments: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Error setting up investment stream: $e');
      _setLoading(false);
    }
  }

  /// Refresh NAV data for all investments
  Future<void> refreshNavData() async {
    if (_investments.isEmpty) return;

    try {
      _investments = await _navService.enrichInvestmentsWithNav(_investments);
      notifyListeners();
    } catch (e) {
      _setError('Error refreshing NAV data: $e');
    }
  }

  Future<void> addInvestment(Investment investment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _investmentService.addInvestment(
        investment.copyWith(userId: user.uid),
      );
    } catch (e) {
      _setError('Error adding investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateInvestment(Investment investment) async {
    _setLoading(true);
    try {
      await _investmentService.updateInvestment(investment);
    } catch (e) {
      _setError('Error updating investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteInvestment(String investmentId) async {
    _setLoading(true);
    try {
      await _investmentService.deleteInvestment(investmentId);
    } catch (e) {
      _setError('Error deleting investment: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
