import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical Firestore identity helpers for user-owned transactions.
///
/// Transaction document IDs are authoritative. Source fingerprints are only
/// idempotency keys and must never be used as document IDs.
class TransactionPaths {
  const TransactionPaths._();

  static CollectionReference<Map<String, dynamic>> collection(
    FirebaseFirestore firestore,
    String userId,
  ) => firestore.collection('users').doc(userId).collection('transactions');

  static DocumentReference<Map<String, dynamic>> document(
    FirebaseFirestore firestore,
    String userId,
    String transactionId,
  ) => collection(firestore, userId).doc(transactionId);

  static String allocateId(FirebaseFirestore firestore, String userId) =>
      collection(firestore, userId).doc().id;
}
