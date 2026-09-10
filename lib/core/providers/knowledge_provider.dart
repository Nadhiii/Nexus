import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/knowledge_entry.dart';
import '../services/knowledge_service.dart';
import '../services/knowledge_learning_service.dart';

/// User-controlled view of Nexus Knowledge.
class KnowledgeProvider extends ChangeNotifier {
  final KnowledgeService _service = KnowledgeService();
  final KnowledgeLearningService _learningService = KnowledgeLearningService();
  StreamSubscription<List<KnowledgeEntry>>? _subscription;

  List<KnowledgeEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

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
