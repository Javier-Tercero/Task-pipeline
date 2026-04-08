import 'package:flutter/material.dart';

void main() {
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

// Main home screen of the app.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with the app title.
      appBar: AppBar(
        title: const Text('Task Pipeline'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // Body with centered "My Projects" label.
      body: const Center(
        child: Text(
          ' My Projects',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),

      // Floating action button for adding new items.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: handle add action
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
