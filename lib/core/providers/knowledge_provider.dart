import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/knowledge/merchant_knowledge.dart' show MerchantKnowledge;
import '../models/knowledge_entry.dart';
import '../services/knowledge_service.dart';
import '../services/knowledge_learning_service.dart';

/// User-controlled view of Nexus Knowledge.
class KnowledgeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final KnowledgeService _service = KnowledgeService();
  final KnowledgeLearningService _learningService = KnowledgeLearningService();
  StreamSubscription<List<KnowledgeEntry>>? _subscription;

  List<KnowledgeEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  KnowledgeProvider({FirebaseFirestore? firestore, String? userId})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userId = userId;

  CollectionReference<Map<String, dynamic>> get _merchantsCollection {
    final userId = _userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('knowledge_merchants');
  }

  List<KnowledgeEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<void> saveMerchantKnowledge(MerchantKnowledge knowledge) async {
    await _merchantsCollection
        .doc(knowledge.id)
        .set(knowledge.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteMerchantKnowledge(String id) async {
    await _merchantsCollection.doc(id).delete();
  }

  Future<void> toggleMerchantKnowledge(String id, bool disabled) async {
    await _merchantsCollection.doc(id).update({'is_disabled': disabled});
  }

  Stream<List<MerchantKnowledge>> watchAllMerchants() {
    return _merchantsCollection
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MerchantKnowledge.fromFirestore(doc.data()))
              .toList(),
        );
  }

  Future<KnowledgeStats> getStats() async {
    final snapshot = await _merchantsCollection.count().get();
    return KnowledgeStats(
      merchantCount: snapshot.count ?? 0,
      autoApprovalEligible: 0,
    );
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
}

class KnowledgeStats {
  final int merchantCount;
  final int autoApprovalEligible;

  const KnowledgeStats({
    required this.merchantCount,
    required this.autoApprovalEligible,
  });
}
