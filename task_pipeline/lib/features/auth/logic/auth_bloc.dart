import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/data/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _service;

  AuthBloc(this._service) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<SignInRequested>(_onSignIn);
    on<SignUpRequested>(_onSignUp);
    on<SignOutRequested>(_onSignOut);
    on<PasswordResetRequested>(_onPasswordReset);
    on<VerificationEmailRequested>(_onSendVerification);
    on<VerificationCheckRequested>(_onCheckVerification);
    on<DisplayNameUpdateRequested>(_onUpdateDisplayName);
  }

  AuthState _stateFor(User? user) {
    if (user == null) return const Unauthenticated();
    if (user.isAnonymous) {
      // Leftover from before accounts existed. Drop it so sign-in starts clean;
      // the auth stream then reports "signed out".
      unawaited(_service.signOut());
      return const Unauthenticated();
    }
    return Authenticated.fromUser(user);
  }

  /// Re-reads the current user into the state, for changes the auth stream
  /// doesn't announce (profile edits, verification).
  void _emitCurrentUser(Emitter<AuthState> emit) {
    final user = _service.currentUser;
    if (user != null) emit(_stateFor(user));
  }

  // Follows Firebase's sign-in state for the life of the bloc. Signing in or
  // out only has to change Firebase; this stream turns that into a new state.
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await emit.forEach<User?>(
      _service.authStateChanges,
      onData: _stateFor,
      onError: (error, stackTrace) =>
          Unauthenticated(error: describeAuthError(error)),
    );
  }

  Future<void> _onSignIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(const Unauthenticated(busy: true));
    try {
      await _service.signIn(event.email, event.password);
      // Success needs no emit: the auth stream reports the signed-in user.
    } catch (e) {
      emit(Unauthenticated(error: describeAuthError(e)));
    }
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(const Unauthenticated(busy: true));
    try {
      await _service.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      // The auth stream fired before the display name was saved; re-read it.
      _emitCurrentUser(emit);
    } catch (e) {
      emit(Unauthenticated(error: describeAuthError(e)));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _service.signOut();
    } catch (e) {
      final current = state;
      if (current is Authenticated) {
        emit(current.withStatus(error: describeAuthError(e)));
      }
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated(busy: true));
    try {
      await _service.sendPasswordReset(event.email);
      emit(
        Unauthenticated(
          info:
              'If an account exists for ${event.email}, a reset link is on its way.',
        ),
      );
    } catch (e) {
      emit(Unauthenticated(error: describeAuthError(e)));
    }
  }

  Future<void> _onSendVerification(
    VerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;
    emit(current.withStatus(busy: true));
    try {
      await _service.sendVerificationEmail();
      emit(
        current.withStatus(
          info: 'Verification email sent to ${current.email}.',
        ),
      );
    } catch (e) {
      emit(current.withStatus(error: describeAuthError(e)));
    }
  }

  Future<void> _onCheckVerification(
    VerificationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;
    emit(current.withStatus(busy: true));
    try {
      await _service.refreshUser();
      final user = _service.currentUser;
      if (user == null) {
        // Signed out meanwhile; the auth stream reports it.
        return;
      }
      final refreshed = Authenticated.fromUser(user);
      emit(
        refreshed.emailVerified
            ? refreshed
            : refreshed.withStatus(
                info:
                    'Not verified yet. Open the link in the email, then try again.',
              ),
      );
    } catch (e) {
      emit(current.withStatus(error: describeAuthError(e)));
    }
  }

  Future<void> _onUpdateDisplayName(
    DisplayNameUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;
    emit(current.withStatus(busy: true));
    try {
      await _service.updateDisplayName(event.name);
      final user = _service.currentUser;
      emit(
        user == null
            ? current
            : Authenticated.fromUser(user).withStatus(info: 'Name updated.'),
      );
    } catch (e) {
      emit(current.withStatus(error: describeAuthError(e)));
    }
  }
}
