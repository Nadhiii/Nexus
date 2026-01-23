class Challan {
  final String id;
  final String bikeId;
  final String userId;
  final String registrationNumber;
  final DateTime violationDate;
  final String
  violationType; // 'speeding', 'parking', 'no-helmet', 'red-light', 'other'
  final double fineAmount;
  final String location;
  final String? policeStation;
  final String? notes;
  final DateTime? paymentDeadline;
  final bool isPaid;
  final DateTime? paidDate;
  final String? receiptUrl;
  final DateTime createdAt;

  Challan({
    required this.id,
    required this.bikeId,
    required this.userId,
    required this.registrationNumber,
    required this.violationDate,
    required this.violationType,
    required this.fineAmount,
    required this.location,
    this.policeStation,
    this.notes,
    this.paymentDeadline,
    this.isPaid = false,
    this.paidDate,
    this.receiptUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bikeId': bikeId,
      'userId': userId,
      'registrationNumber': registrationNumber,
      'violationDate': violationDate.toIso8601String(),
      'violationType': violationType,
      'fineAmount': fineAmount,
      'location': location,
      'policeStation': policeStation,
      'notes': notes,
      'paymentDeadline': paymentDeadline?.toIso8601String(),
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'receiptUrl': receiptUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Challan.fromFirestore(Map<String, dynamic> data, String id) {
    return Challan(
      id: id,
      bikeId: data['bikeId'] ?? '',
      userId: data['userId'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      violationDate: data['violationDate'] != null
          ? DateTime.parse(data['violationDate'] as String)
          : DateTime.now(),
      violationType: data['violationType'] ?? 'other',
      fineAmount: (data['fineAmount'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      policeStation: data['policeStation'],
      notes: data['notes'],
      paymentDeadline: data['paymentDeadline'] != null
          ? DateTime.parse(data['paymentDeadline'] as String)
          : null,
      isPaid: data['isPaid'] ?? false,
      paidDate: data['paidDate'] != null
          ? DateTime.parse(data['paidDate'] as String)
          : null,
      receiptUrl: data['receiptUrl'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Challan copyWith({
    String? id,
    String? bikeId,
    String? userId,
    String? registrationNumber,
    DateTime? violationDate,
    String? violationType,
    double? fineAmount,
    String? location,
    String? policeStation,
    String? notes,
    DateTime? paymentDeadline,
    bool? isPaid,
    DateTime? paidDate,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return Challan(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      userId: userId ?? this.userId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      violationDate: violationDate ?? this.violationDate,
      violationType: violationType ?? this.violationType,
      fineAmount: fineAmount ?? this.fineAmount,
      location: location ?? this.location,
      policeStation: policeStation ?? this.policeStation,
      notes: notes ?? this.notes,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
