import 'package:flutter/material.dart';
import '../models/transaction.dart' as models;
import '../models/subscription.dart';
import '../models/debt.dart';

/// Service that automatically matches transactions to subscriptions and EMI payments.
/// This helps users identify recurring payments and keep their finances organized.
class TransactionMatchService {
  /// Analyze a transaction and find potential matches with existing subscriptions/debts
  static MatchResult analyzeTransaction({
    required models.Transaction transaction,
    required List<Subscription> subscriptions,
    required List<Debt> debts,
  }) {
    final matches = <PotentialMatch>[];

    // Only analyze expense transactions
    if (transaction.type != models.TransactionType.expense) {
      return MatchResult(matches: [], confidence: 0);
    }

    // Check subscription matches
    for (final subscription in subscriptions.where((s) => s.isActive)) {
      final score = _calculateMatchScore(
        transactionAmount: transaction.amount,
        transactionDescription: transaction.description ?? '',
        targetAmount: subscription.amount,
        targetName: subscription.name,
        transactionDate: transaction.date,
        targetDueDate: subscription.nextDueDate,
        frequency: subscription.frequency,
      );

      if (score > 0.5) {
        matches.add(
          PotentialMatch(
            type: MatchType.subscription,
            id: subscription.id,
            name: subscription.name,
            expectedAmount: subscription.amount,
            actualAmount: transaction.amount,
            confidence: score,
            frequency: subscription.frequency,
          ),
        );
      }
    }

    // Check EMI matches
    for (final debt in debts.where((d) => d.currentBalance > 0)) {
      if (debt.monthlyEMI == null || debt.nextPaymentDate == null) { continue; }

      final score = _calculateMatchScore(
        transactionAmount: transaction.amount,
        transactionDescription: transaction.description ?? '',
        targetAmount: debt.monthlyEMI!,
        targetName: debt.name,
        transactionDate: transaction.date,
        targetDueDate: debt.nextPaymentDate!,
        frequency: 'monthly',
      );

      if (score > 0.5) {
        matches.add(
          PotentialMatch(
            type: MatchType.emi,
            id: debt.id,
            name: '${debt.name} EMI',
            expectedAmount: debt.monthlyEMI!,
            actualAmount: transaction.amount,
            confidence: score,
            frequency: 'monthly',
          ),
        );
      }
    }

    // Sort by confidence
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));

    final topConfidence = matches.isNotEmpty ? matches.first.confidence : 0.0;

    return MatchResult(matches: matches, confidence: topConfidence);
  }

  /// Detect potential new subscriptions from transaction history
  static List<DetectedRecurring> detectRecurringPatterns({
    required List<models.Transaction> transactions,
    required List<Subscription> existingSubscriptions,
    required List<Debt> existingDebts,
  }) {
    final detected = <DetectedRecurring>[];

    // Filter expenses only
    final expenses =
        transactions
            .where((t) => t.type == models.TransactionType.expense)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (expenses.length < 3) { return detected; }

    // Group transactions by similar amount (within 5% tolerance)
    final amountGroups = <double, List<models.Transaction>>{};
    for (final tx in expenses) {
      bool matched = false;
      for (final key in amountGroups.keys.toList()) {
        if ((tx.amount - key).abs() / key < 0.05) {
          amountGroups[key]!.add(tx);
          matched = true;
          break;
        }
      }
      if (!matched) {
        amountGroups[tx.amount] = [tx];
      }
    }

    // Find patterns in each group
    for (final group in amountGroups.entries) {
      if (group.value.length < 2) { continue; }

      final txns = group.value..sort((a, b) => a.date.compareTo(b.date));

      // Calculate intervals between transactions
      final intervals = <int>[];
      for (int i = 1; i < txns.length; i++) {
        intervals.add(txns[i].date.difference(txns[i - 1].date).inDays);
      }

      if (intervals.isEmpty) { continue; }

      // Detect frequency pattern
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final frequency = _detectFrequency(avgInterval.round());

      if (frequency != null) {
        // Check if this already matches an existing subscription
        final alreadyTracked = _isAlreadyTracked(
          group.key,
          txns.last.description,
          existingSubscriptions,
          existingDebts,
        );

        if (!alreadyTracked) {
          // Use description from most recent transaction
          final commonDescription = _extractCommonDescription(txns);

          detected.add(
            DetectedRecurring(
              suggestedName: commonDescription ?? 'Recurring payment',
              amount: group.key,
              frequency: frequency,
              occurrences: txns.length,
              lastOccurrence: txns.last.date,
              transactions: txns,
              confidence: _calculatePatternConfidence(
                intervals,
                avgInterval.round(),
              ),
            ),
          );
        }
      }
    }

    // Sort by confidence and occurrences
    detected.sort((a, b) {
      final confCompare = b.confidence.compareTo(a.confidence);
      if (confCompare != 0) { return confCompare; }
      return b.occurrences.compareTo(a.occurrences);
    });

    return detected;
  }

  static double _calculateMatchScore({
    required double transactionAmount,
    required String transactionDescription,
    required double targetAmount,
    required String targetName,
    required DateTime transactionDate,
    required DateTime targetDueDate,
    required String frequency,
  }) {
    double score = 0;

    // Amount match (40% weight)
    final amountDiff = (transactionAmount - targetAmount).abs();
    final amountTolerance = targetAmount * 0.05; // 5% tolerance
    if (amountDiff <= amountTolerance) {
      score += 0.4 * (1 - (amountDiff / (amountTolerance + 0.01)));
    } else if (amountDiff <= targetAmount * 0.15) {
      // Partial score for close amounts
      score += 0.2;
    }

    // Name/description match (35% weight)
    final descLower = transactionDescription.toLowerCase();
    final nameLower = targetName.toLowerCase();
    final nameWords = nameLower.split(RegExp(r'\s+'));

    if (descLower.contains(nameLower)) {
      score += 0.35;
    } else {
      // Check word matches
      int matchedWords = 0;
      for (final word in nameWords) {
        if (word.length > 2 && descLower.contains(word)) {
          matchedWords++;
        }
      }
      if (nameWords.isNotEmpty) {
        score += 0.35 * (matchedWords / nameWords.length);
      }
    }

    // Date proximity match (25% weight)
    final daysDiff = transactionDate.difference(targetDueDate).inDays.abs();
    final periodDays = _frequencyToDays(frequency);

    if (daysDiff <= 3) {
      score += 0.25;
    } else if (daysDiff <= 7) {
      score += 0.15;
    } else if (daysDiff <= periodDays ~/ 4) {
      // Within 25% of the period
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  static int _frequencyToDays(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 1;
      case 'weekly':
        return 7;
      case 'biweekly':
        return 14;
      case 'monthly':
        return 30;
      case 'bimonthly':
        return 60;
      case 'quarterly':
        return 90;
      case '6months':
        return 180;
      case 'yearly':
        return 365;
      default:
        return 30;
    }
  }

  static String? _detectFrequency(int intervalDays) {
    if (intervalDays >= 1 && intervalDays <= 2) { return 'daily'; }
    if (intervalDays >= 5 && intervalDays <= 9) { return 'weekly'; }
    if (intervalDays >= 12 && intervalDays <= 17) { return 'biweekly'; }
    if (intervalDays >= 26 && intervalDays <= 35) { return 'monthly'; }
    if (intervalDays >= 55 && intervalDays <= 65) { return 'bimonthly'; }
    if (intervalDays >= 85 && intervalDays <= 100) { return 'quarterly'; }
    if (intervalDays >= 175 && intervalDays <= 190) { return '6months'; }
    if (intervalDays >= 350 && intervalDays <= 380) { return 'yearly'; }
    return null;
  }

  static bool _isAlreadyTracked(
    double amount,
    String? description,
    List<Subscription> subscriptions,
    List<Debt> debts,
  ) {
    // Check subscriptions
    for (final sub in subscriptions.where((s) => s.isActive)) {
      if ((sub.amount - amount).abs() / sub.amount < 0.1) {
        // Also check name similarity if description available
        if (description != null) {
          if (description.toLowerCase().contains(sub.name.toLowerCase())) {
            return true;
          }
        } else {
          return true; // Same amount, assume match
        }
      }
    }

    // Check EMIs
    for (final debt in debts.where((d) => d.currentBalance > 0)) {
      if (debt.monthlyEMI != null) {
        if ((debt.monthlyEMI! - amount).abs() / debt.monthlyEMI! < 0.1) {
          return true;
        }
      }
    }

    return false;
  }

  static String? _extractCommonDescription(List<models.Transaction> txns) {
    final descriptions = txns
        .where((t) => t.description != null && t.description!.isNotEmpty)
        .map((t) => t.description!)
        .toList();

    if (descriptions.isEmpty) { return null; }

    // Find common words
    final wordCounts = <String, int>{};
    for (final desc in descriptions) {
      final words = desc.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 2 && !_isStopWord(word)) {
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        }
      }
    }

    // Find most common meaningful word(s)
    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedWords.isNotEmpty) {
      // Use most common word(s) that appear in majority
      final threshold = descriptions.length * 0.6;
      final commonWords = sortedWords
          .where((e) => e.value >= threshold)
          .take(3)
          .map((e) => _capitalize(e.key))
          .toList();

      if (commonWords.isNotEmpty) {
        return commonWords.join(' ');
      }

      // Fall back to first word of most common
      return _capitalize(sortedWords.first.key);
    }

    return descriptions.first;
  }

  static bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'was',
      'are',
      'were',
      'been',
      'be',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'shall',
      'can',
      'need',
      'payment',
      'paid',
      'ref',
      'reference',
      'txn',
      'upi',
      'neft',
      'imps',
    };
    return stopWords.contains(word.toLowerCase());
  }

  static String _capitalize(String s) {
    if (s.isEmpty) { return s; }
    return s[0].toUpperCase() + s.substring(1);
  }

  static double _calculatePatternConfidence(
    List<int> intervals,
    int avgInterval,
  ) {
    if (intervals.isEmpty) { return 0; }

    // Calculate variance
    double variance = 0;
    for (final interval in intervals) {
      variance += (interval - avgInterval) * (interval - avgInterval);
    }
    variance /= intervals.length;
    final stdDev = variance > 0 ? variance * 0.5 : 0; // sqrt approximation

    // Lower variance = higher confidence
    final maxDeviation = avgInterval * 0.3; // Allow 30% deviation
    final normalizedDev = stdDev / (maxDeviation + 1);
    final varianceConfidence = (1 - normalizedDev).clamp(0.0, 1.0);

    // More occurrences = higher confidence
    final occurrenceBonus = (intervals.length / 6).clamp(0.0, 0.3);

    return (varianceConfidence * 0.7 + occurrenceBonus).clamp(0.0, 1.0);
  }
}

/// Result of matching a transaction to subscriptions/debts
class MatchResult {
  final List<PotentialMatch> matches;
  final double confidence;

  MatchResult({required this.matches, required this.confidence});

  bool get hasMatch => matches.isNotEmpty && confidence > 0.6;
  PotentialMatch? get bestMatch => matches.isNotEmpty ? matches.first : null;
}

enum MatchType { subscription, emi }

/// A potential match between a transaction and a tracked recurring payment
class PotentialMatch {
  final MatchType type;
  final String id;
  final String name;
  final double expectedAmount;
  final double actualAmount;
  final double confidence;
  final String frequency;

  PotentialMatch({
    required this.type,
    required this.id,
    required this.name,
    required this.expectedAmount,
    required this.actualAmount,
    required this.confidence,
    required this.frequency,
  });

  double get amountDifference => actualAmount - expectedAmount;
  bool get isExactAmount => amountDifference.abs() < 1;

  IconData get icon {
    switch (type) {
      case MatchType.subscription:
        return Icons.repeat;
      case MatchType.emi:
        return Icons.account_balance;
    }
  }

  Color get color {
    switch (type) {
      case MatchType.subscription:
        return const Color(0xFF2196F3);
      case MatchType.emi:
        return const Color(0xFF9C27B0);
    }
  }
}

/// A detected recurring pattern from transaction history
class DetectedRecurring {
  final String suggestedName;
  final double amount;
  final String frequency;
  final int occurrences;
  final DateTime lastOccurrence;
  final List<models.Transaction> transactions;
  final double confidence;

  DetectedRecurring({
    required this.suggestedName,
    required this.amount,
    required this.frequency,
    required this.occurrences,
    required this.lastOccurrence,
    required this.transactions,
    required this.confidence,
  });

  DateTime get nextPredictedDate {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return lastOccurrence.add(const Duration(days: 1));
      case 'weekly':
        return lastOccurrence.add(const Duration(days: 7));
      case 'biweekly':
        return lastOccurrence.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 1,
          lastOccurrence.day,
        );
      case 'bimonthly':
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 2,
          lastOccurrence.day,
        );
      case 'quarterly':
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 3,
          lastOccurrence.day,
        );
      case '6months':
        return DateTime(
          lastOccurrence.year,
          lastOccurrence.month + 6,
          lastOccurrence.day,
        );
      case 'yearly':
        return DateTime(
          lastOccurrence.year + 1,
          lastOccurrence.month,
          lastOccurrence.day,
        );
      default:
        return lastOccurrence.add(const Duration(days: 30));
    }
  }

  String get frequencyLabel {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Monthly';
      case 'bimonthly':
        return 'Every 2 months';
      case 'quarterly':
        return 'Quarterly';
      case '6months':
        return 'Every 6 months';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  bool get isDueInNextWeek {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return nextPredictedDate.isAfter(now) &&
        nextPredictedDate.isBefore(nextWeek);
  }
}
