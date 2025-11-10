import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user data from Firebase Auth and Firestore
  Future<void> loadUserProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try to get user profile from Firestore first
      try {
        final profile = await FirestoreService.getUserProfile(user.uid);
        _userProfile = profile;
      } catch (e) {
        // If no profile exists in Firestore, create one from Firebase Auth data
        _userProfile = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          isAnonymous: user.isAnonymous,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save the new profile to Firestore
        await FirestoreService.saveUserProfile(_userProfile!);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userProfile == null) {
        throw Exception('User not authenticated');
      }

      // Update Firebase Auth profile if display name or photo changed
      if (displayName != null || photoUrl != null) {
        await user.updateDisplayName(displayName ?? user.displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
      }

      // Update email if provided and different
      if (email != null && email != user.email) {
        await user.updateEmail(email);
      }

      // Update the local profile
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await FirestoreService.saveUserProfile(_userProfile!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Clear user data on sign out
  void clearUserData() {
    _userProfile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
