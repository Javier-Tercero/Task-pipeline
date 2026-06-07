import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/tasks/data/task_service.dart';
import 'package:task_pipeline/features/tasks/logic/task_bloc.dart';
import 'package:task_pipeline/features/tasks/widgets/task_card.dart';
import 'package:task_pipeline/models/task.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';

/// Provides a scoped [TaskBloc] for this project and renders the task list.
class TasksScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const TasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create a fresh bloc scoped to this project and immediately load tasks.
      create: (_) => TaskBloc(TaskService())..add(LoadTasks(projectId)),
      child: _TasksView(projectId: projectId, projectName: projectName),
    );
  }
}

class _TasksView extends StatelessWidget {
  final String projectId;
  final String projectName;

  const _TasksView({required this.projectId, required this.projectName});

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
          content: TextField(
            controller: controller,
            autofocus: true,
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
                  context.read<TaskBloc>().add(EditTask(task.id, name, projectId));
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

  void _pickRandomTask(BuildContext context) {
    final state = context.read<TaskBloc>().state;

    if (state is! TasksLoaded || state.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some tasks first!')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    return const EmptyState(message: 'No tasks yet. Tap + to add one.');
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.tasks.length,
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return TaskCard(
                        task: task,
                        onEdit: () => _showEditDialog(context, task),
                        onDelete: () => _showDeleteDialog(context, task),
                      );
                    },
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
    );
  }
}
