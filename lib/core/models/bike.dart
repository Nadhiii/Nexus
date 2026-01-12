class BikeEntry {
  final String id;
  final String userId;
  final String bikeName;
  // It is highly recommended to add 'bikeId' here for relational linking,
  // but I have kept it matching your existing structure for now.
  final DateTime date;
  final double fuelQuantity; // in liters
  final double fuelAmount; // cost in ₹
  final double odometerReading; // in km
  final String? notes;
  final double? mileage; // calculated: fuelQuantity / km traveled
  final String? category; // fuel, maintenance, repair, insurance, etc.

  BikeEntry({
    required this.id,
    required this.userId,
    required this.bikeName,
    required this.date,
    required this.fuelQuantity,
    required this.fuelAmount,
    required this.odometerReading,
    this.notes,
    this.mileage,
    this.category,
  });

  BikeEntry copyWith({
    String? id,
    String? userId,
    String? bikeName,
    DateTime? date,
    double? fuelQuantity,
    double? fuelAmount,
    double? odometerReading,
    String? notes,
    double? mileage,
    String? category,
  }) {
    return BikeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bikeName: bikeName ?? this.bikeName,
      date: date ?? this.date,
      fuelQuantity: fuelQuantity ?? this.fuelQuantity,
      fuelAmount: fuelAmount ?? this.fuelAmount,
      odometerReading: odometerReading ?? this.odometerReading,
      notes: notes ?? this.notes,
      mileage: mileage ?? this.mileage,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bikeName': bikeName,
      'date': date.toIso8601String(),
      'fuelQuantity': fuelQuantity,
      'fuelAmount': fuelAmount,
      'odometerReading': odometerReading,
      'notes': notes,
      'mileage': mileage,
      'category': category,
      'userId': userId,
    };
  }

  factory BikeEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return BikeEntry(
      id: id,
      userId: data['userId'] ?? '',
      bikeName: data['bikeName'] ?? 'My Bike',
      date: data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : DateTime.now(),
      fuelQuantity: (data['fuelQuantity'] ?? 0).toDouble(),
      fuelAmount: (data['fuelAmount'] ?? 0).toDouble(),
      odometerReading: (data['odometerReading'] ?? 0).toDouble(),
      notes: data['notes'],
      mileage: data['mileage'] != null
          ? (data['mileage'] as num).toDouble()
          : null,
      category: data['category'] ?? 'fuel',
    );
  }
}

class Bike {
  final String id;
  final String userId;
  final String name; // Nickname (e.g. "My Daily Driver")
  final String model; // Model Name (e.g. "Himalayan 450")
  final int year;
  final double currentOdometer;
  final DateTime createdAt;
  final bool isActive;

  // --- NEW RTO & INSURANCE FIELDS ---
  final String registrationNumber; // Primary Identifier (e.g. KA01AB1234)
  final String make; // Manufacturer (e.g. Royal Enfield)
  final String? ownerName;
  final String? fuelType; // Petrol/Diesel/Electric
  final String? rtoLocation; // e.g. Mumbai Central
  final String? insurer; // Insurance Company
  final DateTime? policyExpiry; // Insurance Expiry Date
  final String? chassisNumber;
  final String? engineNumber;

  Bike({
    required this.id,
    required this.userId,
    required this.name,
    required this.model,
    required this.year,
    required this.currentOdometer,
    required this.createdAt,
    this.isActive = true,
    // Initialize new fields
    required this.registrationNumber,
    required this.make,
    this.ownerName,
    this.fuelType,
    this.rtoLocation,
    this.insurer,
    this.policyExpiry,
    this.chassisNumber,
    this.engineNumber,
  });

  Bike copyWith({
    String? id,
    String? userId,
    String? name,
    String? model,
    int? year,
    double? currentOdometer,
    DateTime? createdAt,
    bool? isActive,
    // Copy new fields
    String? registrationNumber,
    String? make,
    String? ownerName,
    String? fuelType,
    String? rtoLocation,
    String? insurer,
    DateTime? policyExpiry,
    String? chassisNumber,
    String? engineNumber,
  }) {
    return Bike(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      model: model ?? this.model,
      year: year ?? this.year,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      // New fields
      registrationNumber: registrationNumber ?? this.registrationNumber,
      make: make ?? this.make,
      ownerName: ownerName ?? this.ownerName,
      fuelType: fuelType ?? this.fuelType,
      rtoLocation: rtoLocation ?? this.rtoLocation,
      insurer: insurer ?? this.insurer,
      policyExpiry: policyExpiry ?? this.policyExpiry,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'model': model,
      'year': year,
      'currentOdometer': currentOdometer,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'userId': userId,
      // Serialize new fields
      'registrationNumber': registrationNumber,
      'make': make,
      'ownerName': ownerName,
      'fuelType': fuelType,
      'rtoLocation': rtoLocation,
      'insurer': insurer,
      'policyExpiry': policyExpiry?.toIso8601String(),
      'chassisNumber': chassisNumber,
      'engineNumber': engineNumber,
    };
  }

  factory Bike.fromFirestore(Map<String, dynamic> data, String id) {
    return Bike(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'My Bike',
      model: data['model'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      currentOdometer: (data['currentOdometer'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      isActive: data['isActive'] ?? true,

      // Deserialize new fields with safety checks
      registrationNumber: data['registrationNumber'] ?? '',
      make: data['make'] ?? '',
      ownerName: data['ownerName'],
      fuelType: data['fuelType'],
      rtoLocation: data['rtoLocation'],
      insurer: data['insurer'],
      policyExpiry: data['policyExpiry'] != null
          ? DateTime.parse(data['policyExpiry'] as String)
          : null,
      chassisNumber: data['chassisNumber'],
      engineNumber: data['engineNumber'],
    );
  }
}
