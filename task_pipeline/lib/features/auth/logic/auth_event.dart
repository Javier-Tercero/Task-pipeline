part of 'auth_bloc.dart';

sealed class AuthEvent {}

/// Starts following Firebase's sign-in state. Dispatched once, at startup.
final class AuthStarted extends AuthEvent {}

final class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested({required this.email, required this.password});
}

final class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  SignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

final class SignOutRequested extends AuthEvent {}

/// "Get started": try the app as a guest, without an account.
final class GuestStartRequested extends AuthEvent {}

/// Turns the current guest into a real account, keeping everything they made.
final class GuestUpgradeRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  GuestUpgradeRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// Sends a password-reset email to [email].
final class PasswordResetRequested extends AuthEvent {
  final String email;
  PasswordResetRequested(this.email);
}

/// Re-sends the verification email to the signed-in user.
final class VerificationEmailRequested extends AuthEvent {}

/// Re-reads the account to see whether the email has been verified yet.
final class VerificationCheckRequested extends AuthEvent {}

final class DisplayNameUpdateRequested extends AuthEvent {
  final String name;
  DisplayNameUpdateRequested(this.name);
}
