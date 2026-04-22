import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'database_helper.dart';
import 'models.dart';

void main() async {
  // Required before using plugins in main().
  WidgetsFlutterBinding.ensureInitialized();

  // On web, sqflite needs a custom database factory backed by IndexedDB.
  // On native platforms the default factory is used automatically.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const TaskPipelineApp());
}

// Root widget — sets up the app theme and entry point.
class TaskPipelineApp extends StatelessWidget {
  const TaskPipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Pipeline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// HomeScreen — manages the list of projects.
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getProjects();
    print('Loaded ${projects.length} projects from database');
    setState(() => _projects = projects);
  }

  // Shows a dialog prompting the user to enter a project name.
  // If saved, persists to the database and reloads the list.
  void _showAddProjectDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Project'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Project name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await DatabaseHelper.instance.insertProject(name);
                  await _loadProjects();
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Pipeline'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _projects.isEmpty ? _buildEmptyState() : _buildProjectList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Shown when there are no projects yet.
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No projects yet. Tap + to add one.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  // Renders each project as a tappable card that navigates to TasksScreen.
  Widget _buildProjectList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return Card(
          child: ListTile(
            title: Text(project.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TasksScreen(
                    projectId: project.id,
                    projectName: project.name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// TasksScreen — shows tasks for a given project.
// ---------------------------------------------------------------------------

class TasksScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const TasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance.getTasks(widget.projectId);
    setState(() => _tasks = tasks);
  }

  // Shows a dialog prompting the user to enter a task name.
  // If saved, persists to the database and reloads the list.
  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await DatabaseHelper.instance.insertTask(name, widget.projectId);
                  await _loadTasks();
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Picks a random task from the list and shows it in a dialog.
  // If there are no tasks, shows a snackbar instead.
  void _pickRandomTask() {
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some tasks first!')),
      );
      return;
    }

    final randomTask = _tasks[Random().nextInt(_tasks.length)];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Random Task'),
          content: Text(randomTask.name, style: const TextStyle(fontSize: 18)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
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
                onPressed: _pickRandomTask,
                icon: const Icon(Icons.shuffle),
                label: const Text('Pick Random Task'),
              ),
            ),
          ),

          // Task list or empty state below the button.
          Expanded(
            child: _tasks.isEmpty ? _buildEmptyState() : _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Shown when there are no tasks yet.
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No tasks yet. Tap + to add one.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  // Renders each task as a card in a scrollable list.
  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(_tasks[index].name),
          ),
        );
      },
    );
  }
}
