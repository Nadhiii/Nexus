import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bike.dart';
import '../models/trip.dart';
import '../services/bike_service.dart';

class BikeProvider with ChangeNotifier {
  final BikeService _bikeService = BikeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Bike> _bikes = [];
  List<BikeEntry> _currentBikeEntries = [];
  List<Trip> _currentTrips = [];
  String? _selectedBikeId;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bikesSubscription;
  StreamSubscription? _entriesSubscription;
  StreamSubscription? _tripsSubscription;

  List<Bike> get bikes => _bikes;
  List<BikeEntry> get currentBikeEntries => _currentBikeEntries;
  List<Trip> get currentTrips => _currentTrips;
  String? get selectedBikeId => _selectedBikeId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FirebaseAuth get auth => _auth;
  Bike? get selectedBike {
    if (_selectedBikeId == null) return _bikes.isNotEmpty ? _bikes.first : null;
    try {
      return _bikes.firstWhere((b) => b.id == _selectedBikeId);
    } catch (e) {
      return _bikes.isNotEmpty ? _bikes.first : null;
    }
  }

  BikeProvider() {
    _init();
  }

  void _init() {
    final user = _auth.currentUser;
    if (user != null) {
      loadBikes(user.uid);
    }
  }

  void loadBikes(String userId) {
    _setLoading(true);
    // Cancel previous subscription if it exists
    _bikesSubscription?.cancel();

    _bikesSubscription = _bikeService
        .watchBikes(userId)
        .listen(
          (bikes) {
            _bikes = bikes;
            _setLoading(false);
            notifyListeners();

            // Load entries for first bike if available
            if (bikes.isNotEmpty && _selectedBikeId == null) {
              _selectedBikeId = bikes.first.id;
              loadBikeEntries(userId, bikes.first.id);
            }
          },
          onError: (e) {
            _setError('Error loading bikes: $e');
            _setLoading(false);
          },
        );
  }

  void loadBikeEntries(String userId, String bikeId) {
    _setLoading(true);
    // Cancel previous subscription if it exists
    _entriesSubscription?.cancel();

    _entriesSubscription = _bikeService
        .watchBikeEntries(userId, bikeId)
        .listen(
          (entries) {
            _currentBikeEntries = entries;
            _selectedBikeId = bikeId;
            _setLoading(false);
            notifyListeners();
          },
          onError: (e) {
            _setError('Error loading entries: $e');
            _setLoading(false);
          },
        );

    // Also load trips for the bike
    loadTrips(userId, bikeId);
  }

  void loadTrips(String userId, String bikeId) {
    // Cancel previous subscription if it exists
    _tripsSubscription?.cancel();

    _tripsSubscription = _bikeService
        .watchTrips(userId, bikeId)
        .listen(
          (trips) {
            _currentTrips = trips;
            notifyListeners();
          },
          onError: (e) {
            _setError('Error loading trips: $e');
          },
        );
  }

  Future<void> addBike(Bike bike) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.addBike(user.uid, bike.copyWith(userId: user.uid));
      _setError(null);
    } catch (e) {
      _setError('Error adding bike: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBike(Bike bike) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.updateBike(user.uid, bike);
      _setError(null);
    } catch (e) {
      _setError('Error updating bike: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBike(String bikeId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.deleteBike(user.uid, bikeId);
      if (_selectedBikeId == bikeId) {
        _selectedBikeId = null;
        _currentBikeEntries = [];
      }
      _setError(null);
    } catch (e) {
      _setError('Error deleting bike: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addBikeEntry(BikeEntry entry) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.addBikeEntry(user.uid, _selectedBikeId!, entry);
      _setError(null);
    } catch (e) {
      _setError('Error adding entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBikeEntry(BikeEntry entry) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.updateBikeEntry(user.uid, _selectedBikeId!, entry);
      _setError(null);
    } catch (e) {
      _setError('Error updating entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBikeEntry(String entryId) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.deleteBikeEntry(user.uid, _selectedBikeId!, entryId);
      _setError(null);
    } catch (e) {
      _setError('Error deleting entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Statistics
  double getTotalFuelCost() {
    return _currentBikeEntries.fold<double>(
      0,
      (sum, entry) => sum + (entry.category == 'fuel' ? entry.fuelAmount : 0),
    );
  }

  double getAverageMileage() {
    final entries = _currentBikeEntries
        .where((e) => e.mileage != null && e.mileage! > 0)
        .toList();
    if (entries.isEmpty) return 0;
    return entries.fold<double>(0, (sum, e) => sum + e.mileage!) /
        entries.length;
  }

  int getTotalFillups() {
    return _currentBikeEntries.where((e) => e.category == 'fuel').length;
  }

  double getKmTraveled() {
    if (_currentBikeEntries.isEmpty) return 0;
    final oldest = _currentBikeEntries.last.odometerReading;
    final newest = _currentBikeEntries.first.odometerReading;
    return (newest - oldest).abs();
  }

  double calculateMileage(double fuelQuantity, double kmTraveled) {
    return _bikeService.calculateMileage(fuelQuantity, kmTraveled);
  }

  // Trip management
  Future<void> addTrip(Trip trip) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.addTrip(user.uid, _selectedBikeId!, trip);
      _setError(null);
    } catch (e) {
      _setError('Error adding trip: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTrip(Trip trip) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.updateTrip(user.uid, _selectedBikeId!, trip);
      _setError(null);
    } catch (e) {
      _setError('Error updating trip: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTrip(String tripId) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.deleteTrip(user.uid, _selectedBikeId!, tripId);
      _setError(null);
    } catch (e) {
      _setError('Error deleting trip: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Calculate total distance from all trips
  double getTotalDistanceFromTrips() {
    return _currentTrips.fold<double>(0, (sum, trip) => sum + trip.distanceKm);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clear() {
    _bikesSubscription?.cancel();
    _entriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    _bikes = [];
    _currentBikeEntries = [];
    _currentTrips = [];
    _selectedBikeId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _bikesSubscription?.cancel();
    _entriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }
}
