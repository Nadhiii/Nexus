import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/models/knowledge/merchant_knowledge.dart';

/// Provider for persisting and retrieving Nexus Knowledge from Firestore
class KnowledgeProvider {
  final FirebaseFirestore _firestore;
  final String userId;

  KnowledgeProvider({
    required FirebaseFirestore firestore,
    required this.userId,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _merchantsCollection =>
      _firestore.collection('users').doc(userId).collection('knowledge_merchants');

  /// Save or update merchant knowledge
  Future<void> saveMerchantKnowledge(MerchantKnowledge knowledge) async {
    await _merchantsCollection.doc(knowledge.id).set(knowledge.toFirestore(), SetOptions(merge: true));
  }

  /// Get merchant knowledge by ID
  Future<MerchantKnowledge?> getMerchantKnowledge(String id) async {
    try {
      final doc = await _merchantsCollection.doc(id).get();
      if (!doc.exists) return null;
      return MerchantKnowledge.fromFirestore(doc.data()!);
    } catch (e) {
      print('Error fetching merchant knowledge: $e');
      return null;
    }
  }

  /// Get all merchant knowledge
  Stream<List<MerchantKnowledge>> watchAllMerchants() {
    return _merchantsCollection.orderBy('updated_at', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => MerchantKnowledge.fromFirestore(doc.data()))
          .toList(),
    );
  }

  /// Search merchants by name
  Future<List<MerchantKnowledge>> searchMerchants(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      final snapshot = await _merchantsCollection.limit(50).get();
      return snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => MerchantKnowledge.fromFirestore(doc.data()))
          .toList();
    }
    
    // Simple client-side filtering since Firestore doesn't support case-insensitive search well
    final snapshot = await _merchantsCollection
        .orderBy('normalized_name')
        .limit(100)
        .get();
    
    return snapshot.docs
        .where((doc) => doc.exists)
        .map((doc) => MerchantKnowledge.fromFirestore(doc.data()))
        .where((k) => k.normalizedName.contains(normalizedQuery) || 
                      k.name.toLowerCase().contains(normalizedQuery))
        .take(20)
        .toList();
  }

  /// Delete merchant knowledge
  Future<void> deleteMerchantKnowledge(String id) async {
    await _merchantsCollection.doc(id).delete();
  }

  /// Disable/enable merchant knowledge
  Future<void> toggleMerchantKnowledge(String id, bool disabled) async {
    await _merchantsCollection.doc(id).update({'is_disabled': disabled});
  }

  /// Clear all knowledge (for reset)
  Future<void> clearAllKnowledge() async {
    final merchants = await _merchantsCollection.get();
    final batch = _firestore.batch();
    
    for (var doc in merchants.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Get knowledge statistics
  Future<KnowledgeStats> getStats() async {
    final snapshot = await _merchantsCollection.count().get();
    final count = snapshot.count ?? 0;
    
    return KnowledgeStats(
      merchantCount: count,
      autoApprovalEligible: 0, // Will be calculated separately
    );
  }
}

/// Statistics about learned knowledge
class KnowledgeStats {
  final int merchantCount;
  final int autoApprovalEligible;

  KnowledgeStats({
    required this.merchantCount,
    required this.autoApprovalEligible,
  });

  int get recognitionRate => merchantCount > 0 ? (autoApprovalEligible / merchantCount * 100).round() : 0;
}
