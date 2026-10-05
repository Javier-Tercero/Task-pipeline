import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/tasks/data/firestore_task_service.dart';
import 'package:task_pipeline/features/tasks/logic/task_bloc.dart';
import 'package:task_pipeline/features/tasks/widgets/task_card.dart';
import 'package:task_pipeline/features/tasks/widgets/task_card_completed.dart';
import 'package:task_pipeline/models/task.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';

// One-line ListTile (56) + the Card's default 4 + 4 vertical margin. Every row
// is forced to this height so a row's position can be computed from its index.
const double _taskRowHeight = 64;

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

class _TasksView extends StatelessWidget {
  final String projectId;
  final String projectName;
  final int projectColor; // Color represented as an integer (ARGB)

  const _TasksView({
    required this.projectId,
    required this.projectName,
    required this.projectColor,
  });

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<TaskBloc>().add(AddTask(name, projectId));
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    final controller = TextEditingController(text: task.name);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(task.name),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<TaskBloc>().add(
                    EditTask(task.id, name, projectId),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
                context.read<TaskBloc>().add(DeleteTask(task.id, projectId));
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
      CompletionTask(task.id, projectId, !task.isCompleted),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    if (task.isCompleted) {
      return TaskCardCompleted(
        task: task,
        onComplete: () => _completeTask(context, task),
      );
    }
    return TaskCard(
      task: task,
      onComplete: () => _completeTask(context, task),
      onEdit: () => _showEditDialog(context, task),
      onDelete: () => _showDeleteDialog(context, task),
    );
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
        colorScheme: ColorScheme.fromSeed(seedColor: Color(projectColor)),
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            projectName,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Column(
          children: [
            // "Pick Random Task" button — always visible at the top.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickRandomTask(context),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Pick Random Task'),
                ),
              ),
            ),

            // Task list or loading/empty state below the button.
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TasksLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TasksError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is TasksLoaded) {
                    if (state.tasks.isEmpty) {
                      return const EmptyState(
                        message: 'No tasks yet. Tap + to add one.',
                      );
                    }
                    // Each row's top is index × row height and rows are keyed by
                    // task id. When a completion re-sorts the list, the row glides
                    // to its new slot and the rows in between slide up to fill the
                    // gap. The list lives only in the Bloc state, so there is no
                    // second copy to keep in sync.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: state.tasks.length * _taskRowHeight,
                        child: Stack(
                          children: [
                            for (var i = 0; i < state.tasks.length; i++)
                              AnimatedPositioned(
                                key: ValueKey(state.tasks[i].id),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                top: i * _taskRowHeight,
                                left: 0,
                                right: 0,
                                height: _taskRowHeight,
                                child: RepaintBoundary(
                                  child: _buildTaskCard(
                                    context,
                                    state.tasks[i],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          tooltip: 'Add Task',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
