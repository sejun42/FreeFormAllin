import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/log.dart';

/// Native Google Sign-In service.
///
/// Google blocks OAuth inside embedded WebViews, so the native app handles
/// sign-in via the OS-level Google Sign-In dialog, then passes the ID token
/// to the WebView's Firebase Auth via `signInWithCredential`.
class NativeAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Perform native Google Sign-In.
  ///
  /// Returns a map with `idToken` and `accessToken` that can be injected
  /// into the WebView for Firebase `signInWithCredential`.
  /// Returns null if the user cancels or sign-in fails.
  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        log.w('Google Sign-In cancelled by user');
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null) {
        log.e('Google Sign-In: no ID token received');
        return null;
      }

      log.i('Google Sign-In success: ${account.email}');

      // Also sign in to Firebase Auth natively so the app has a unified auth state
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      log.i(
        'Firebase Auth signed in: ${FirebaseAuth.instance.currentUser?.email}',
      );

      return {
        'idToken': idToken,
        'accessToken': accessToken ?? '',
        'email': account.email,
        'displayName': account.displayName ?? '',
        'photoUrl': account.photoUrl ?? '',
      };
    } catch (e) {
      log.e('Google Sign-In error', error: e);
      return null;
    }
  }

  /// Sign out from both Google and Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      log.i('Signed out from Google and Firebase');
    } catch (e) {
      log.e('Sign-out error', error: e);
    }
  }

  /// Check if user is currently signed in.
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Get current user's ID token (for WebView injection).
  Future<String?> getCurrentIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Generate JavaScript to inject auth credentials into the WebView.
  ///
  /// This calls Firebase JS SDK's `signInWithCredential` using the ID token
  /// obtained from native Google Sign-In.
  String generateAuthInjectionJs(Map<String, String> tokens) {
    final idToken = tokens['idToken'] ?? '';
    final accessToken = tokens['accessToken'] ?? '';

    return '''
(function() {
  try {
    // Check if Firebase is available
    if (typeof firebase === 'undefined' && typeof window.__FIREBASE_AUTH__ === 'undefined') {
      // Firebase JS SDK may be loaded as ESM module, try using the global auth object
      console.log('[FreeForm Native Auth] Waiting for Firebase Auth...');
    }
    
    // Store tokens for the web app to pick up
    window.__FREEFORM_NATIVE_AUTH__ = {
      idToken: '$idToken',
      accessToken: '$accessToken',
      provider: 'google',
      timestamp: Date.now()
    };
    
    // Dispatch event so AuthContext can react
    window.dispatchEvent(new CustomEvent('freeform-native-auth', {
      detail: window.__FREEFORM_NATIVE_AUTH__
    }));
    
    console.log('[FreeForm Native Auth] Credentials injected');
    return 'OK';
  } catch (e) {
    console.error('[FreeForm Native Auth] Injection error:', e);
    return 'ERROR: ' + e.message;
  }
})();
''';
  }
}

final nativeAuthServiceProvider = Provider<NativeAuthService>((ref) {
  return NativeAuthService();
});
