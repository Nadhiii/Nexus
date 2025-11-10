import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/detected_transaction.dart';

class NBoxProvider extends ChangeNotifier {
  final List<DetectedTransaction> _pending = [];
  final Set<String> _processedIds = {}; // IDs that were already processed
  final Set<String> _rejectedIds = {}; // IDs that were rejected
  final bool _isLoading = false;

  List<DetectedTransaction> get pending => List.unmodifiable(_pending);
  int get pendingCount => _pending.length;
  bool get isLoading => _isLoading;

  NBoxProvider() {
    _loadProcessedIds();
  }

  // Load processed and rejected IDs from SharedPreferences
  Future<void> _loadProcessedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList('nbox_processed') ?? [];
    final rejected = prefs.getStringList('nbox_rejected') ?? [];
    _processedIds.addAll(processed);
    _rejectedIds.addAll(rejected);
  }

  // Save processed IDs to SharedPreferences
  Future<void> _saveProcessedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nbox_processed', _processedIds.toList());
    await prefs.setStringList('nbox_rejected', _rejectedIds.toList());
  }

  // Mark transaction as approved and remove from pending
  Future<void> approve(String id) async {
    _pending.removeWhere((e) => e.id == id);
    _processedIds.add(id);
    await _saveProcessedIds();
    notifyListeners();
  }

  // Mark transaction as rejected and remove from pending
  Future<void> reject(String id) async {
    _pending.removeWhere((e) => e.id == id);
    _processedIds.add(id);
    _rejectedIds.add(id);
    await _saveProcessedIds();
    notifyListeners();
  }

  // Approve all pending transactions
  Future<void> approveAll() async {
    for (final item in _pending) {
      _processedIds.add(item.id);
    }
    _pending.clear();
    await _saveProcessedIds();
    notifyListeners();
  }

  // Clear all pending (mark as processed but not rejected)
  Future<void> clearAll() async {
    for (final item in _pending) {
      _processedIds.add(item.id);
    }
    _pending.clear();
    await _saveProcessedIds();
    notifyListeners();
  }

  // Add detected transactions (filtering out duplicates and rejected)
  void addDetectedAll(Iterable<DetectedTransaction> items) {
    for (final item in items) {
      // Skip if already processed or rejected
      if (_processedIds.contains(item.id) || _rejectedIds.contains(item.id)) {
        continue;
      }

      // Skip if already in pending list
      if (_pending.any((p) => p.id == item.id)) {
        continue;
      }

      _pending.add(item);
    }

    // Sort by date (newest first)
    _pending.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // Clear rejected list (for testing purposes)
  Future<void> clearRejectedList() async {
    _rejectedIds.clear();
    await _saveProcessedIds();
    notifyListeners();
  }
}
