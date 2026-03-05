import 'package:flutter/material.dart';
import '../services/fuel_price_service.dart';
import '../services/location_service.dart';

class FuelPriceProvider with ChangeNotifier {
  final FuelPriceService _fuelPriceService = FuelPriceService();
  final LocationService _locationService = LocationService();

  FuelPrice? _currentPrice;
  String? _selectedCity;
  bool _isLoading = false;
  String? _error;
  bool _autoDetectLocation = true;

  FuelPrice? get currentPrice => _currentPrice;
  String? get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get autoDetectLocation => _autoDetectLocation;

  List<String> get supportedCities => _fuelPriceService.getSupportedCities();

  FuelPriceProvider() {
    // Initialize asynchronously without blocking
    Future.microtask(_initSafely);
  }

  Future<void> _initSafely() async {
    try {
      await loadSavedPreferences();
      // Don't auto-detect on init to avoid crashes
      // User can manually trigger location detection
      if (_selectedCity != null) {
        await loadPriceForCity(_selectedCity!);
      } else {
        // Load default city without detection
        await loadPriceForCity('Mumbai');
      }
    } catch (e) {
      debugPrint('Error initializing fuel price provider: $e');
      // Fallback to Mumbai
      _selectedCity = 'Mumbai';
      await loadPriceForCity('Mumbai');
    }
  }

  /// Load saved preferences
  Future<void> loadSavedPreferences() async {
    try {
      final savedCity = await _locationService.getSelectedCity();
      if (savedCity != null) {
        _selectedCity = savedCity;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved preferences: $e');
    }
  }

  /// Detect current location and load fuel price
  Future<void> detectAndLoadCity() async {
    _setLoading(true);
    _setError(null);

    try {
      final city = await _locationService.getCurrentCity();
      if (city != null) {
        final normalizedCity = _locationService.normalizeCity(city);
        _selectedCity = normalizedCity;
        await loadPriceForCity(normalizedCity);
      } else {
        _setError('Could not detect location');
        // Load default city if detection fails
        _selectedCity = 'Mumbai';
        await loadPriceForCity('Mumbai');
      }
    } catch (e) {
      _setError('Error detecting location: $e');
      _selectedCity = 'Mumbai';
      await loadPriceForCity('Mumbai');
    } finally {
      _setLoading(false);
    }
  }

  /// Load fuel price for a specific city
  Future<void> loadPriceForCity(String city) async {
    _setLoading(true);
    _setError(null);

    try {
      final price = await _fuelPriceService.getFuelPriceForCity(city);
      _currentPrice = price;
      _selectedCity = city;
      await _locationService.setSelectedCity(city);
    } catch (e) {
      _setError('Error loading fuel price: $e');
      debugPrint('Error loading fuel price for $city: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current city's fuel price
  Future<void> refresh() async {
    // Use selected city or default to Mumbai if not set
    final cityToRefresh = _selectedCity ?? 'Mumbai';
    try {
      await _fuelPriceService.clearCache();
      await loadPriceForCity(cityToRefresh);
    } catch (e) {
      _setError('Error refreshing: $e');
      debugPrint('Error refreshing prices: $e');
      // Don't rethrow - just log the error
    }
  }

  /// Toggle auto-detect location
  void setAutoDetectLocation(bool enabled) {
    _autoDetectLocation = enabled;
    notifyListeners();
    if (enabled) {
      detectAndLoadCity();
    }
  }

  /// Set API key for fuel price service
  Future<void> setAPIKey(String apiKey) async {
    await _fuelPriceService.setAPIKey(apiKey);
  }

  /// Manually update price (for testing/admin)
  Future<void> updatePrice(String city, double petrol, double diesel) async {
    await _fuelPriceService.updatePrice(city, petrol, diesel);
    if (_selectedCity == city) {
      await loadPriceForCity(city);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
