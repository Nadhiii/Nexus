class VehicleDocument {
  final String id;
  final String bikeId;
  final String userId;
  final String documentType; // 'rc', 'insurance', 'pollution', 'puc', 'other'
  final String fileName;
  final String fileUrl; // Firebase Storage URL or Google Drive link
  final String? driveFileId; // Google Drive file ID
  final DateTime uploadedAt;
  final DateTime? expiryDate;
  final String? description;
  final int fileSizeBytes;

  VehicleDocument({
    required this.id,
    required this.bikeId,
    required this.userId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.driveFileId,
    required this.uploadedAt,
    this.expiryDate,
    this.description,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bikeId': bikeId,
      'userId': userId,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'driveFileId': driveFileId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'description': description,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory VehicleDocument.fromFirestore(Map<String, dynamic> data, String id) {
    return VehicleDocument(
      id: id,
      bikeId: data['bikeId'] ?? '',
      userId: data['userId'] ?? '',
      documentType: data['documentType'] ?? 'other',
      fileName: data['fileName'] ?? 'document',
      fileUrl: data['fileUrl'] ?? '',
      driveFileId: data['driveFileId'],
      uploadedAt: data['uploadedAt'] != null
          ? DateTime.parse(data['uploadedAt'] as String)
          : DateTime.now(),
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'] as String)
          : null,
      description: data['description'],
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
    );
  }

  VehicleDocument copyWith({
    String? id,
    String? bikeId,
    String? userId,
    String? documentType,
    String? fileName,
    String? fileUrl,
    String? driveFileId,
    DateTime? uploadedAt,
    DateTime? expiryDate,
    String? description,
    int? fileSizeBytes,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      driveFileId: driveFileId ?? this.driveFileId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
