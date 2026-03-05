import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Google Sign-In
  GoogleSignIn _initializeGoogleSignIn() {
    if (_googleSignIn != null) { return _googleSignIn!; }
    
    try {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      return _googleSignIn!;
    } catch (e) {
      debugPrint('Failed to initialize Google Sign-In: $e');
      rethrow;
    }
  }

  // SIGN IN WITH GOOGLE
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Firebase Auth provider
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        
        final userCredential = await _auth.signInWithPopup(provider);
        return userCredential.user;
      } else {
        // Mobile: Try google_sign_in package first, then fallback to Firebase provider
        try {
          final googleSignIn = _initializeGoogleSignIn();
          
          debugPrint('Starting Google Sign-In...');
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          
          if (googleUser == null) {
            debugPrint('User cancelled Google Sign-In');
            throw Exception('Sign-in was cancelled');
          }

          debugPrint('Google account selected: ${googleUser.email}');
          debugPrint('Getting authentication tokens...');
          
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

          debugPrint('Access token available: ${googleAuth.accessToken != null}');
          debugPrint('ID token available: ${googleAuth.idToken != null}');

          if (googleAuth.accessToken == null || googleAuth.idToken == null) {
            debugPrint('Missing authentication tokens');
            throw Exception('Failed to get authentication tokens from Google');
          }

          debugPrint('Creating Firebase credential...');
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          debugPrint('Signing in to Firebase...');
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          
          debugPrint('Firebase sign-in successful: ${userCredential.user?.email}');
          return userCredential.user;
          
        } catch (e) {
          debugPrint('Google Sign-In package error: $e');
          
          // More specific error handling based on the error type
          if (e.toString().contains('cancelled')) {
            throw Exception('Sign-in was cancelled');
          } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
            throw Exception('Network error. Please check your internet connection and try again');
          } else if (e.toString().contains('invalid_request') || e.toString().contains('invalid_client')) {
            throw Exception('Configuration error. The app needs to be properly configured for Google Sign-In');
          } else if (e.toString().contains('account-exists-with-different-credential')) {
            throw Exception('An account already exists with this email. Please sign in using a different method');
          }
          
          // Fallback: Try Firebase Auth's signInWithProvider
          try {
            debugPrint('Attempting fallback with Firebase signInWithProvider');
            final provider = GoogleAuthProvider();
            provider.addScope('email');
            provider.addScope('profile');
            
            final userCredential = await _auth.signInWithProvider(provider);
            debugPrint('Firebase fallback successful: ${userCredential.user?.email}');
            return userCredential.user;
          } catch (fallbackError) {
            debugPrint('Firebase signInWithProvider also failed: $fallbackError');
            
            // Check if it's a Google Play Services issue
            if (e.toString().contains('SIGN_IN_REQUIRED') || 
                e.toString().contains('GoogleSignInApi') ||
                e.toString().contains('Google Play Services') ||
                e.toString().contains('Null is not a subtype')) {
              throw Exception('Google Play Services is not available or needs to be updated. Please try "Use without account" option.');
            }
            
            // If both methods fail, provide a generic but helpful error
            throw Exception('Google Sign-In failed. This might be due to app configuration or temporary Google services issues. Please try "Use without account" option.');
          }
        }
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow; // Rethrow to show the error to the user
    }
  }

  // SIGN IN ANONYMOUSLY
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      // Sign out from Google Sign-In if user was signed in with Google
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
