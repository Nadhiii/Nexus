import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crypto.dart';
import '../services/crypto_service.dart';
import '../services/crypto_price_service.dart';

class CryptoProvider extends ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();
  final CryptoPriceService _priceService = CryptoPriceService();
  List<Crypto> _cryptos = [];
  bool _isLoading = false;
  String? _error;

  List<Crypto> get cryptos => _cryptos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CryptoProvider() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadCryptos(user.uid);
    }
  }

  Future<void> loadCryptos(String userId) async {
    _setLoading(true);
    try {
      _cryptoService
          .watchCryptos(userId)
          .listen(
            (cryptos) async {
              // Enrich cryptos with current prices
              _cryptos = await _priceService.enrichCryptosWithPrice(cryptos);
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Error loading cryptos: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Error setting up crypto stream: $e');
      _setLoading(false);
    }
  }

  /// Refresh price data for all cryptos
  Future<void> refreshPriceData() async {
    if (_cryptos.isEmpty) return;

    try {
      _cryptos = await _priceService.enrichCryptosWithPrice(_cryptos);
      notifyListeners();
    } catch (e) {
      _setError('Error refreshing price data: $e');
    }
  }

  Future<void> addCrypto(Crypto crypto) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _cryptoService.addCrypto(crypto.copyWith(userId: user.uid));
    } catch (e) {
      _setError('Error adding crypto: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCrypto(Crypto crypto) async {
    _setLoading(true);
    try {
      await _cryptoService.updateCrypto(crypto);
    } catch (e) {
      _setError('Error updating crypto: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCrypto(String cryptoId) async {
    _setLoading(true);
    try {
      await _cryptoService.deleteCrypto(cryptoId);
    } catch (e) {
      _setError('Error deleting crypto: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleCryptoStatus(String cryptoId, bool isActive) async {
    try {
      await _cryptoService.toggleCryptoStatus(cryptoId, isActive);
    } catch (e) {
      _setError('Error toggling crypto status: $e');
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
