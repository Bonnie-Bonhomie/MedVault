import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../barrel_export.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String pharmacyName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final appUser = AppUser(
      uid: cred.user!.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      pharmacyName: pharmacyName.trim(),
      role: role,
    );
    await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
    await cred.user!.updateDisplayName(fullName.trim());
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Turns Firebase error codes into wording a pharmacy user can act on.
  static String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is not formatted correctly.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect. Try again.';
        case 'email-already-in-use':
          return 'An account already uses this email. Sign in instead.';
        case 'weak-password':
          return 'Use a password of at least 6 characters.';
        case 'network-request-failed':
          return 'No connection. Check your network and retry.';
        default:
          return error.message ?? 'Sign-in failed. Try again.';
      }
    }
    return 'Something went wrong. Try again.';
  }
}
