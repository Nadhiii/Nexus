import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle_document.dart';
import 'google_drive_service.dart';
import 'package:flutter/foundation.dart';

class VehicleDocumentService {
  static const String _vehicleDocumentsCollection = 'vehicle_documents';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleDriveService _driveService;

  VehicleDocumentService({GoogleDriveService? driveService})
    : _driveService = driveService ?? GoogleDriveService();

  /// Upload a document file to Google Drive and register in Firestore
  Future<VehicleDocument?> uploadDocument({
    required String bikeId,
    required String userId,
    required String documentType,
    required File file,
    required DateTime? expiryDate,
    String? description,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final documentId = const Uuid().v4();

      debugPrint('📤 Uploading document to Google Drive...');
      // Upload to Google Drive
      final driveFileId = await _driveService.uploadVehicleDocument(
        file: file,
        bikeId: bikeId,
        documentType: documentType,
      );

      if (driveFileId == null) {
        debugPrint('❌ Failed to upload to Google Drive');
        return null;
      }

      // Generate shareable link
      final fileUrl = GoogleDriveService.getGoogleDriveFileUrl(driveFileId);

      // Create document record in Firestore
      final vehicleDocument = VehicleDocument(
        id: documentId,
        bikeId: bikeId,
        userId: userId,
        documentType: documentType,
        fileName: fileName,
        fileUrl: fileUrl,
        driveFileId:
            driveFileId, // Store the Drive file ID for future reference
        uploadedAt: DateTime.now(),
        expiryDate: expiryDate,
        description: description,
        fileSizeBytes: fileSize,
      );

      await _firestore
          .collection(_vehicleDocumentsCollection)
          .doc(documentId)
          .set(vehicleDocument.toJson());

      debugPrint('✅ Document registered in Firestore');
      return vehicleDocument;
    } catch (e) {
      debugPrint('❌ Document Upload Error: $e');
      return null;
    }
  }

  /// Register a document with existing file URL
  Future<VehicleDocument?> registerDocument({
    required String bikeId,
    required String userId,
    required String documentType,
    required String fileName,
    String? fileUrl, // Can be empty initially, updated later
    String? driveFileId, // Store the Drive file ID
    required DateTime? expiryDate,
    String? description,
    int fileSizeBytes = 0,
  }) async {
    try {
      final documentId = const Uuid().v4();

      // Create document record in Firestore
      final vehicleDocument = VehicleDocument(
        id: documentId,
        bikeId: bikeId,
        userId: userId,
        documentType: documentType,
        fileName: fileName,
        fileUrl: fileUrl ?? '',
        driveFileId: driveFileId,
        uploadedAt: DateTime.now(),
        expiryDate: expiryDate,
        description: description,
        fileSizeBytes: fileSizeBytes,
      );

      await _firestore
          .collection(_vehicleDocumentsCollection)
          .doc(documentId)
          .set(vehicleDocument.toJson());

      return vehicleDocument;
    } catch (e) {
      debugPrint('❌ Document Registration Error: $e');
      return null;
    }
  }

  /// Update document with file URL (after uploading to external service)
  Future<bool> updateDocumentUrl(String documentId, String fileUrl) async {
    try {
      await _firestore
          .collection(_vehicleDocumentsCollection)
          .doc(documentId)
          .update({'fileUrl': fileUrl});
      return true;
    } catch (e) {
      debugPrint('❌ Error updating document URL: $e');
      return false;
    }
  }

  /// Fetch all documents for a specific vehicle
  Future<List<VehicleDocument>> getVehicleDocuments(String bikeId) async {
    try {
      final snapshot = await _firestore
          .collection(_vehicleDocumentsCollection)
          .where('bikeId', isEqualTo: bikeId)
          .get();

      final documents = snapshot.docs
          .map((doc) => VehicleDocument.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by uploadedAt in memory to avoid composite index requirement
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return documents;
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      return [];
    }
  }

  /// Fetch documents by type for a vehicle
  Future<List<VehicleDocument>> getVehicleDocumentsByType(
    String bikeId,
    String documentType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_vehicleDocumentsCollection)
          .where('bikeId', isEqualTo: bikeId)
          .where('documentType', isEqualTo: documentType)
          .get();

      final documents = snapshot.docs
          .map((doc) => VehicleDocument.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by uploadedAt in memory to avoid composite index requirement
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return documents;
    } catch (e) {
      debugPrint('❌ Error fetching documents by type: $e');
      return [];
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(VehicleDocument document) async {
    try {
      // Delete from Firestore
      // Note: If using external storage (Firebase, AWS, etc), delete from there first
      await _firestore
          .collection(_vehicleDocumentsCollection)
          .doc(document.id)
          .delete();

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      return false;
    }
  }

  /// Check if documents are expiring soon (within 30 days)
  List<VehicleDocument> getExpiringDocuments(
    List<VehicleDocument> documents, {
    int daysWarning = 30,
  }) {
    final now = DateTime.now();
    final warningDate = now.add(Duration(days: daysWarning));

    return documents.where((doc) {
      if (doc.expiryDate == null) { return false; }
      return doc.expiryDate!.isBefore(warningDate) &&
          doc.expiryDate!.isAfter(now);
    }).toList();
  }

  /// Check if documents are expired
  List<VehicleDocument> getExpiredDocuments(List<VehicleDocument> documents) {
    final now = DateTime.now();
    return documents.where((doc) {
      if (doc.expiryDate == null) { return false; }
      return doc.expiryDate!.isBefore(now);
    }).toList();
  }
}
