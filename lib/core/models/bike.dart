import 'package:cloud_firestore/cloud_firestore.dart';

class Bike {
  final String id;
  final String userId;
  final String name;
  final String make;
  final String model;
  final int year;
  final String registrationNumber;
  final double currentOdometer;
  final bool isActive;
  final DateTime createdAt;

  // RTO & detailed fields
  final String? ownerName;
  final String? fuelType;
  final String? rtoLocation;
  final String? chassisNumber;
  final String? engineNumber;
  final String? insurer;
  final DateTime? policyExpiry;

  // Dashboard and display properties
  final bool isDashboardBike;
  final int displayOrder;

  Bike({
    required this.id,
    required this.userId,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.registrationNumber,
    required this.currentOdometer,
    required this.createdAt,
    this.isActive = true,
    this.ownerName,
    this.fuelType,
    this.rtoLocation,
    this.chassisNumber,
    this.engineNumber,
    this.insurer,
    this.policyExpiry,
    this.isDashboardBike = false,
    this.displayOrder = 0,
  });

  Bike copyWith({
    String? id,
    String? userId,
    String? name,
    String? make,
    String? model,
    int? year,
    String? registrationNumber,
    double? currentOdometer,
    bool? isActive,
    DateTime? createdAt,
    String? ownerName,
    String? fuelType,
    String? rtoLocation,
    String? chassisNumber,
    String? engineNumber,
    String? insurer,
    DateTime? policyExpiry,
    bool? isDashboardBike,
    int? displayOrder,
  }) {
    return Bike(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      ownerName: ownerName ?? this.ownerName,
      fuelType: fuelType ?? this.fuelType,
      rtoLocation: rtoLocation ?? this.rtoLocation,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      insurer: insurer ?? this.insurer,
      policyExpiry: policyExpiry ?? this.policyExpiry,
      isDashboardBike: isDashboardBike ?? this.isDashboardBike,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'registrationNumber': registrationNumber,
      'currentOdometer': currentOdometer,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerName': ownerName,
      'fuelType': fuelType,
      'rtoLocation': rtoLocation,
      'chassisNumber': chassisNumber,
      'engineNumber': engineNumber,
      'insurer': insurer,
      'policyExpiry': policyExpiry != null
          ? Timestamp.fromDate(policyExpiry!)
          : null,
      'isDashboardBike': isDashboardBike,
      'displayOrder': displayOrder,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Bike.fromFirestore(DocumentSnapshot doc) {
    return Bike.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory Bike.fromMap(Map<String, dynamic> map, String docId) {
    // Helper function to parse dates from either Timestamp or String
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    }

    // Handle createdAt - use current time if missing or invalid
    DateTime createdAtValue;
    try {
      createdAtValue = parseDateTime(map['createdAt']) ?? DateTime.now();
    } catch (e) {
      createdAtValue = DateTime.now();
    }

    // Handle policyExpiry
    DateTime? policyExpiryValue;
    try {
      policyExpiryValue = parseDateTime(map['policyExpiry']);
    } catch (e) {
      policyExpiryValue = null;
    }

    return Bike(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year']?.toInt() ?? 0,
      registrationNumber: map['registrationNumber'] ?? '',
      currentOdometer: (map['currentOdometer'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: createdAtValue,
      ownerName: map['ownerName'],
      fuelType: map['fuelType'],
      rtoLocation: map['rtoLocation'],
      chassisNumber: map['chassisNumber'],
      engineNumber: map['engineNumber'],
      insurer: map['insurer'],
      policyExpiry: policyExpiryValue,
      isDashboardBike: map['isDashboardBike'] ?? false,
      displayOrder: map['displayOrder'] ?? 0,
    );
  }
}

class BikeEntry {
  final String id;
  final String userId;
  final String bikeName;
  final DateTime date;
  final double odometerReading;
  final double fuelQuantity;
  final double fuelAmount;
  final String? category;
  final String? notes;
  final double? mileage;

  // NEW: Flag to track full tank fill-ups
  final bool isFullTank;

  BikeEntry({
    required this.id,
    required this.userId,
    required this.bikeName,
    required this.date,
    required this.odometerReading,
    required this.fuelQuantity,
    required this.fuelAmount,
    this.category,
    this.notes,
    this.mileage,
    this.isFullTank = true, // Defaults to true for backward compatibility
  });

  BikeEntry copyWith({
    String? id,
    String? userId,
    String? bikeName,
    DateTime? date,
    double? odometerReading,
    double? fuelQuantity,
    double? fuelAmount,
    String? category,
    String? notes,
    double? mileage,
    bool? isFullTank,
  }) {
    return BikeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bikeName: bikeName ?? this.bikeName,
      date: date ?? this.date,
      odometerReading: odometerReading ?? this.odometerReading,
      fuelQuantity: fuelQuantity ?? this.fuelQuantity,
      fuelAmount: fuelAmount ?? this.fuelAmount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      mileage: mileage ?? this.mileage,
      isFullTank: isFullTank ?? this.isFullTank,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bikeName': bikeName,
      'date': Timestamp.fromDate(date),
      'odometerReading': odometerReading,
      'fuelQuantity': fuelQuantity,
      'fuelAmount': fuelAmount,
      'category': category,
      'notes': notes,
      'mileage': mileage,
      'isFullTank': isFullTank,
    };
  }

  factory BikeEntry.fromMap(Map<String, dynamic> map, String docId) {
    return BikeEntry(
      id: docId,
      userId: map['userId'] ?? '',
      bikeName: map['bikeName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      odometerReading: (map['odometerReading'] ?? 0).toDouble(),
      fuelQuantity: (map['fuelQuantity'] ?? 0).toDouble(),
      fuelAmount: (map['fuelAmount'] ?? 0).toDouble(),
      category: map['category'],
      notes: map['notes'],
      mileage: map['mileage'] != null ? (map['mileage']).toDouble() : null,
      // Default to true if field is missing (for old data)
      isFullTank: map['isFullTank'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory BikeEntry.fromFirestore(DocumentSnapshot doc) {
    return BikeEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
