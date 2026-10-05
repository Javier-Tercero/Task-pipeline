part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

/// Waiting for Firebase to report whether anyone is signed in.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Nobody is signed in. [busy], [error] and [info] describe the latest request
/// (sign in, sign up, password reset) so the login screen can show it inline.
final class Unauthenticated extends AuthState {
  final bool busy;
  final String? error;
  final String? info;
  const Unauthenticated({this.busy = false, this.error, this.info});
}

/// Trying the app without an account (an anonymous Firebase user). Has a real
/// uid and data, and can become an [Authenticated] account by signing up.
/// [busy], [error] and [info] describe the latest request, like the others.
final class Guest extends AuthState {
  final String uid;
  final bool busy;
  final String? error;
  final String? info;
  const Guest({required this.uid, this.busy = false, this.error, this.info});
}

/// Someone is signed in. Copies the few fields the UI needs instead of holding
/// Firebase's live, mutable User object, so each state is an immutable snapshot.
final class Authenticated extends AuthState {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final bool busy;
  final String? error;
  final String? info;

  const Authenticated({
    required this.uid,
    required this.emailVerified,
    this.email,
    this.displayName,
    this.busy = false,
    this.error,
    this.info,
  });

  factory Authenticated.fromUser(User user) => Authenticated(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    emailVerified: user.emailVerified,
  );

  /// The same account with a new request status ([busy], [error], [info]).
  Authenticated withStatus({bool busy = false, String? error, String? info}) {
    return Authenticated(
      uid: uid,
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
      busy: busy,
      error: error,
      info: info,
    );
  }
}
