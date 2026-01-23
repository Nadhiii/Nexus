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
  List<Bike> _deletedBikes = [];
  List<BikeEntry> _currentBikeEntries = [];
  List<Trip> _currentTrips = [];
  String? _selectedBikeId;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bikesSubscription;
  StreamSubscription? _deletedBikesSubscription;
  StreamSubscription? _entriesSubscription;
  StreamSubscription? _tripsSubscription;

  List<Bike> get bikes => _bikes;
  List<Bike> get deletedBikes => _deletedBikes;
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
      loadDeletedBikes(user.uid);
    }
  }

  // Public method to manually fetch bikes
  void fetchBikes() {
    final user = _auth.currentUser;
    if (user != null) {
      loadBikes(user.uid);
      loadDeletedBikes(user.uid);
    }
  }

  // Method to select a specific bike (separate from dashboard bike)
  void selectBike(String bikeId) {
    _selectedBikeId = bikeId;
    final user = _auth.currentUser;
    if (user != null) {
      loadBikeEntries(user.uid, bikeId);
    }
    notifyListeners();
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

  void loadDeletedBikes(String userId) {
    // Cancel previous subscription if it exists
    _deletedBikesSubscription?.cancel();

    _deletedBikesSubscription = _bikeService
        .watchAllBikes(userId)
        .listen(
          (allBikes) {
            _deletedBikes = allBikes.where((b) => !b.isActive).toList();
            print('BikeProvider: Found ${_deletedBikes.length} deleted bikes');
            for (var bike in _deletedBikes) {
              print('  Deleted: ${bike.name} (${bike.id})');
            }
            notifyListeners();
          },
          onError: (e) {
            print('Error loading deleted bikes: $e');
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
      // Soft delete: set isActive to false instead of permanently deleting
      final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
      if (bikeIndex != -1) {
        final deletedBike = _bikes[bikeIndex].copyWith(isActive: false);
        await _bikeService.updateBike(user.uid, deletedBike);
        // Remove from active list and add to deleted list
        _bikes.removeAt(bikeIndex);
        _deletedBikes.add(deletedBike);
        notifyListeners();
        print('Bike deleted: $bikeId');
      }
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

  Future<void> restoreBike(String bikeId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      // Get the bike and restore it by setting isActive to true
      final bike = await _bikeService.getBike(user.uid, bikeId);

      if (bike != null) {
        await _bikeService.updateBike(user.uid, bike.copyWith(isActive: true));
      }
      _setError(null);
    } catch (e) {
      _setError('Error restoring bike: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> permanentlyDeleteBike(String bikeId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      // Permanently delete the bike document
      await _bikeService.deleteBike(user.uid, bikeId);
      if (_selectedBikeId == bikeId) {
        _selectedBikeId = null;
        _currentBikeEntries = [];
      }
      _setError(null);
    } catch (e) {
      _setError('Error permanently deleting bike: $e');
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
      (sum, entry) =>
          sum +
          ((entry.category?.toLowerCase() == 'fuel') ? entry.fuelAmount : 0),
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
    return _currentBikeEntries
        .where((e) => e.category?.toLowerCase() == 'fuel')
        .length;
  }

  double getKmTraveled() {
    double totalDistance = 0;

    // Calculate from odometer difference if we have entries
    if (_currentBikeEntries.isNotEmpty) {
      final oldest = _currentBikeEntries.last.odometerReading;
      final newest = _currentBikeEntries.first.odometerReading;
      totalDistance += (newest - oldest).abs();
    }

    // Add trip distances
    totalDistance += getTotalDistanceFromTrips();

    return totalDistance;
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
    _deletedBikesSubscription?.cancel();
    _entriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    _bikes = [];
    _deletedBikes = [];
    _currentBikeEntries = [];
    _currentTrips = [];
    _selectedBikeId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Set a bike as the dashboard bike (only one can be dashboard bike)
  Future<void> setDashboardBike(String bikeId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      // Remove dashboard flag from all bikes
      for (var bike in _bikes) {
        if (bike.isDashboardBike) {
          await _bikeService.updateBike(
            user.uid,
            bike.copyWith(isDashboardBike: false),
          );
        }
      }

      // Set new dashboard bike
      final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
      if (bikeIndex != -1) {
        await _bikeService.updateBike(
          user.uid,
          _bikes[bikeIndex].copyWith(isDashboardBike: true),
        );
      }
      _setError(null);
    } catch (e) {
      _setError('Error setting dashboard bike: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get the dashboard bike
  Bike? getDashboardBike() {
    try {
      return _bikes.firstWhere((b) => b.isDashboardBike);
    } catch (e) {
      return null;
    }
  }

  /// Reorder bikes - moves bike at [fromIndex] to [toIndex]
  Future<void> reorderBikes(int fromIndex, int toIndex) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }

    // Perform local reordering for immediate UI update
    if (fromIndex < _bikes.length && toIndex < _bikes.length) {
      final List<Bike> reorderedBikes = List.from(_bikes);
      final bike = reorderedBikes.removeAt(fromIndex);
      reorderedBikes.insert(toIndex, bike);
      _bikes = reorderedBikes;
      notifyListeners();
    }

    _setLoading(true);
    try {
      // Update display order for all bikes
      for (int i = 0; i < _bikes.length; i++) {
        final bike = _bikes[i];
        if (bike.displayOrder != i) {
          await _bikeService.updateBike(
            user.uid,
            bike.copyWith(displayOrder: i),
          );
        }
      }
      _setError(null);
    } catch (e) {
      _setError('Error reordering bikes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get bikes sorted by display order
  List<Bike> getBikesSortedByOrder() {
    final sorted = List<Bike>.from(_bikes);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  @override
  void dispose() {
    _bikesSubscription?.cancel();
    _deletedBikesSubscription?.cancel();
    _entriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }
}
