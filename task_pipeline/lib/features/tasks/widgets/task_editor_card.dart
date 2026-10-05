import 'package:flutter/material.dart';
import 'package:task_pipeline/models/task.dart';

/// A task card opened for editing, in place in the list. With no [task] it
/// creates a new one.
///
/// Its height is its content's, so new fields just go in the Column below; the
/// list measures the card and moves the tasks below it to make room.
class TaskEditorCard extends StatefulWidget {
  final Task? task;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const TaskEditorCard({
    super.key,
    this.task,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TaskEditorCard> createState() => _TaskEditorCardState();
}

class _TaskEditorCardState extends State<TaskEditorCard> {
  late final _nameController = TextEditingController(text: widget.task?.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a task name')));
      return;
    }
    widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cue that this task doesn't exist yet.
            if (widget.task == null)
              Text(
                'New task',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            // Same text style as the collapsed card's title, and no border, so
            // opening a task doesn't change how its name looks.
            TextField(
              controller: _nameController,
              autofocus: true,
              minLines: 1,
              maxLines: null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Title',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(widget.task == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
