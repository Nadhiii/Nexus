import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GoalProvider() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadGoals(user.uid);
    }
  }

  Future<void> loadGoals(String userId) async {
    _setLoading(true);
    try {
      _goalService
          .watchGoals(userId)
          .listen(
            (goals) {
              _goals = goals;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Error loading goals: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Error setting up goal stream: $e');
      _setLoading(false);
    }
  }

  Future<void> addGoal(Goal goal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }
    _setLoading(true);
    try {
      await _goalService.addGoal(goal.copyWith(userId: user.uid));
    } catch (e) {
      _setError('Error adding goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    _setLoading(true);
    try {
      await _goalService.updateGoal(goal);
    } catch (e) {
      _setError('Error updating goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _setLoading(true);
    try {
      await _goalService.deleteGoal(goalId);
    } catch (e) {
      _setError('Error deleting goal: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addContribution(String goalId, double amount) async {
    _setLoading(true);
    try {
      await _goalService.addContribution(goalId, amount);
    } catch (e) {
      _setError('Error adding contribution: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _goalService.clearAllGoals(user.uid);
  }

  Future<void> restoreFromBackup(List<dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final goals = data
        .map((d) => Goal.fromJson(d as Map<String, dynamic>))
        .toList();
    await _goalService.restoreGoals(user.uid, goals);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void clear() {
    _goals = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
