import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/auth/logic/auth_bloc.dart';
import 'package:task_pipeline/features/auth/logic/guest_sign_up_memory.dart';
import 'package:task_pipeline/features/auth/view/auth_screen.dart';
import 'package:task_pipeline/features/tasks/data/firestore_task_service.dart';
import 'package:task_pipeline/features/tasks/logic/task_bloc.dart';
import 'package:task_pipeline/features/tasks/widgets/task_list.dart';
import 'package:task_pipeline/models/task.dart';
import 'package:task_pipeline/shared/widgets/cross_pattern_painter.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';
import 'package:task_pipeline/shared/widgets/poker_chip_button.dart';

/// Provides a scoped [TaskBloc] for this project and renders the task list.
class TasksScreen extends StatelessWidget {
  final String projectId;
  final String projectName;
  final int projectColor; // Color represented as an integer (ARGB)

  const TasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create a fresh bloc scoped to this project and immediately load tasks.
      create: (_) =>
          TaskBloc(FirestoreTaskService())..add(LoadTasks(projectId)),
      child: _TasksView(
        projectId: projectId,
        projectName: projectName,
        projectColor: projectColor,
      ),
    );
  }
}

class _TasksView extends StatefulWidget {
  final String projectId;
  final String projectName;
  final int projectColor; // Color represented as an integer (ARGB)

  const _TasksView({
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  // Whether the new-task editor is showing in the list.
  bool _creating = false;

  void _createTask(BuildContext context, String name) {
    context.read<TaskBloc>().add(AddTask(name, widget.projectId));
    setState(() => _creating = false);
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showDeleteDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Are you sure you want to delete ${task.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white, // text/icon color
              ),
              onPressed: () {
                context.read<TaskBloc>().add(
                  DeleteTask(task.id, widget.projectId),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete task'),
            ),
          ],
        );
      },
    );
  }

  void _completeTask(BuildContext context, Task task) {
    context.read<TaskBloc>().add(
      CompletionTask(task.id, widget.projectId, !task.isCompleted),
    );
  }

  void _renameTask(BuildContext context, Task task, String name) {
    if (name == task.name) return;
    context.read<TaskBloc>().add(EditTask(task.id, name, widget.projectId));
  }

  /// How many tasks a project needs before a guest is asked to sign up.
  static const _promptAfterTasks = 3;

  /// Opens the create-account form for a guest, remembering this project so
  /// they come back to it once their email is verified.
  void _signUp(BuildContext context) {
    context.read<GuestSignUpMemory>().returnToProjectId = widget.projectId;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen(startCreating: true)),
    );
  }

  /// Asks a guest to sign up, once, when this project gets its third task.
  Future<void> _promptSignUp(BuildContext context) async {
    final memory = context.read<GuestSignUpMemory>();
    if (memory.promptDismissed) return;
    if (context.read<AuthBloc>().state is! Guest) return;

    final signUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keep your projects'),
        content: const Text(
          "You're trying Task Pipeline as a guest. Sign up to keep your "
          'projects and tasks, and use them on any device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (signUp == true) {
      _signUp(context);
    } else {
      memory.promptDismissed = true;
    }
  }

  void _pickRandomTask(BuildContext context) {
    final state = context.read<TaskBloc>().state;

    if (state is! TasksLoaded || state.tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add some tasks first!')));
      return;
    }

    final randomTask = state.tasks[Random().nextInt(state.tasks.length)];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Random Task'),
          content: Text(randomTask.name, style: const TextStyle(fontSize: 18)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(widget.projectColor),
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.projectName,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          // Back arrow and icons in the same white as the title.
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            // Guests can sign up from here at any time, not only when asked.
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) =>
                  (previous is Guest) != (current is Guest),
              builder: (context, auth) => auth is Guest
                  ? TextButton(
                      onPressed: () => _signUp(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text('Sign up'),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        // Same blueprint pattern as the projects screen, behind everything.
        body: Stack(
          children: [
            Positioned.fill(
              // Its own layer, so the task list animating on top doesn't make
              // the pattern repaint every frame.
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: CrossPatternPainter(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // "Pick Random Task" button — always visible at the top.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickRandomTask(context),
                      // Solid, the same fill as the task cards, so the background
                      // pattern doesn't show through it.
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Pick Random Task'),
                    ),
                  ),
                ),

                // Task list or loading/empty state below the button.
                Expanded(
                  child: BlocConsumer<TaskBloc, TaskState>(
                    // This project just reached its third task.
                    listenWhen: (previous, current) =>
                        previous is TasksLoaded &&
                        current is TasksLoaded &&
                        previous.tasks.length < _promptAfterTasks &&
                        current.tasks.length >= _promptAfterTasks,
                    listener: (context, state) => _promptSignUp(context),
                    builder: (context, state) {
                      if (state is TasksLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is TasksError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is TasksLoaded) {
                        // A new task being written counts as content too.
                        if (state.tasks.isEmpty && !_creating) {
                          return const EmptyState(
                            message: 'No tasks yet. Tap + to add one.',
                          );
                        }
                        return TaskList(
                          tasks: state.tasks,
                          onComplete: (task) => _completeTask(context, task),
                          onDelete: (task) => _showDeleteDialog(context, task),
                          onRename: (task, name) =>
                              _renameTask(context, task, name),
                          creating: _creating,
                          onCreate: (name) => _createTask(context, name),
                          onCreateClosed: () =>
                              setState(() => _creating = false),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: PokerChipButton(
          icon: Icons.add,
          tooltip: 'Add Task',
          onPressed: () => setState(() => _creating = true),
        ),
      ),
    );
  }
}
