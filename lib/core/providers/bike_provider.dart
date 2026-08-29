import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bike.dart';
import '../models/trip.dart';
import '../services/bike_service.dart';
import '../services/home_screen_widget_service.dart';
import '../services/android_auto_service.dart';
import 'package:intl/intl.dart';

class BikeProvider with ChangeNotifier {
  final BikeService _bikeService = BikeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Bike> _bikes = [];
  List<Bike> _deletedBikes = [];
  List<BikeEntry> _currentBikeEntries = [];
  List<BikeEntry> _dashboardBikeEntries = [];
  List<Trip> _currentTrips = [];
  String? _selectedBikeId;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bikesSubscription;
  StreamSubscription? _deletedBikesSubscription;
  StreamSubscription? _entriesSubscription;
  StreamSubscription? _dashboardEntriesSubscription;
  StreamSubscription? _tripsSubscription;

  List<Bike> get bikes => _bikes;
  List<Bike> get deletedBikes => _deletedBikes;
  List<BikeEntry> get currentBikeEntries => _currentBikeEntries;
  List<BikeEntry> get dashboardBikeEntries =>
      List<BikeEntry>.unmodifiable(_dashboardBikeEntries);
  List<Trip> get currentTrips => _currentTrips;
  String? get selectedBikeId => _selectedBikeId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FirebaseAuth get auth => _auth;

  List<BikeEntry> getEntriesForBike(String bikeId) {
    if (_selectedBikeId != bikeId) {
      return const <BikeEntry>[];
    }
    return List<BikeEntry>.unmodifiable(_currentBikeEntries);
  }

  Bike? get selectedBike {
    if (_selectedBikeId == null) { return _bikes.isNotEmpty ? _bikes.first : null; }
    try {
      return _bikes.firstWhere((b) => b.id == _selectedBikeId);
    } catch (e) {
      return _bikes.isNotEmpty ? _bikes.first : null;
    }
  }

  /// The bike explicitly chosen to appear on the Home dashboard.
  Bike? get dashboardDisplayBike {
    try {
      return _bikes.firstWhere((b) => b.isDashboardBike);
    } catch (e) {
      return null;
    }
  }

  BikeProvider() {
    _init();
  }

  /// Returns the number of unique calendar days where a transaction occurred.
  /// If 2 fuel-ups happen on 18/02/2026, it counts as 1 day.
  int getUniqueActiveDays() {
    final uniqueDays = _currentBikeEntries.map((entry) {
      // Standardize to YYYY-MM-DD to ignore time differences
      return "${entry.date.year}-${entry.date.month}-${entry.date.day}";
    }).toSet();

    debugPrint('≡ƒùô∩╕Å getUniqueActiveDays: ${uniqueDays.length} unique days');
    return uniqueDays.length;
  }

  List<BikeEntry> get filteredTimeline {
    List<BikeEntry> entries = List.from(_currentBikeEntries);
    // Default Sort: Newest to Oldest
    entries.sort((a, b) => b.date.compareTo(a.date));
    // You can add 'where' clauses here later for date filters
    return entries;
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
    debugPrint('≡ƒÅì∩╕Å BikeProvider: selectBike called with bikeId: $bikeId');
    _selectedBikeId = bikeId;
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('≡ƒÅì∩╕Å BikeProvider: Loading entries for user ${user.uid}');
      loadBikeEntries(user.uid, bikeId);
    } else {
      debugPrint('Γ¥î BikeProvider: No current user!');
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

            // Keep dashboard-specific data tied to the dashboard bike,
            // independently of Garage selectedBike state.
            _loadDashboardBikeEntries(userId);

            // Sync to widgets when bikes update
            _syncToWidgets();
          },
          onError: (e) {
            _setError('Error loading bikes: $e');
            _setLoading(false);
          },
        );
  }

  void _loadDashboardBikeEntries(String userId) {
    _dashboardEntriesSubscription?.cancel();
    _dashboardBikeEntries = [];

    final dashboardBike = dashboardDisplayBike;
    if (dashboardBike == null) {
      notifyListeners();
      return;
    }

    _dashboardEntriesSubscription = _bikeService
        .watchBikeEntries(userId, dashboardBike.id)
        .listen(
      (entries) {
        _dashboardBikeEntries = entries;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Γ¥î BikeProvider: Error loading dashboard bike entries: $e');
        _setError('Error loading dashboard bike entries: $e');
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
            debugPrint('BikeProvider: Found ${_deletedBikes.length} deleted bikes');
            for (var bike in _deletedBikes) {
              debugPrint('  Deleted: ${bike.name} (${bike.id})');
            }
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error loading deleted bikes: $e');
          },
        );
  }

  void loadBikeEntries(String userId, String bikeId) {
    debugPrint('≡ƒôè BikeProvider: loadBikeEntries called for bikeId: $bikeId');
    _setLoading(true);
    // Cancel previous subscription if it exists
    _entriesSubscription?.cancel();

    _entriesSubscription = _bikeService
        .watchBikeEntries(userId, bikeId)
        .listen(
          (entries) {
            debugPrint('≡ƒôè BikeProvider: Received ${entries.length} entries');
            for (var i = 0; i < entries.length; i++) {
              final entry = entries[i];
              debugPrint(
                '  [$i] ${entry.date.toIso8601String()} | ${entry.category}, Γé╣${entry.fuelAmount}, ${entry.fuelQuantity}L',
              );
            }
            _currentBikeEntries = entries;
            _selectedBikeId = bikeId;
            _setLoading(false);
            notifyListeners();

            // Sync to widgets whenever entries update
            _syncToWidgets();
          },
          onError: (e) {
            debugPrint('Γ¥î BikeProvider: Error loading entries: $e');
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
        debugPrint('Bike deleted: $bikeId');
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
      // Firestore listener will automatically pick up the new entry
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
      // Firestore listener will automatically pick up the updated entry
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

  Future<void> undoDeleteBikeEntry(BikeEntry entry) async {
    final user = _auth.currentUser;
    if (user == null || _selectedBikeId == null) {
      _setError('User or bike not selected');
      return;
    }
    _setLoading(true);
    try {
      await _bikeService.restoreBikeEntry(user.uid, _selectedBikeId!, entry);
      _setError(null);
    } catch (e) {
      _setError('Error restoring entry: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ
  // MILEAGE CALCULATION (Full Tank ΓåÆ Full Tank method)
  //
  // This matches the spreadsheet "Real Mileage" logic:
  //   - Sort all FUEL entries by odometer reading (ascending = chronological
  //     by distance traveled, which is more reliable than date for bikes
  //     where entries might be logged out of order).
  //   - Walk through entries, accumulating fuel quantity (including
  //     partial fills) since the last Full Tank.
  //   - When we hit a Full Tank entry, mileage = (odometer delta since the
  //     PREVIOUS full tank) / (sum of fuel added since then, INCLUDING
  //     this full tank's own fuel).
  //   - Partial fills get NO standalone mileage value (mileageDisplay = '-')
  //     because mileage can only be reliably computed at a full-tank point.
  //
  // This avoids the "0.01 km/L" bug, which happened because the old code
  // computed dist / fuelQuantity using the nearest-lower-odometer entry
  // (which could be a partial fill just a few km away), giving a tiny
  // distance divided against a normal fuel amount.
  // ΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉΓòÉ

  /// Returns a map of entryId -> calculated mileage (km/L) for FULL TANK
  /// entries only. Partial fill entries are not included (no key present).
  Map<String, double> getEntryMileageMap() {
    final Map<String, double> result = {};

    final fuelEntries = _dashboardBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    if (fuelEntries.length < 2) {
      return result;
    }

    // Sort by odometer reading ascending (chronological by distance)
    final sorted = List<BikeEntry>.from(fuelEntries)
      ..sort((a, b) => a.odometerReading.compareTo(b.odometerReading));

    double? lastFullTankOdo;
    double fuelSinceLastFullTank = 0.0;

    for (final entry in sorted) {
      fuelSinceLastFullTank += entry.fuelQuantity;

      if (entry.isFullTank) {
        if (lastFullTankOdo != null) {
          final dist = entry.odometerReading - lastFullTankOdo;
          if (dist > 0 && fuelSinceLastFullTank > 0) {
            result[entry.id] = dist / fuelSinceLastFullTank;
          }
        }
        // Reset accumulator from this full tank point
        lastFullTankOdo = entry.odometerReading;
        fuelSinceLastFullTank = 0.0;
      }
    }

    return result;
  }

  /// Get the calculated mileage for a specific entry, or null if not
  /// applicable (e.g. partial fill, or first full-tank entry with no
  /// prior reference point).
  double? getMileageForEntry(String entryId) {
    return getEntryMileageMap()[entryId];
  }

  double getAverageMileage() {
    final entries = _currentBikeEntries
        .where((e) => e.mileage != null && e.mileage! > 0)
        .toList();
    if (entries.isEmpty) {
      debugPrint('Γ¢╜ getAverageMileage: 0 (no entries with mileage)');
      return 0;
    }
    final avg =
        entries.fold<double>(0, (sum, e) => sum + e.mileage!) / entries.length;
    debugPrint('Γ¢╜ getAverageMileage: $avg (from ${entries.length} entries)');
    return avg;
  }

  /// Calculate overall average mileage using the Full Tank ΓåÆ Full Tank
  /// method. This is the RELIABLE, production method ΓÇö it matches the
  /// spreadsheet's "Real Mileage" approach and correctly accounts for
  /// partial fills between full tanks.
  double getDashboardReliableAverageMileage() {
    final fuelEntries = _dashboardBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    if (fuelEntries.length < 2) {
      return 0.0;
    }

    final sorted = List<BikeEntry>.from(fuelEntries)
      ..sort((a, b) => a.odometerReading.compareTo(b.odometerReading));

    double? lastFullTankOdo;
    double fuelSinceLastFullTank = 0.0;
    final mileages = <double>[];

    for (final entry in sorted) {
      final quantity = entry.fuelQuantity;
      if (quantity > 0) {
        fuelSinceLastFullTank += quantity;
      }

      if (entry.isFullTank) {
        if (lastFullTankOdo != null) {
          final dist = entry.odometerReading - lastFullTankOdo;
          if (dist > 0 && fuelSinceLastFullTank > 0) {
            mileages.add(dist / fuelSinceLastFullTank);
          }
        }
        lastFullTankOdo = entry.odometerReading;
        fuelSinceLastFullTank = 0.0;
      }
    }

    if (mileages.isEmpty) {
      return 0.0;
    }

    return mileages.reduce((a, b) => a + b) / mileages.length;
  }

  double getReliableAverageMileage() {
    final mileageMap = getEntryMileageMap();

    if (mileageMap.isEmpty) {
      return 0.0;
    }

    final total = mileageMap.values.fold<double>(0, (sum, m) => sum + m);
    final avg = total / mileageMap.length;

    debugPrint(
      'Γ¢╜ getReliableAverageMileage: $avg km/l (from ${mileageMap.length} full-tank intervals)',
    );
    return avg;
  }

  /// Overall mileage computed across the ENTIRE tracked range:
  /// total distance (first full tank odo -> last full tank odo) divided by
  /// total fuel consumed in that range (excludes the very first full tank's
  /// own fuel, since that fuel fills the tank to start the range, not
  /// "consumed" within it). Useful for a single headline stat.
  double getOverallMileage() {
    final fuelEntries = _currentBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    final fullTanks = fuelEntries.where((e) => e.isFullTank).toList()
      ..sort((a, b) => a.odometerReading.compareTo(b.odometerReading));

    if (fullTanks.length < 2) {
      return 0.0;
    }

    final firstOdo = fullTanks.first.odometerReading;
    final lastOdo = fullTanks.last.odometerReading;
    final totalDist = lastOdo - firstOdo;

    if (totalDist <= 0) {
      return 0.0;
    }

    // Sum fuel for all entries with odometer > firstOdo and <= lastOdo
    double totalFuel = 0.0;
    for (final e in fuelEntries) {
      if (e.odometerReading > firstOdo && e.odometerReading <= lastOdo) {
        totalFuel += e.fuelQuantity;
      }
    }

    if (totalFuel <= 0) {
      return 0.0;
    }

    return totalDist / totalFuel;
  }

  int getTotalFillups() {
    final count = _currentBikeEntries
        .where((e) => e.category?.toLowerCase() == 'fuel')
        .length;
    debugPrint('≡ƒöó getTotalFillups: $count');
    return count;
  }

  double getKmTraveled() {
    double totalDistance = 0;

    // Calculate from odometer difference if we have entries
    if (_currentBikeEntries.isNotEmpty) {
      // Use min/max odometer rather than first/last by date, since the
      // list order is not guaranteed to be chronological by odometer.
      double minOdo = _currentBikeEntries.first.odometerReading;
      double maxOdo = _currentBikeEntries.first.odometerReading;
      for (final e in _currentBikeEntries) {
        if (e.odometerReading < minOdo) minOdo = e.odometerReading;
        if (e.odometerReading > maxOdo) maxOdo = e.odometerReading;
      }
      totalDistance += (maxOdo - minOdo).abs();
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

  // Statistics
  double getTotalFuelCost() {
    final total = _currentBikeEntries.fold<double>(
      0,
      (sum, entry) =>
          sum +
          ((entry.category?.toLowerCase() == 'fuel') ? entry.fuelAmount : 0),
    );
    debugPrint(
      '≡ƒÆ░ getTotalFuelCost: $total (from ${_currentBikeEntries.length} entries)',
    );
    return total;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Sync current bike data to Android widgets and Android Auto
  Future<void> _syncToWidgets() async {
    final bike = dashboardDisplayBike;
    if (bike == null) { return; }

    // Get latest fuel entry for this bike
    final fuelEntries = _currentBikeEntries
        .where((e) => (e.category ?? 'fuel').toLowerCase() == 'fuel')
        .toList();

    String lastFuelDate = 'N/A';
    double lastFuelPrice = 0;

    if (fuelEntries.isNotEmpty) {
      final lastEntry = fuelEntries.first;
      lastFuelDate = DateFormat('dd MMM').format(lastEntry.date);
      if (lastEntry.fuelQuantity > 0) {
        lastFuelPrice = lastEntry.fuelAmount / lastEntry.fuelQuantity;
      }
    }

    final mileage = getDashboardReliableAverageMileage();

    // Update Home Screen Widget
    await HomeScreenWidgetService.updateGarageWidget(
      vehicleName: bike.name,
      odometer: bike.currentOdometer,
      mileage: mileage,
      lastFuelDate: lastFuelDate,
      fuelPrice: lastFuelPrice,
    );

    // Update Android Auto
    await AndroidAutoService.updateGarageData(
      vehicleName: bike.name,
      odometer: bike.currentOdometer,
      mileage: mileage,
      lastFuelPrice: lastFuelPrice,
      lastFuelDate: lastFuelDate,
    );

    debugPrint('≡ƒöä Synced bike data to widgets: ${bike.name}');
  }

  void clear() {
    _bikesSubscription?.cancel();
    _deletedBikesSubscription?.cancel();
    _entriesSubscription?.cancel();
    _dashboardEntriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    _bikes = [];
    _deletedBikes = [];
    _currentBikeEntries = [];
    _dashboardBikeEntries = [];
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
      _loadDashboardBikeEntries(user.uid);
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
    _dashboardEntriesSubscription?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }

}
