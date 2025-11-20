import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';

/// Manages user-defined and default transaction categories.
class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryProvider() {
    _loadCategories();
  }

  /// Loads both default and user-defined categories.
  Future<void> _loadCategories() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Start with a list of default, non-custom categories
      final List<Category> defaultCategories = _getDefaultCategories();

      // Fetch user-specific categories from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      final userCategories = snapshot.docs.map((doc) {
        return Category.fromMap(doc.id, doc.data());
      }).toList();

      // Combine and sort the lists
      _categories = [...defaultCategories, ...userCategories];
      _categories.sort((a, b) => a.name.compareTo(b.name));

      _error = null;
    } catch (e) {
      _error = 'Error loading categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      await _loadCategories(); // Refresh the list
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
      await _loadCategories(); // Refresh the list
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
      await _loadCategories(); // Refresh the list
    } catch (e) {
      _error = 'Error deleting category: $e';
      notifyListeners();
    }
  }

  /// Returns a list of default categories that are not user-modifiable.
  List<Category> _getDefaultCategories() {
    return [
      Category(id: 'food', name: 'Food & Dining', emoji: '🍔', color: Colors.red, isCustom: false),
      Category(id: 'shopping', name: 'Shopping', emoji: '🛍️', color: Colors.orange, isCustom: false),
      Category(id: 'transport', name: 'Transportation', emoji: '🚗', color: Colors.blue, isCustom: false),
      Category(id: 'bills', name: 'Bills & Utilities', emoji: '🧾', color: Colors.purple, isCustom: false),
      Category(id: 'entertainment', name: 'Entertainment', emoji: '🎬', color: Colors.pink, isCustom: false),
      Category(id: 'health', name: 'Healthcare', emoji: '🏥', color: Colors.green, isCustom: false),
      Category(id: 'salary', name: 'Salary', emoji: '💰', color: Colors.green, isCustom: false),
      Category(id: 'investment', name: 'Investment', emoji: '📈', color: Colors.teal, isCustom: false),
      Category(id: 'other', name: 'Other', emoji: '🏷️', color: Colors.grey, isCustom: false),
      Category(id: 'uncategorized', name: 'Uncategorized', emoji: '📎', color: Colors.grey, isCustom: false),
    ];
  }
}
