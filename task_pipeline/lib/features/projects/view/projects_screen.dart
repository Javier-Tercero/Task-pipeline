import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/projects/logic/project_bloc.dart';
import 'package:task_pipeline/features/projects/widgets/project_card.dart';
import 'package:task_pipeline/features/tasks/view/tasks_screen.dart';
import 'package:task_pipeline/models/project.dart';
import 'package:task_pipeline/shared/widgets/empty_state.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final summaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Project name'),
              ),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(hintText: 'Project summary'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  // Use outer context — dialog context may not carry the bloc.
                  final summary = summaryController.text.trim();
                  if (summary.isNotEmpty) {
                    context.read<ProjectBloc>().add(AddProject(name, summary: summary));
                  } else {
                    context.read<ProjectBloc>().add(AddProject(name));
                  }
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      summaryController.dispose();
    });
  }

  void _showEditDialog(BuildContext context, Project project) {
    final nameController = TextEditingController(text: project.name);
    final summaryController = TextEditingController(text: project.summary);


    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(project.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
              ),
              TextField(
                controller: summaryController,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Project summary'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final summary = summaryController.text.trim();
                final newName = name.isNotEmpty ? name : null;
                final newSummary = summary.isNotEmpty ? summary : null;
                if (newName != null || newSummary != null) {
                  context.read<ProjectBloc>().add(
                        EditProject(project.id, newName: newName, newSummary: newSummary),
                      );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      summaryController.dispose();
    });
  }

  void _showDeleteDialog(BuildContext context, Project project) {

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Are you sure you want to delete ${project.name}?'),
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
                context.read<ProjectBloc>().add(DeleteProject(project.id));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete project'),
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
        title: const Text('Task Pipeline'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectsError) {
            return Center(child: Text(state.message));
          }
          if (state is ProjectsLoaded) {
            if (state.projects.isEmpty) {
              return const EmptyState(message: 'No projects yet. Tap + to add one.');
            }
            final screenHeight = MediaQuery.of(context).size.height;
            return SizedBox(
              height: screenHeight * 0.6,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                scrollDirection: Axis.horizontal,
                itemCount: state.projects.length,
                itemBuilder: (context, index) {
                  final project = state.projects[index];
                  return ProjectCard(
                    project: project,
                    onEdit: () => _showEditDialog(context, project),
                    onDelete: () => _showDeleteDialog(context, project),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TasksScreen(
                          projectId: project.id,
                          projectName: project.name,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          // ProjectsInitial — nothing to show yet.
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
