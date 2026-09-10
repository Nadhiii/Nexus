import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _categorySubscription;

  List<Category> _categories = [];
  List<Category> _hiddenCategories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;

  /// Default categories the user has swiped-deleted (hidden). Shown in
  /// the "Hidden" filter so they can be restored via unhideCategory().
  List<Category> get hiddenCategories => _hiddenCategories;

  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryProvider() {
    _categories = _getDefaultCategories();
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }

  /// Loads both default and user-defined categories with real-time updates.
  Future<void> _loadCategories() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

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
              final List<Category> defaultCategories = _getDefaultCategories();
              final defaultIds = defaultCategories.map((c) => c.id).toSet();

              final userDocs = {
                for (final doc in snapshot.docs) doc.id: doc.data(),
              };

              final List<Category> hidden = [];

              // Merge defaults with any user overrides (edits/hides).
              final mergedDefaults = defaultCategories
                  .map((def) {
                    final override = userDocs[def.id];
                    if (override == null) {
                      return def;
                    }
                    if (override['hidden'] == true) {
                      // User "deleted" this default -> hide it, but keep
                      // it around (with its last known name/emoji/color)
                      // so it can be shown in the Hidden filter.
                      hidden.add(
                        Category.fromMap(def.id, {
                          ...override,
                          'is_custom': false,
                        }),
                      );
                      return null;
                    }
                    // Apply override fields on top of the default,
                    // but a default category always stays isCustom: false
                    // so it renders/behaves as "Editable Default".
                    return Category.fromMap(def.id, {
                      ...override,
                      'is_custom': false,
                    }, isModified: true);
                  })
                  .whereType<Category>()
                  .toList();

              // True custom categories: doc id is not a default id,
              // and not hidden.
              final customCategories = userDocs.entries
                  .where(
                    (e) =>
                        !defaultIds.contains(e.key) &&
                        e.value['hidden'] != true,
                  )
                  .map((e) => Category.fromMap(e.key, e.value))
                  .toList();

              // Combine and sort the lists
              _categories = [...mergedDefaults, ...customCategories];
              _categories.sort((a, b) => a.name.compareTo(b.name));

              _hiddenCategories = hidden
                ..sort((a, b) => a.name.compareTo(b.name));

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

  /// Clears user-scoped state on logout. The next authenticated session
  /// calls refresh() from AuthGate.
  void clear() {
    _categorySubscription?.cancel();
    _categorySubscription = null;
    // Keep the built-in categories available immediately after logout/login
    // transitions. The authenticated refresh will replace them with the
    // merged Firestore-backed list once it arrives.
    _categories = _getDefaultCategories();
    _hiddenCategories = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh categories (useful after auth changes)
  Future<void> refresh() async {
    await _loadCategories();
  }

  /// Adds a new custom category to Firestore.
  Future<void> addCategory(Category category) async {
    _error = null;
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.id);
      await ref.set(category.toMap());
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error adding category: $e';
      notifyListeners();
    }
  }

  /// Updates an existing category in Firestore.
  ///
  /// Works for BOTH true custom categories and overrides of default
  /// categories, since a default category id has no existing document
  /// yet. Uses set(merge: true) instead of update() — update() throws
  /// on a non-existent doc, which is why edits to default categories
  /// used to silently fail.
  Future<void> updateCategory(Category category) async {
    _error = null;
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.id)
          .set(category.toMap(), SetOptions(merge: true));
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error updating category: $e';
      notifyListeners();
    }
  }

  /// Deletes (or hides) a category.
  ///
  /// - True custom category -> the Firestore doc is deleted outright.
  /// - Default category -> can't be deleted (it isn't a real doc and
  ///   legacy category routing may still route transactions to its id),
  ///   so we mark it 'hidden' instead. It moves into hiddenCategories
  ///   and disappears from the main list, but the id stays reserved
  ///   and can be restored via unhideCategory().
  Future<void> deleteCategory(
    String categoryId, {
    bool isDefault = false,
  }) async {
    _error = null;
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId);

      if (isDefault) {
        await ref.set({'hidden': true}, SetOptions(merge: true));
      } else {
        await ref.delete();
      }
      // Stream will auto-update the list
    } catch (e) {
      _error = 'Error deleting category: $e';
      notifyListeners();
    }
  }

  /// Restores a previously hidden default category back to visible.
  Future<void> unhideCategory(String categoryId) async {
    _error = null;
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .set({'hidden': false}, SetOptions(merge: true));
    } catch (e) {
      _error = 'Error restoring category: $e';
      notifyListeners();
    }
  }

  /// Returns a list of default categories that are not user-modifiable
  /// (i.e. their base definition — users can still override name/emoji/
  /// color or hide them via updateCategory/deleteCategory above).
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

      // --- INDIA-SPECIFIC ADDITIONS ---
      Category(
        id: 'upi_p2p',
        name: 'UPI / Sent to Person',
        emoji: '📲',
        color: Colors.deepPurple,
        isCustom: false,
      ),
      Category(
        id: 'rent',
        name: 'Rent',
        emoji: '🏠',
        color: Colors.brown,
        isCustom: false,
      ),
      Category(
        id: 'insurance',
        name: 'Insurance & PF',
        emoji: '🛡️',
        color: Colors.blueAccent,
        isCustom: false,
      ),
      Category(
        id: 'donation',
        name: 'Donations & Religious',
        emoji: '🙏',
        color: Colors.amberAccent,
        isCustom: false,
      ),
      Category(
        id: 'family',
        name: 'Family Support',
        emoji: '👨‍👩‍👧',
        color: Colors.pinkAccent,
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
