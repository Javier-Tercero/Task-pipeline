import 'package:flutter/material.dart';
import 'package:task_pipeline/models/task.dart';

/// A card representing a single task with edit and delete actions.
class TaskCardCompleted extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskCardCompleted({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade100.withValues(alpha: 0.5),
      child: ListTile(
        title: Text(
          task.name,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              isSelected: task.isCompleted,
              icon: const Icon(Icons.check_box_outline_blank),
              selectedIcon: const Icon(Icons.check_box),
              onPressed: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}
