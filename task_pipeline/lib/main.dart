import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:task_pipeline/features/auth/data/auth_service.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/view/auth_gate.dart';
import 'package:task_pipeline/features/projects/data/firestore_project_service.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';

void main() async {
  // Required before using plugins in main().
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TaskPipelineApp());
}

/// The uid of a signed-in user with a verified email, or null. Only such a
/// user is allowed to load data (see firestore.rules).
String? _sessionUid(AuthState state) {
  return state is Authenticated && state.emailVerified ? state.uid : null;
}

class TaskPipelineApp extends StatelessWidget {
  const TaskPipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AuthService())..add(AuthStarted()),
      child: BlocBuilder<AuthBloc, AuthState>(
        // Rebuild only when the session itself changes (someone signs in,
        // verifies, or signs out), not on every busy/error update.
        buildWhen: (previous, current) =>
            _sessionUid(previous) != _sessionUid(current),
        builder: (context, state) {
          final app = MaterialApp(
            title: 'Task Pipeline',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3B4219),
              ),
              useMaterial3: true,
            ),
            home: const AuthGate(),
          );

          final uid = _sessionUid(state);
          if (uid == null) return app;

          // ProjectBloc sits above MaterialApp so pushed routes (the edit
          // screen, dialogs) can read it. It exists only while someone is
          // signed in: signing out drops this provider, which closes the bloc
          // and its Firestore listener.
          return BlocProvider(
            key: ValueKey(uid),
            create: (_) =>
                ProjectBloc(FirestoreProjectService())..add(LoadProjects()),
            child: app,
          );
        },
      ),
    );
  }
}
