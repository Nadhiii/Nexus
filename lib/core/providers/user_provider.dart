import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  UserProvider() {
    _user = FirebaseAuth.instance.currentUser;
    // Defer the listener setup to avoid calling notifyListeners during build
    Future.microtask(() {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _loadUser(user);
      });
    });
  }

  void _loadUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUser(User user) async {
    _loadUser(user);
  }
}
