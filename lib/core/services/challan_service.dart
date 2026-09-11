// ignore_for_file: avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/challan.dart';
import 'package:flutter/foundation.dart';

class ChallanService {
  static const String _challansCollection = 'challans';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    try {
      final challanId = const Uuid().v4();
      final challan = Challan(
        id: challanId,
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
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_challansCollection)
          .doc(challanId)
          .set(challan.toJson());

      return challan;
    } catch (e) {
      debugPrint('❌ Challan Creation Error: $e');
      return null;
    }
  }

  /// Fetch all challans for a vehicle
  Future<List<Challan>> getVehicleChallans(String bikeId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];
      final snapshot = await _firestore
          .collection(_challansCollection)
          .where('userId', isEqualTo: userId)
          .where('bikeId', isEqualTo: bikeId)
          .orderBy('violationDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Challan.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching challans: $e');
      return [];
    }
  }

  /// Fetch unpaid challans for a vehicle
  Future<List<Challan>> getUnpaidChallans(String bikeId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];
      final snapshot = await _firestore
          .collection(_challansCollection)
          .where('userId', isEqualTo: userId)
          .where('bikeId', isEqualTo: bikeId)
          .where('isPaid', isEqualTo: false)
          .orderBy('violationDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Challan.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching unpaid challans: $e');
      return [];
    }
  }

  /// Mark challan as paid
  Future<bool> markChallanAsPaid(String challanId, {String? receiptUrl}) async {
    try {
      await _firestore.collection(_challansCollection).doc(challanId).update({
        'isPaid': true,
        'paidDate': DateTime.now().toIso8601String(),
        'receiptUrl': receiptUrl,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error marking challan as paid: $e');
      return false;
    }
  }

  /// Delete a challan
  Future<bool> deleteChallan(String challanId) async {
    try {
      await _firestore.collection(_challansCollection).doc(challanId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting challan: $e');
      return false;
    }
  }

  /// Get pending/overdue challans
  List<Challan> getOverdueChallans(List<Challan> challans) {
    final now = DateTime.now();
    return challans.where((challan) {
      if (challan.isPaid) {
        return false;
      }
      if (challan.paymentDeadline == null) {
        return false;
      }
      return challan.paymentDeadline!.isBefore(now);
    }).toList();
  }

  /// Get challans expiring soon (7 days)
  List<Challan> getExpiringChallans(
    List<Challan> challans, {
    int daysWarning = 7,
  }) {
    final now = DateTime.now();
    final warningDate = now.add(Duration(days: daysWarning));

    return challans.where((challan) {
      if (challan.isPaid) {
        return false;
      }
      if (challan.paymentDeadline == null) {
        return false;
      }
      return challan.paymentDeadline!.isBefore(warningDate) &&
          challan.paymentDeadline!.isAfter(now);
    }).toList();
  }

  /// Calculate total pending fine amount for a vehicle
  double getTotalPendingFines(List<Challan> challans) {
    return challans
        .where((c) => !c.isPaid)
        .fold(0, (sum, c) => sum + c.fineAmount);
  }
}
