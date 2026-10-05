import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over [FirebaseAuth] for email + password accounts.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits on sign in and sign out (and once on startup with the restored session).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return;
    // Best effort: the account exists either way, and the name and the
    // verification email can both be redone from inside the app.
    try {
      if (displayName.isNotEmpty) await user.updateDisplayName(displayName);
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      // Ignored on purpose, see above.
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendVerificationEmail() =>
      _requireUser().sendEmailVerification();

  /// Re-reads the account from Firebase and refreshes the ID token, so both
  /// `User.emailVerified` and the `email_verified` claim that the Firestore
  /// rules check pick up a verification done in another tab or device.
  Future<void> refreshUser() async {
    final user = _requireUser();
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> updateDisplayName(String name) async {
    final user = _requireUser();
    await user.updateDisplayName(name);
    await user.reload();
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user.');
    return user;
  }
}

/// Turns an auth failure into a sentence the user can act on.
String describeAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Choose a password with at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      case 'operation-not-allowed':
        return "Email/password sign-in isn't enabled for this Firebase project yet.";
      default:
        return error.message ?? 'Something went wrong (${error.code}).';
    }
  }
  return 'Something went wrong. Please try again.';
}
