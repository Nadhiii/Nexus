import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crypto.dart';

class CryptoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'cryptos';

  /// Stream of user's crypto holdings
  Stream<List<Crypto>> watchCryptos(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Crypto.fromFirestore(doc)).toList(),
        );
  }

  /// Get all crypto holdings for a user
  Future<List<Crypto>> getCryptos(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Crypto.fromFirestore(doc)).toList();
  }

  /// Add a new crypto holding
  Future<String> addCrypto(Crypto crypto) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(crypto.toJson());
    return docRef.id;
  }

  /// Update an existing crypto holding
  Future<void> updateCrypto(Crypto crypto) async {
    await _firestore
        .collection(_collection)
        .doc(crypto.id)
        .update(crypto.toJson());
  }

  /// Delete a crypto holding
  Future<void> deleteCrypto(String cryptoId) async {
    await _firestore.collection(_collection).doc(cryptoId).delete();
  }

  /// Get a single crypto by ID
  Future<Crypto?> getCrypto(String cryptoId) async {
    final doc = await _firestore.collection(_collection).doc(cryptoId).get();
    if (doc.exists) {
      return Crypto.fromFirestore(doc);
    }
    return null;
  }

  /// Toggle active status of a crypto
  Future<void> toggleCryptoStatus(String cryptoId, bool isActive) async {
    await _firestore.collection(_collection).doc(cryptoId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }
}
