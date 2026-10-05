import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/view/auth_screen.dart';
import 'package:task_pipeline/features/auth/view/verify_email_screen.dart';
import 'package:task_pipeline/features/projects/view/projects_screen.dart';

/// The app's front door: picks the screen that matches the sign-in state.
///
/// On the web, the landing page (taskpipelines.com) links here with
/// `?start=trial` for "Get started" and `?start=signin` for "Sign in".
/// A trial link starts a guest session straight away; anything else shows
/// the sign-in form.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Set once the first sign-in state has been seen, so the `?start=trial`
  // in the address only counts on arrival: signing out later mustn't start
  // another trial.
  static bool _arrivalHandled = false;

  /// Whether this is the first state since the page loaded and the address
  /// asked for a trial.
  static bool _takeTrialRequest() {
    if (_arrivalHandled) return false;
    _arrivalHandled = true;
    return kIsWeb && Uri.base.queryParameters['start'] == 'trial';
  }

  /// Whether the change from [previous] to [current] means different screens.
  static bool _screenChanges(AuthState previous, AuthState current) {
    if (previous.runtimeType != current.runtimeType) return true;
    return previous is Authenticated &&
        current is Authenticated &&
        previous.emailVerified != current.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: _screenChanges,
      listener: (context, state) {
        // When the session changes, drop any page pushed on top of this one
        // (a sign-up page opened from a project, say), so what's shown is the
        // screen for the new state and not a stale page left above it.
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Only a visitor who isn't signed in starts a trial; someone already
        // signed in just carries on.
        if (_takeTrialRequest() && state is Unauthenticated) {
          context.read<AuthBloc>().add(GuestStartRequested());
        }
      },
      buildWhen: _screenChanges,
      builder: (context, state) => switch (state) {
        AuthInitial() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        Unauthenticated() => const AuthScreen(),
        Guest() => const ProjectsScreen(),
        Authenticated(emailVerified: false) => const VerifyEmailScreen(),
        Authenticated() => const ProjectsScreen(),
      },
    );
  }
}
