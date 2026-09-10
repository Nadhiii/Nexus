import 'package:flutter/material.dart';
import 'dart:io';
import '../models/challan.dart';
import '../models/vehicle_document.dart';
import '../services/challan_service.dart';
import '../services/vehicle_document_service.dart';

class VehicleManagementProvider extends ChangeNotifier {
  final ChallanService _challanService = ChallanService();
  final VehicleDocumentService _documentService = VehicleDocumentService();
  List<VehicleDocument> _documents = [];

  // State variables
  List<Challan> _challans = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Challan> get challans => _challans;
  bool get isLoading => _isLoading;
  String get error => _error;
  List<VehicleDocument> get documents => List.unmodifiable(_documents);
  List<VehicleDocument> get rcDocuments => _byType('rc');
  List<VehicleDocument> get insuranceDocuments => _byType('insurance');
  List<VehicleDocument> get pollutionDocuments => _byType('pollution');
  List<VehicleDocument> get expiringDocuments =>
      _documentService.getExpiringDocuments(_documents);
  List<VehicleDocument> get expiredDocuments =>
      _documentService.getExpiredDocuments(_documents);

  List<VehicleDocument> _byType(String type) =>
      _documents.where((document) => document.documentType == type).toList();

  Future<void> fetchVehicleDocuments(String bikeId) async {
    _documents = await _documentService.getVehicleDocuments(bikeId);
    notifyListeners();
  }

  Future<VehicleDocument?> registerDocument({
    required String bikeId,
    required String userId,
    required String documentType,
    required String fileName,
    DateTime? expiryDate,
    String? description,
    int fileSizeBytes = 0,
  }) async {
    final document = await _documentService.registerDocument(
      bikeId: bikeId,
      userId: userId,
      documentType: documentType,
      fileName: fileName,
      expiryDate: expiryDate,
      description: description,
      fileSizeBytes: fileSizeBytes,
    );
    if (document != null) {
      _documents = [..._documents, document];
      notifyListeners();
    }
    return document;
  }

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
