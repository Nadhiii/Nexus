import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static const String _selectedCityKey = 'selected_city';

  /// Get user's current city using GPS
  Future<String?> getCurrentCity() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          debugPrint('Error requesting location permission: $e');
          return null;
        }
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return null;
      }

      // Get current position with error handling
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (e) {
        debugPrint('Error getting position: $e');
        return null;
      }

      // Reverse geocode to get city name
      List<Placemark> placemarks = [];
      try {
        placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('Error getting placemarks: $e');
        return null;
      }

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        String? city =
            placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;

        final normalizedCity = city?.trim();
        if (normalizedCity?.isNotEmpty ?? false) {
          // Save detected city
          await setSelectedCity(normalizedCity!);
          return normalizedCity;
        }
      }
    } catch (e) {
      debugPrint('Error getting current city: $e');
    }
    return null;
  }

  /// Get saved city preference
  Future<String?> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedCityKey);
    } catch (e) {
      debugPrint('Error getting selected city: $e');
      return null;
    }
  }

  /// Save user's city preference
  Future<void> setSelectedCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCityKey, city);
    } catch (e) {
      debugPrint('Error setting selected city: $e');
    }
  }

  /// Clear saved city
  Future<void> clearSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedCityKey);
    } catch (e) {
      debugPrint('Error clearing selected city: $e');
    }
  }

  /// Map common city name variations to standard names
  String normalizeCity(String city) {
    final cityMap = {
      'Bengaluru': 'Bangalore',
      'Bombay': 'Mumbai',
      'Calcutta': 'Kolkata',
      'Madras': 'Chennai',
    };

    return cityMap[city] ?? city;
  }
}
