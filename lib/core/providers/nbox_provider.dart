import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/detected_transaction.dart';

class NBoxProvider extends ChangeNotifier {
  final List<DetectedTransaction> _pending = [];
  final Set<String> _processedSmsIds = {};
  bool _isLoading = false;
  bool _initialScanPerformed = false;

  List<DetectedTransaction> get pending => List.unmodifiable(_pending);
  int get pendingCount => _pending.length;
  bool get isLoading => _isLoading;

  NBoxProvider() {
    _loadProcessedSmsIds();
  }

  Future<void> _loadProcessedSmsIds() async {
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList('nbox_processed_sms_ids') ?? [];
    _processedSmsIds.addAll(processed);
    notifyListeners();
  }

  Future<void> _addProcessedSmsId(String id) async {
    _processedSmsIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nbox_processed_sms_ids', _processedSmsIds.toList());
  }

  void addDetectedTransactions(Iterable<DetectedTransaction> items) {
    final newItems = items.where((item) => !_processedSmsIds.contains(item.id) && !_pending.any((p) => p.id == item.id));
    if (newItems.isEmpty) return;

    final combined = [..._pending, ...newItems];
    final cleanList = <DetectedTransaction>[];

    final definitiveItems = combined.where((i) => i.isDefinitive).toList();
    final nonDefinitiveItems = combined.where((i) => !i.isDefinitive).toList();

    // Add all definitive items to the clean list
    cleanList.addAll(definitiveItems);

    // Add non-definitive items only if no matching definitive item exists
    for (final nonDefinitive in nonDefinitiveItems) {
      final hasMatch = definitiveItems.any((definitive) =>
          definitive.amount == nonDefinitive.amount &&
          definitive.date.difference(nonDefinitive.date).inMinutes.abs() < 10);
      if (!hasMatch) {
        cleanList.add(nonDefinitive);
      }
    }

    _pending.clear();
    _pending.addAll(cleanList);
    _pending.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> approveTransaction(String id) async {
    _pending.removeWhere((t) => t.id == id);
    await _addProcessedSmsId(id);
    notifyListeners();
  }

  Future<void> rejectTransaction(String id) async {
    _pending.removeWhere((t) => t.id == id);
    await _addProcessedSmsId(id);
    notifyListeners();
  }

  Future<void> approveAll() async {
    final ids = _pending.map((t) => t.id).toList();
    for (final id in ids) {
      await _addProcessedSmsId(id);
    }
    _pending.clear();
    notifyListeners();
  }

  Future<void> clearAll() async {
    final ids = _pending.map((t) => t.id).toList();
    for (final id in ids) {
      await _addProcessedSmsId(id);
    }
    _pending.clear();
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool get initialScanPerformed => _initialScanPerformed;

  void markInitialScanAsPerformed() {
    _initialScanPerformed = true;
  }
}
