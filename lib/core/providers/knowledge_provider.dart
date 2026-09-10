<<<<<<< Updated upstream
import 'dart:async';
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/models/knowledge/merchant_knowledge.dart'
    show MerchantKnowledge;
import 'package:nexus/core/models/knowledge_entry.dart';
>>>>>>> Stashed changes

import 'package:flutter/foundation.dart';

import '../models/knowledge_entry.dart';
import '../services/knowledge_service.dart';
import '../services/knowledge_learning_service.dart';

<<<<<<< Updated upstream
/// User-controlled view of Nexus Knowledge.
class KnowledgeProvider extends ChangeNotifier {
  final KnowledgeService _service = KnowledgeService();
  final KnowledgeLearningService _learningService = KnowledgeLearningService();
  StreamSubscription<List<KnowledgeEntry>>? _subscription;

  List<KnowledgeEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
=======
  final List<KnowledgeEntry> _entries = [];
  List<KnowledgeEntry> get entries => List.unmodifiable(_entries);
  bool isLoading = false;

  Future<void> refresh() async {
    isLoading = true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('knowledge')
          .get();
      _entries
        ..clear()
        ..addAll(snapshot.docs.map(KnowledgeEntry.fromFirestore));
    } finally {
      isLoading = false;
    }
  }

  void clear() => _entries.clear();

  Future<void> saveEntry(KnowledgeEntry entry) async {
    _entries.removeWhere((item) => item.id == entry.id);
    _entries.add(entry);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('knowledge')
        .doc(entry.id)
        .set(entry.toMap(), SetOptions(merge: true));
  }

  Future<void> forget(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('knowledge')
        .doc(id)
        .delete();
  }

  Future<void> forgetAll() async {
    for (final entry in List<KnowledgeEntry>.from(_entries)) {
      await forget(entry.id);
    }
  }

  Future<void> learnCategory({
    required String subject,
    required String categoryId,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
  }) => _learn(subject, 'category', categoryId, source, evidence);
  Future<void> learnPurpose({
    required String subject,
    required String purpose,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
  }) => _learn(subject, 'purpose', purpose, source, evidence);
  Future<void> learnCounterpartyRole({
    required String subject,
    required String role,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
  }) => _learn(subject, 'counterpartyRole', role, source, evidence);

  Future<void> _learn(
    String subject,
    String predicate,
    String object,
    KnowledgeSource source,
    List<String> evidence,
  ) => saveEntry(
    KnowledgeEntry(
      id: '${subject.toLowerCase().trim()}_$predicate',
      userId: userId,
      kind: KnowledgeKind.rule,
      source: source,
      subject: subject,
      predicate: predicate,
      object: object,
      evidence: evidence,
      confidence: source == KnowledgeSource.explicit ? 1 : .7,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  CollectionReference<Map<String, dynamic>> get _merchantsCollection =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('knowledge_merchants');

  /// Save or update merchant knowledge
  Future<void> saveMerchantKnowledge(MerchantKnowledge knowledge) async {
    await _merchantsCollection
        .doc(knowledge.id)
        .set(knowledge.toFirestore(), SetOptions(merge: true));
  }
>>>>>>> Stashed changes

  List<KnowledgeEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;

<<<<<<< Updated upstream
  Future<void> refresh() async {
    await _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _service.watchAll().listen(
      (entries) {
        _entries = entries;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load Knowledge: $error';
        notifyListeners();
      },
    );
  }

  Future<String> learnPurpose({
    required String subject,
    required String purpose,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
    Map<String, dynamic> context = const {},
    double confidence = 1.0,
  }) => _learningService.learnPurpose(
        subject: subject,
        purpose: purpose,
        source: source,
        evidence: evidence,
        context: context,
        confidence: confidence,
      );
=======
  /// Get all merchant knowledge
  Stream<List<MerchantKnowledge>> watchAllMerchants() {
    return _merchantsCollection
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
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
        .where(
          (k) =>
              k.normalizedName.contains(normalizedQuery) ||
              k.name.toLowerCase().contains(normalizedQuery),
        )
        .take(20)
        .toList();
  }
>>>>>>> Stashed changes

  Future<String> learnCounterpartyRole({
    required String subject,
    required String role,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
    Map<String, dynamic> context = const {},
    double confidence = 1.0,
  }) => _learningService.learnCounterpartyRole(
        subject: subject,
        role: role,
        source: source,
        evidence: evidence,
        context: context,
        confidence: confidence,
      );

<<<<<<< Updated upstream
  Future<String> learnCategory({
    required String subject,
    required String categoryId,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
    Map<String, dynamic> context = const {},
    double confidence = 1.0,
  }) {
    return _learningService.learnCategory(
      subject: subject,
      categoryId: categoryId,
      source: source,
      evidence: evidence,
      context: context,
      confidence: confidence,
    );
  }

  Future<String> saveEntry(KnowledgeEntry entry) => _service.save(entry);

  Future<void> forget(String id) => _service.deactivate(id);

  Future<void> forgetAll() async {
    await _service.deleteAll();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _entries = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
=======
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

  int get recognitionRate => merchantCount > 0
      ? (autoApprovalEligible / merchantCount * 100).round()
      : 0;
>>>>>>> Stashed changes
}
