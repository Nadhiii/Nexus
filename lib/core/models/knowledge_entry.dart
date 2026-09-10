import 'package:cloud_firestore/cloud_firestore.dart';

/// A piece of user-specific financial knowledge.
///
/// Knowledge is deliberately separate from transactions. Transactions are
/// facts; knowledge describes how Nexus should interpret those facts.
enum KnowledgeSource { explicit, observed, correction }

enum KnowledgeKind {
  entity,
  purpose,
  relationship,
  rule,
  pattern,
  exception,
}

class KnowledgeEntry {
  final String id;
  final String userId;
  final KnowledgeKind kind;
  final KnowledgeSource source;
  final String subject;
  final String predicate;
  final String object;
  final Map<String, dynamic> context;
  final List<String> evidence;
  final double confidence;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeEntry({
    required this.id,
    required this.userId,
    required this.kind,
    required this.source,
    required this.subject,
    required this.predicate,
    required this.object,
    this.context = const {},
    this.evidence = const [],
    this.confidence = 0.5,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeEntry.fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return KnowledgeEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      kind: KnowledgeKind.values.firstWhere(
        (value) => value.name == data['kind'],
        orElse: () => KnowledgeKind.rule,
      ),
      source: KnowledgeSource.values.firstWhere(
        (value) => value.name == data['source'],
        orElse: () => KnowledgeSource.observed,
      ),
      subject: data['subject'] as String? ?? '',
      predicate: data['predicate'] as String? ?? '',
      object: data['object'] as String? ?? '',
      context: Map<String, dynamic>.from(data['context'] as Map? ?? const {}),
      evidence: List<String>.from(data['evidence'] as List? ?? const []),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      active: data['active'] as bool? ?? true,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'kind': kind.name,
        'source': source.name,
        'subject': subject,
        'predicate': predicate,
        'object': object,
        'context': context,
        'evidence': evidence,
        'confidence': confidence,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  KnowledgeEntry copyWith({
    String? id,
    KnowledgeKind? kind,
    KnowledgeSource? source,
    String? subject,
    String? predicate,
    String? object,
    Map<String, dynamic>? context,
    List<String>? evidence,
    double? confidence,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeEntry(
      id: id ?? this.id,
      userId: userId,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      subject: subject ?? this.subject,
      predicate: predicate ?? this.predicate,
      object: object ?? this.object,
      context: context ?? this.context,
      evidence: evidence ?? this.evidence,
      confidence: confidence ?? this.confidence,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
