import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single trip (distance traveled) for a bike
class Trip {
  final String id;
  final String userId;
  final String bikeId;
  final DateTime date;
  final double distanceKm;
  final String notes;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.date,
    required this.distanceKm,
    this.notes = '',
    required this.createdAt,
  });

  /// Convert Trip to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bikeId': bikeId,
      'date': Timestamp.fromDate(date),
      'distanceKm': distanceKm,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create Trip from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      bikeId: data['bikeId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      distanceKm: (data['distanceKm'] as num).toDouble(),
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with modifications
  Trip copyWith({
    String? id,
    String? userId,
    String? bikeId,
    DateTime? date,
    double? distanceKm,
    String? notes,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bikeId: bikeId ?? this.bikeId,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
