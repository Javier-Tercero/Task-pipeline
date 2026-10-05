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
    on<GuestStartRequested>(_onStartGuest);
    on<GuestUpgradeRequested>(_onUpgradeGuest);
    on<PasswordResetRequested>(_onPasswordReset);
    on<VerificationEmailRequested>(_onSendVerification);
    on<VerificationCheckRequested>(_onCheckVerification);
    on<DisplayNameUpdateRequested>(_onUpdateDisplayName);
  }

  AuthState _stateFor(User? user) {
    if (user == null) return const Unauthenticated();
    if (user.isAnonymous) return Guest(uid: user.uid);
    return Authenticated.fromUser(user);
  }

  /// The current state with a new request status ([busy], [error], [info]).
  ///
  /// Keeps the kind of state: a guest who signs in or resets a password stays a
  /// guest while it runs, instead of briefly looking signed out, which would
  /// swap their screens underneath them.
  AuthState _status({bool busy = false, String? error, String? info}) {
    return switch (state) {
      Guest(:final uid) => Guest(
        uid: uid,
        busy: busy,
        error: error,
        info: info,
      ),
      Authenticated current => current.withStatus(
        busy: busy,
        error: error,
        info: info,
      ),
      _ => Unauthenticated(busy: busy, error: error, info: info),
    };
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
    emit(_status(busy: true));
    try {
      await _service.signIn(event.email, event.password);
      // Success needs no emit: the auth stream reports the signed-in user.
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
    }
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(_status(busy: true));
    try {
      await _service.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      // The auth stream fired before the display name was saved; re-read it.
      _emitCurrentUser(emit);
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _service.signOut();
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
    }
  }

  Future<void> _onStartGuest(
    GuestStartRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_status(busy: true));
    try {
      await _service.startGuest();
      // Success needs no emit: the auth stream reports the guest.
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
    }
  }

  Future<void> _onUpgradeGuest(
    GuestUpgradeRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Guest) return;
    emit(_status(busy: true));
    try {
      await _service.upgradeGuest(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      // Linking keeps the same signed-in user, so the auth stream stays quiet;
      // re-read it to become an (unverified) account.
      _emitCurrentUser(emit);
    } on FirebaseAuthException catch (e) {
      final taken =
          e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use';
      emit(
        _status(
          error: taken
              ? 'That email already has an account. Sign in with it instead '
                    "(projects made as a guest won't carry over)."
              : describeAuthError(e),
        ),
      );
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_status(busy: true));
    try {
      await _service.sendPasswordReset(event.email);
      emit(
        _status(
          info:
              'If an account exists for ${event.email}, a reset link is on its way.',
        ),
      );
    } catch (e) {
      emit(_status(error: describeAuthError(e)));
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
