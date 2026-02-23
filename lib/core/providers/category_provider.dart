import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';

/// Manages user-defined and default transaction categories.
class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _categorySubscription;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryProvider() {
    _loadCategories();
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }

  /// Loads both default and user-defined categories with real-time updates.
  Future<void> _loadCategories() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Cancel previous subscription
      await _categorySubscription?.cancel();

      // Listen to real-time updates for user categories
      _categorySubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .snapshots()
          .listen(
            (snapshot) {
              // Start with a list of default, non-custom categories
              final List<Category> defaultCategories = _getDefaultCategories();

              final userCategories = snapshot.docs.map((doc) {
                return Category.fromMap(doc.id, doc.data());
              }).toList();

              // Combine and sort the lists
              _categories = [...defaultCategories, ...userCategories];
              _categories.sort((a, b) => a.name.compareTo(b.name));

              _isLoading = false;
              _error = null;
              notifyListeners();
            },
            onError: (e) {
              _error = 'Error loading categories: $e';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _error = 'Error setting up categories: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh categories (useful after auth changes)
  Future<void> refresh() async {
    await _loadCategories();
  }

  /// Adds a new custom category to Firestore.
  Future<void> addCategory(Category category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .add(category.toMap());
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error adding category: $e';
      notifyListeners();
    }
  }

  /// Updates an existing custom category in Firestore.
  Future<void> updateCategory(Category category) async {
    final user = _auth.currentUser;
    if (user == null || !category.isCustom) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error updating category: $e';
      notifyListeners();
    }
  }

  /// Deletes a custom category from Firestore.
  Future<void> deleteCategory(String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .delete();
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error deleting category: $e';
      notifyListeners();
    }
  }

  /// Returns a list of default categories that are not user-modifiable.
  List<Category> _getDefaultCategories() {
    return [
      // --- INCOME ---
      Category(
        id: 'salary',
        name: 'Salary',
        emoji: '💰',
        color: Colors.green,
        isCustom: false,
      ),
      Category(
        id: 'investment',
        name: 'Investment',
        emoji: '📈',
        color: Colors.teal,
        isCustom: false,
      ),

      // --- ESSENTIALS ---
      Category(
        id: 'food',
        name: 'Food & Dining',
        emoji: '🍔',
        color: Colors.red,
        isCustom: false,
      ),
      Category(
        id: 'groceries',
        name: 'Groceries',
        emoji: '🛒',
        color: Colors.lightGreen,
        isCustom: false,
      ),
      Category(
        id: 'bills',
        name: 'Bills & Utilities',
        emoji: '🧾',
        color: Colors.purple,
        isCustom: false,
      ),
      Category(
        id: 'health',
        name: 'Healthcare',
        emoji: '🏥',
        color: Colors.greenAccent,
        isCustom: false,
      ),
      Category(
        id: 'education',
        name: 'Education',
        emoji: '📚',
        color: Colors.indigo,
        isCustom: false,
      ),

      // --- LIFESTYLE & GARAGE ---
      Category(
        id: 'garage',
        name: 'Vehicle & Garage',
        emoji: '🏍️',
        color: Colors.deepOrange,
        isCustom: false,
      ),
      Category(
        id: 'transport',
        name: 'Transit & Cabs',
        emoji: '🚇',
        color: Colors.blue,
        isCustom: false,
      ),
      Category(
        id: 'tech',
        name: 'Electronics & Tech',
        emoji: '💻',
        color: Colors.blueGrey,
        isCustom: false,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        emoji: '🛍️',
        color: Colors.orange,
        isCustom: false,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        emoji: '🎬',
        color: Colors.pink,
        isCustom: false,
      ),
      Category(
        id: 'travel',
        name: 'Travel & Trips',
        emoji: '🏕️',
        color: Colors.cyan,
        isCustom: false,
      ),

      // --- UTILITY ---
      Category(
        id: 'shared',
        name: 'Shared & Splits',
        emoji: '🤝',
        color: Colors.amber,
        isCustom: false,
      ),
      Category(
        id: 'transfer',
        name: 'Transfer',
        emoji: '↔️',
        color: Colors.grey,
        isCustom: false,
      ),
      Category(
        id: 'other',
        name: 'Other',
        emoji: '🏷️',
        color: Colors.grey,
        isCustom: false,
      ),
      Category(
        id: 'uncategorized',
        name: 'Uncategorized',
        emoji: '📎',
        color: Colors.grey,
        isCustom: false,
      ),
    ];
  }
}
