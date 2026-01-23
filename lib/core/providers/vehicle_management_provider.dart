import 'package:flutter/material.dart';
import '../models/vehicle_document.dart';
import '../models/challan.dart';
import '../services/vehicle_document_service.dart';
import '../services/challan_service.dart';

class VehicleManagementProvider extends ChangeNotifier {
  final VehicleDocumentService _documentService = VehicleDocumentService();
  final ChallanService _challanService = ChallanService();

  // State variables
  List<VehicleDocument> _documents = [];
  List<Challan> _challans = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<VehicleDocument> get documents => _documents;
  List<Challan> get challans => _challans;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Document-specific getters
  List<VehicleDocument> get rcDocuments =>
      _documents.where((d) => d.documentType == 'rc').toList();
  List<VehicleDocument> get insuranceDocuments =>
      _documents.where((d) => d.documentType == 'insurance').toList();
  List<VehicleDocument> get pollutionDocuments =>
      _documents.where((d) => d.documentType == 'pollution').toList();
  List<VehicleDocument> get pucDocuments =>
      _documents.where((d) => d.documentType == 'puc').toList();
  List<VehicleDocument> get expiringDocuments =>
      _documentService.getExpiringDocuments(_documents);
  List<VehicleDocument> get expiredDocuments =>
      _documentService.getExpiredDocuments(_documents);

  // Challan-specific getters
  List<Challan> get paidChallans => _challans.where((c) => c.isPaid).toList();
  List<Challan> get unpaidChallans =>
      _challans.where((c) => !c.isPaid).toList();
  List<Challan> get overdueChallans =>
      _challanService.getOverdueChallans(_challans);
  List<Challan> get expiringChallans =>
      _challanService.getExpiringChallans(_challans);
  double get totalPendingFines =>
      _challanService.getTotalPendingFines(_challans);

  /// Fetch all documents for a vehicle
  Future<void> fetchVehicleDocuments(String bikeId) async {
    _setLoading(true);
    try {
      _documents = await _documentService.getVehicleDocuments(bikeId);
      _error = '';
    } catch (e) {
      _error = 'Failed to load documents: $e';
    }
    _setLoading(false);
  }

  /// Fetch documents by type
  Future<void> fetchDocumentsByType(String bikeId, String docType) async {
    _setLoading(true);
    try {
      _documents = await _documentService.getVehicleDocumentsByType(
        bikeId,
        docType,
      );
      _error = '';
    } catch (e) {
      _error = 'Failed to load documents: $e';
    }
    _setLoading(false);
  }

  /// Register a new document
  Future<VehicleDocument?> registerDocument({
    required String bikeId,
    required String userId,
    required String documentType,
    required String fileName,
    String? fileUrl,
    DateTime? expiryDate,
    String? description,
    int fileSizeBytes = 0,
  }) async {
    _setLoading(true);
    try {
      final doc = await _documentService.registerDocument(
        bikeId: bikeId,
        userId: userId,
        documentType: documentType,
        fileName: fileName,
        fileUrl: fileUrl,
        expiryDate: expiryDate,
        description: description,
        fileSizeBytes: fileSizeBytes,
      );

      if (doc != null) {
        _documents.add(doc);
        _error = '';
      }
      return doc;
    } catch (e) {
      _error = 'Failed to register document: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(VehicleDocument document) async {
    _setLoading(true);
    try {
      final success = await _documentService.deleteDocument(document);
      if (success) {
        _documents.removeWhere((d) => d.id == document.id);
        _error = '';
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete document: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all challans for a vehicle
  Future<void> fetchVehicleChallans(String bikeId) async {
    _setLoading(true);
    try {
      _challans = await _challanService.getVehicleChallans(bikeId);
      _error = '';
    } catch (e) {
      _error = 'Failed to load challans: $e';
    }
    _setLoading(false);
  }

  /// Create a new challan
  Future<Challan?> createChallan({
    required String bikeId,
    required String userId,
    required String registrationNumber,
    required DateTime violationDate,
    required String violationType,
    required double fineAmount,
    required String location,
    String? policeStation,
    String? notes,
    DateTime? paymentDeadline,
  }) async {
    _setLoading(true);
    try {
      final challan = await _challanService.createChallan(
        bikeId: bikeId,
        userId: userId,
        registrationNumber: registrationNumber,
        violationDate: violationDate,
        violationType: violationType,
        fineAmount: fineAmount,
        location: location,
        policeStation: policeStation,
        notes: notes,
        paymentDeadline: paymentDeadline,
      );

      if (challan != null) {
        _challans.add(challan);
        _error = '';
      }
      return challan;
    } catch (e) {
      _error = 'Failed to create challan: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark challan as paid
  Future<bool> markChallanAsPaid(String challanId, {String? receiptUrl}) async {
    try {
      final success = await _challanService.markChallanAsPaid(
        challanId,
        receiptUrl: receiptUrl,
      );
      if (success) {
        final index = _challans.indexWhere((c) => c.id == challanId);
        if (index != -1) {
          _challans[index] = _challans[index].copyWith(
            isPaid: true,
            paidDate: DateTime.now(),
            receiptUrl: receiptUrl,
          );
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to mark challan as paid: $e';
      return false;
    }
  }

  /// Delete a challan
  Future<bool> deleteChallan(String challanId) async {
    try {
      final success = await _challanService.deleteChallan(challanId);
      if (success) {
        _challans.removeWhere((c) => c.id == challanId);
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete challan: $e';
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
