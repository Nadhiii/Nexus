import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LearningService {
  static const _learningsKey = 'universal_learnings_v2';
  static const _oldLearningsKey = 'smart_transaction_learnings';

  SharedPreferences? _prefs;

  // New structure: entityType → word → classification → count
  Map<String, Map<String, Map<String, int>>> _entityLearnings = {
    'transaction': {},
    'debt': {},
    'subscription': {},
    'investment': {},
    'goal': {},
    'budget': {},
    'account': {},
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLearnings();
  }

  Future<void> _loadLearnings() async {
    // Try loading new format first
    final String? learningsJson = _prefs?.getString(_learningsKey);
    
    if (learningsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(learningsJson);
        _entityLearnings = decoded.map((entityType, entityData) {
          final Map<String, dynamic> wordMap = entityData as Map<String, dynamic>;
          return MapEntry(
            entityType,
            wordMap.map((word, classifications) {
              final Map<String, dynamic> classMap = classifications as Map<String, dynamic>;
              return MapEntry(word, classMap.map((k, v) => MapEntry(k, v as int)));
            }),
          );
        });
      } catch (e) {
        _entityLearnings = {
          'transaction': {},
          'debt': {},
          'subscription': {},
          'investment': {},
          'goal': {},
          'budget': {},
          'account': {},
        };
      }
    } else {
      // Try migrating from old format
      await _migrateFromOldFormat();
    }
  }

  Future<void> _migrateFromOldFormat() async {
    final String? oldLearningsJson = _prefs?.getString(_oldLearningsKey);
    
    if (oldLearningsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(oldLearningsJson);
        final Map<String, Map<String, int>> oldData = decoded.map((key, value) {
          final Map<String, dynamic> categoryCounts = value as Map<String, dynamic>;
          return MapEntry(key, categoryCounts.map((k, v) => MapEntry(k, v as int)));
        });
        
        // Migrate to new format under 'transaction' key
        _entityLearnings['transaction'] = oldData;
        
        // Save in new format
        await _saveLearnings();
        
        // Optionally delete old key
        await _prefs?.remove(_oldLearningsKey);
      } catch (e) {
        // Migration failed, start fresh
      }
    }
  }

  Future<void> _saveLearnings() async {
    if (_prefs == null) await init();
    final String learningsJson = json.encode(_entityLearnings);
    await _prefs?.setString(_learningsKey, learningsJson);
  }

  List<String> _tokenize(String description) {
    final cleanText = description.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final words = cleanText.split(RegExp(r'\s+'));
    final stopWords = {'to', 'the', 'a', 'an', 'at', 'for', 'in', 'on', 'upi', 'ref', 'pos', 'payment', 'transfer'};
    return words.where((w) => w.length > 2 && !stopWords.contains(w)).toList();
  }

  /// Generic learning method for any entity type
  Future<void> learnEntity(String entityType, String description, String classification) async {
    if (description.trim().isEmpty || classification.trim().isEmpty) return;
    if (_prefs == null) await init();

    // Ensure entity type exists
    if (!_entityLearnings.containsKey(entityType)) {
      _entityLearnings[entityType] = {};
    }

    final tokens = _tokenize(description);

    for (final word in tokens) {
      if (!_entityLearnings[entityType]!.containsKey(word)) {
        _entityLearnings[entityType]![word] = {};
      }

      final currentCount = _entityLearnings[entityType]![word]![classification] ?? 0;
      _entityLearnings[entityType]![word]![classification] = currentCount + 1;
    }

    await _saveLearnings();
  }

  /// Generic suggestion method for any entity type
  String? suggestForEntity(String entityType, String description) {
    if (description.trim().isEmpty) return null;
    if (!_entityLearnings.containsKey(entityType)) return null;

    final tokens = _tokenize(description);
    final Map<String, int> classificationScores = {};

    for (final word in tokens) {
      final weights = _entityLearnings[entityType]![word];
      if (weights != null) {
        weights.forEach((classification, count) {
          classificationScores[classification] = (classificationScores[classification] ?? 0) + count;
        });
      }
    }

    if (classificationScores.isEmpty) return null;

    final sortedEntries = classificationScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.first.value < 2) return null;

    return sortedEntries.first.key;
  }

  /// Backward compatibility: learn transaction category
  Future<void> learn(String description, String categoryId) async {
    return learnEntity('transaction', description, categoryId);
  }

  /// Backward compatibility: suggest transaction category
  String? suggest(String description) {
    return suggestForEntity('transaction', description);
  }

  /// Clear all learnings for a specific entity type
  Future<void> clearEntityLearnings(String entityType) async {
    if (_entityLearnings.containsKey(entityType)) {
      _entityLearnings[entityType] = {};
      await _saveLearnings();
    }
  }

  /// Clear all learnings
  Future<void> clearAllLearnings() async {
    _entityLearnings = {
      'transaction': {},
      'debt': {},
      'subscription': {},
      'investment': {},
      'goal': {},
      'budget': {},
      'account': {},
    };
    await _saveLearnings();
  }

  /// Get statistics about learned data
  Map<String, int> getEntityStats(String entityType) {
    if (!_entityLearnings.containsKey(entityType)) {
      return {'words': 0, 'classifications': 0, 'totalAssociations': 0};
    }

    final entityData = _entityLearnings[entityType]!;
    final uniqueClassifications = <String>{};
    int totalAssociations = 0;

    entityData.forEach((word, classifications) {
      uniqueClassifications.addAll(classifications.keys);
      totalAssociations += classifications.values.fold(0, (sum, count) => sum + count);
    });

    return {
      'words': entityData.length,
      'classifications': uniqueClassifications.length,
      'totalAssociations': totalAssociations,
    };
  }
}