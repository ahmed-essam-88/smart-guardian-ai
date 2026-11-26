import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Minimal auth API so screens and tests do not depend on Firebase directly.
abstract class AuthApi extends ChangeNotifier {
  /// Signed-in user's email, or null.
  String? get email;

  /// False if Firebase could not start (offline config problem etc).
  bool get available;

  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

/// Error with an English message (translated on screen).
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'Wrong email or password.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Try again when you are online.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled for this app yet.';
    default:
      return 'Sign-in failed. Please try again.';
  }
}

class FirebaseAuthApi extends AuthApi {
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _sub;
  bool _available = false;

  @override
  bool get available => _available;

  @override
  String? get email => _auth?.currentUser?.email;

  /// Starts Firebase with the bundled client config. Never throws.
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: smartGuardianFirebaseOptions);
      }
      _auth = FirebaseAuth.instance;
      _available = true;
      _sub = _auth!.authStateChanges().listen((_) => notifyListeners());
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      _available = false;
    }
    notifyListeners();
  }

  Future<T> _wrap<T>(Future<T> Function() run) async {
    if (_auth == null) {
      throw const AuthFailure(
          'Sign-in service is unavailable. Check your internet connection and restart the app.');
    }
    try {
      return await run();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authErrorMessage(e.code));
    } catch (_) {
      throw const AuthFailure('Sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signIn(String email, String password) => _wrap(() =>
      _auth!.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> signUp(String email, String password) => _wrap(() =>
      _auth!.createUserWithEmailAndPassword(
          email: email.trim(), password: password));

  @override
  Future<void> sendPasswordReset(String email) =>
      _wrap(() => _auth!.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
