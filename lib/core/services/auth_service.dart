import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- REPLACE THIS WITH YOUR WEB CLIENT ID ---
  // Source: Google Cloud Console → APIs & Services → Credentials
  // → "Web client (auto created by Google Service)" → copy the Client ID
  // Looks like: 1234567890-xxxxxxxxxxxxxxxx.apps.googleusercontent.com
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  // --------------------------------------------

  bool _googleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _googleSignInInitialized = true;
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(provider);
        return userCredential.user;
      }

      try {
        debugPrint('Starting Google Sign-In (v7)...');

        await _ensureGoogleSignInInitialized();

        // v7: authenticate() replaces signIn()
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        debugPrint('Google account selected: ${googleUser.email}');

        // Get authorization with scopes to retrieve access token
        final authorization = await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile']);

        debugPrint(
          'Access token available: ${authorization.accessToken.isNotEmpty}',
        );

        // idToken is still available via the authentication getter in v7
        final idToken = googleUser.authentication.idToken;

        if (authorization.accessToken.isEmpty || idToken == null) {
          throw Exception(
            'Failed to get authentication tokens from Google',
          );
        }

        debugPrint('Creating Firebase credential...');
        final credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: idToken,
        );

        debugPrint('Signing in to Firebase...');
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        debugPrint(
          'Firebase sign-in successful: ${userCredential.user?.email}',
        );
        return userCredential.user;
      } catch (e) {
        debugPrint('Google Sign-In v7 error: $e');

        if (e is GoogleSignInException) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            throw Exception('Sign-in was cancelled');
          } else if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
            throw Exception(
              'Google Sign-In UI is not available. Please try again.',
            );
          } else if (e.code ==
              GoogleSignInExceptionCode.clientConfigurationError) {
            throw Exception(
              'Google Sign-In is not configured correctly. '
              'Please ensure the Web Client ID is set and SHA fingerprints '
              'are registered in Firebase Console.',
            );
          }
        }

        if (e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          throw Exception(
            'Network error. Please check your connection and try again.',
          );
        }

        // Rethrow — do not silently fall through to Firebase provider
        // since that path also fails when cert hash is invalid.
        rethrow;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}