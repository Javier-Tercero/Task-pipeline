import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/view/auth_screen.dart';
import 'package:task_pipeline/features/auth/view/verify_email_screen.dart';
import 'package:task_pipeline/features/projects/view/projects_screen.dart';

/// The app's front door: picks the screen that matches the sign-in state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthInitial() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        Unauthenticated() => const AuthScreen(),
        Authenticated(emailVerified: false) => const VerifyEmailScreen(),
        Authenticated() => const ProjectsScreen(),
      },
    );
  }
}
