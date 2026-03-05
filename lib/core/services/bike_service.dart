import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bike.dart';
import '../models/trip.dart';
import 'package:flutter/foundation.dart';

class BikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Watch all bikes for a user
  Stream<List<Bike>> watchBikes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
          debugPrint('BikeService: Found ${snapshot.docs.length} active bikes');
          final bikes = <Bike>[];
          for (var doc in snapshot.docs) {
            try {
              bikes.add(Bike.fromFirestore(doc));
            } catch (e) {
              debugPrint('Error parsing bike ${doc.id}: $e');
              // Skip bikes that fail to parse
            }
          }
          return bikes;
        });
  }

  // Watch ALL bikes including deleted ones (for restore functionality)
  Stream<List<Bike>> watchAllBikes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'BikeService: Found ${snapshot.docs.length} total bikes (including deleted)',
          );
          final bikes = <Bike>[];
          for (var doc in snapshot.docs) {
            try {
              final bike = Bike.fromFirestore(doc);
              debugPrint('  - ${bike.name}: isActive=${bike.isActive}');
              bikes.add(bike);
            } catch (e) {
              debugPrint('Error parsing bike ${doc.id}: $e');
            }
          }
          return bikes;
        });
  }

  // Watch all entries for a specific bike
  Stream<List<BikeEntry>> watchBikeEntries(String userId, String bikeId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BikeEntry.fromFirestore(doc);
          }).toList();
        });
  }

  // Add a new bike
  Future<String> addBike(String userId, Bike bike) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .add(bike.toJson());
    return docRef.id;
  }

  // Update a bike
  Future<void> updateBike(String userId, Bike bike) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bike.id)
        .update(bike.toJson());
  }

  // Get a single bike by ID
  Future<Bike?> getBike(String userId, String bikeId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .get();

    if (doc.exists) {
      return Bike.fromFirestore(doc);
    }
    return null;
  }

  // Delete a bike
  Future<void> deleteBike(String userId, String bikeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .delete();
  }

  // Add a bike entry (fuel, maintenance, etc.)
  Future<String> addBikeEntry(
    String userId,
    String bikeId,
    BikeEntry entry,
  ) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        .add(entry.toJson());
    return docRef.id;
  }

  // Update a bike entry
  Future<void> updateBikeEntry(
    String userId,
    String bikeId,
    BikeEntry entry,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        .doc(entry.id)
        .update(entry.toJson());
  }

  // Delete a bike entry
  Future<void> deleteBikeEntry(
    String userId,
    String bikeId,
    String entryId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        .doc(entryId)
        .delete();
  }

  // Restore (recreate) a bike entry using its original id
  Future<void> restoreBikeEntry(
    String userId,
    String bikeId,
    BikeEntry entry,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('entries')
        .doc(entry.id)
        .set(entry.toJson());
  }

  // Calculate mileage from two entries
  double calculateMileage(double fuelQuantity, double kmTraveled) {
    if (fuelQuantity <= 0 || kmTraveled <= 0) { return 0; }
    return kmTraveled / fuelQuantity;
  }

  // Watch all trips for a specific bike
  Stream<List<Trip>> watchTrips(String userId, String bikeId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('trips')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Trip.fromFirestore(doc);
          }).toList();
        });
  }

  // Add a new trip
  Future<String> addTrip(String userId, String bikeId, Trip trip) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('trips')
        .add(trip.toJson());
    return docRef.id;
  }

  // Update a trip
  Future<void> updateTrip(String userId, String bikeId, Trip trip) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('trips')
        .doc(trip.id)
        .update(trip.toJson());
  }

  // Delete a trip
  Future<void> deleteTrip(String userId, String bikeId, String tripId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('trips')
        .doc(tripId)
        .delete();
  }

  // Calculate total distance from all trips
  Future<double> calculateTotalDistanceFromTrips(
    String userId,
    String bikeId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bikes')
        .doc(bikeId)
        .collection('trips')
        .get();

    double totalDistance = 0;
    for (var doc in snapshot.docs) {
      final trip = Trip.fromFirestore(doc);
      totalDistance += trip.distanceKm;
    }
    return totalDistance;
  }
}
