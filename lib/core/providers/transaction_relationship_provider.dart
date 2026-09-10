import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_relationship.dart';
import '../services/transaction_relationship_service.dart';

class TransactionRelationshipProvider extends ChangeNotifier {
  final TransactionRelationshipService _service = TransactionRelationshipService();
  StreamSubscription<List<TransactionRelationship>>? _subscription;
  List<TransactionRelationship> _relationships = [];
  bool _loading = false;
  String? _error;

  List<TransactionRelationship> get relationships => List.unmodifiable(_relationships);
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    await _subscription?.cancel();
    _loading = true;
    notifyListeners();
    _subscription = _service.watchAll().listen((items) {
      _relationships = items;
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _loading = false;
      _error = 'Failed to load transaction relationships: $error';
      notifyListeners();
    });
  }

  Future<String> save(TransactionRelationship relationship) => _service.save(relationship);

  Future<void> separate(String relationshipId) => _service.deactivate(relationshipId);

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _relationships = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
