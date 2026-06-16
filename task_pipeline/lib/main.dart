import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'firebase_options.dart';
import 'package:task_pipeline/features/projects/data/firestore_project_service.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';
import 'package:task_pipeline/features/projects/view/projects_screen.dart';
import 'package:task_pipeline/features/tasks/data/firestore_task_service.dart';
import 'package:task_pipeline/features/tasks/logic/task_bloc.dart';

void main() async {
  // Required before using plugins in main().
  WidgetsFlutterBinding.ensureInitialized();

  // On web, sqflite needs a custom database factory backed by IndexedDB.
  // On native platforms the default factory is used automatically.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TaskPipelineApp());
}

class TaskPipelineApp extends StatelessWidget {
  const TaskPipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ProjectBloc is app-wide; kick off the initial load immediately.
        BlocProvider(
          create: (_) => ProjectBloc(FirestoreProjectService())..add(LoadProjects()),
        ),
        // TaskBloc is app-wide; TasksScreen overrides it with a scoped instance
        // per project so each navigation gets a fresh, isolated state.
        BlocProvider(
          create: (_) => TaskBloc(FirestoreTaskService()),
        ),
      ],
      child: MaterialApp(
        title: 'Task Pipeline',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const ProjectsScreen(),
      ),
    );
  }
}
