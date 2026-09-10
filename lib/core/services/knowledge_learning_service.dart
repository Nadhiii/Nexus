import 'knowledge_service.dart';
import '../models/knowledge_entry.dart';

/// Converts user answers/corrections into reusable Knowledge.
class KnowledgeLearningService {
  final KnowledgeService _knowledgeService;

  KnowledgeLearningService({KnowledgeService? knowledgeService})
      : _knowledgeService = knowledgeService ?? KnowledgeService();

  Future<String> learnCategory({
    required String subject,
    required String categoryId,
    required KnowledgeSource source,
    List<String> evidence = const [],
    Map<String, dynamic> context = const {},
    double confidence = 1.0,
  }) async {
    final normalizedSubject = subject.trim().toLowerCase();
    final existing = await _knowledgeService.find(
      subject: normalizedSubject,
      predicate: 'category',
      kind: KnowledgeKind.rule,
    );

    final now = DateTime.now();
    final entry = existing.isNotEmpty
        ? existing.first.copyWith(
            object: categoryId,
            source: source,
            evidence: evidence,
            context: context,
            confidence: confidence.clamp(0.0, 1.0).toDouble(),
            updatedAt: now,
            active: true,
          )
        : KnowledgeEntry(
            id: '',
            userId: _knowledgeService.currentUserId ?? '',
            kind: KnowledgeKind.rule,
            source: source,
            subject: normalizedSubject,
            predicate: 'category',
            object: categoryId,
            evidence: evidence,
            context: context,
            confidence: confidence.clamp(0.0, 1.0).toDouble(),
            createdAt: now,
            updatedAt: now,
          );

    return _knowledgeService.save(entry);
  }
  Future<String> learnPurpose({
    required String subject,
    required String purpose,
    KnowledgeSource source = KnowledgeSource.explicit,
    List<String> evidence = const [],
    Map<String, dynamic> context = const {},
    double confidence = 1.0,
  }) => _learn(
        subject: subject,
        predicate: 'purpose',
        object: purpose,
        kind: KnowledgeKind.purpose,
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
  }) => _learn(
        subject: subject,
        predicate: 'counterpartyRole',
        object: role,
        kind: KnowledgeKind.entity,
        source: source,
        evidence: evidence,
        context: context,
        confidence: confidence,
      );

  Future<String> _learn({
    required String subject,
    required String predicate,
    required String object,
    required KnowledgeKind kind,
    required KnowledgeSource source,
    required List<String> evidence,
    required Map<String, dynamic> context,
    required double confidence,
  }) async {
    final normalizedSubject = subject.trim().toLowerCase();
    final existing = await _knowledgeService.find(
      subject: normalizedSubject,
      predicate: predicate,
      kind: kind,
    );
    final now = DateTime.now();
    final entry = existing.isNotEmpty
        ? existing.first.copyWith(
            object: object,
            source: source,
            evidence: evidence,
            context: context,
            confidence: confidence.clamp(0.0, 1.0).toDouble(),
            updatedAt: now,
            active: true,
          )
        : KnowledgeEntry(
            id: '',
            userId: _knowledgeService.currentUserId ?? '',
            kind: kind,
            source: source,
            subject: normalizedSubject,
            predicate: predicate,
            object: object,
            evidence: evidence,
            context: context,
            confidence: confidence.clamp(0.0, 1.0).toDouble(),
            createdAt: now,
            updatedAt: now,
          );
    return _knowledgeService.save(entry);
  }

}
