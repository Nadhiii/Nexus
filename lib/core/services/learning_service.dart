import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LearningService {
  static const _learningsKey = 'smart_transaction_learnings';

  SharedPreferences? _prefs;

  Map<String, Map<String, int>> _wordWeights = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLearnings();
  }

  void _loadLearnings() {
    final String? learningsJson = _prefs?.getString(_learningsKey);
    if (learningsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(learningsJson);
        _wordWeights = decoded.map((key, value) {
          final Map<String, dynamic> categoryCounts = value as Map<String, dynamic>;
          return MapEntry(key, categoryCounts.map((k, v) => MapEntry(k, v as int)));
        });
      } catch (e) {
        _wordWeights = {};
      }
    }
  }

  Future<void> _saveLearnings() async {
    if (_prefs == null) await init();
    final String learningsJson = json.encode(_wordWeights);
    await _prefs?.setString(_learningsKey, learningsJson);
  }

  List<String> _tokenize(String description) {
    final cleanText = description.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final words = cleanText.split(RegExp(r'\s+'));
    final stopWords = {'to', 'the', 'a', 'an', 'at', 'for', 'in', 'on', 'upi', 'ref', 'pos', 'payment', 'transfer'};
    return words.where((w) => w.length > 2 && !stopWords.contains(w)).toList();
  }

  Future<void> learn(String description, String categoryId) async {
    if (description.trim().isEmpty) return;
    if (_prefs == null) await init();

    final tokens = _tokenize(description);

    for (final word in tokens) {
      if (!_wordWeights.containsKey(word)) {
        _wordWeights[word] = {};
      }

      final currentCount = _wordWeights[word]![categoryId] ?? 0;
      _wordWeights[word]![categoryId] = currentCount + 1;
    }

    await _saveLearnings();
  }

  String? suggest(String description) {
    if (description.trim().isEmpty) return null;

    final tokens = _tokenize(description);
    final Map<String, int> categoryScores = {};

    for (final word in tokens) {
      final weights = _wordWeights[word];
      if (weights != null) {
        weights.forEach((categoryId, count) {
          categoryScores[categoryId] = (categoryScores[categoryId] ?? 0) + count;
        });
      }
    }

    if (categoryScores.isEmpty) return null;

    final sortedEntries = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.first.value < 2) return null;

    return sortedEntries.first.key;
  }
}