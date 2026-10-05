import 'package:flutter/material.dart';
import 'package:task_pipeline/features/tasks/widgets/task_card.dart';
import 'package:task_pipeline/features/tasks/widgets/task_card_completed.dart';
import 'package:task_pipeline/features/tasks/widgets/task_editor_card.dart';
import 'package:task_pipeline/models/task.dart';
import 'package:task_pipeline/shared/widgets/measure_size.dart';

// One-line ListTile (56) + the Card's default 4 + 4 vertical margin. Every
// closed row is forced to this height; only an open editor measures its own.
const double _taskRowHeight = 64;

/// The animated task list. Rows are stacked by hand so they can slide: each
/// row's top is the sum of the heights above it, keyed by task id. When a
/// completion re-sorts the list, or a task opens for editing and grows, every
/// row glides to its new place instead of jumping.
///
/// It builds every kind of task card itself: open, being edited, new, and
/// completed. The screen only supplies what each action does (complete,
/// delete, save, create). The tasks live in the Bloc state; this widget only
/// holds which task is open and how tall its editor measured.
class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onComplete;
  final ValueChanged<Task> onDelete;
  final void Function(Task task, String name) onRename;

  /// Whether a new-task editor is showing. The screen owns this because its
  /// add button starts it.
  final bool creating;
  final ValueChanged<String> onCreate;

  /// The new-task editor was cancelled, or replaced by editing another task.
  final VoidCallback onCreateClosed;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onComplete,
    required this.onDelete,
    required this.onRename,
    required this.creating,
    required this.onCreate,
    required this.onCreateClosed,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  static const _newTaskKey = 'new-task';

  String? _editingId;
  // The open editor's measured height; null until its first layout.
  double? _editorHeight;
  // Same, for the new-task editor.
  double? _newTaskHeight;

  @override
  void didUpdateWidget(TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only one editor at a time: starting a new task closes any edit.
    if (widget.creating && !oldWidget.creating) {
      _editingId = null;
      _editorHeight = null;
    }
    if (!widget.creating) _newTaskHeight = null;

    // The open task was deleted or completed (maybe from another device):
    // close the editor rather than leave it waiting to reappear.
    final stillOpen = widget.tasks.any(
      (task) => task.id == _editingId && !task.isCompleted,
    );
    if (!stillOpen) {
      _editingId = null;
      _editorHeight = null;
    }
  }

  void _open(String id) {
    // Only one editor at a time: editing a task cancels the new one.
    if (widget.creating) widget.onCreateClosed();
    setState(() {
      _editingId = id;
      _editorHeight = null;
    });
  }

  void _close() {
    setState(() {
      _editingId = null;
      _editorHeight = null;
    });
  }

  void _onEditorSize(String id, Size size) {
    if (!mounted || id != _editingId || size.height == _editorHeight) return;
    setState(() => _editorHeight = size.height);
  }

  void _onNewTaskSize(Size size) {
    if (!mounted || !widget.creating || size.height == _newTaskHeight) return;
    setState(() => _newTaskHeight = size.height);
  }

  /// A closed card: completed tasks only get the checkbox; open tasks also get
  /// edit (which opens the editor in place) and delete.
  Widget _buildClosedCard(Task task) {
    if (task.isCompleted) {
      return TaskCardCompleted(
        task: task,
        onComplete: () => widget.onComplete(task),
      );
    }
    return TaskCard(
      task: task,
      onComplete: () => widget.onComplete(task),
      onEdit: () => _open(task.id),
      onDelete: () => widget.onDelete(task),
    );
  }

  /// An editor laid out at its natural height (OverflowBox) and measured; its
  /// row then animates to that height, clipping the editor while it grows.
  Widget _measuredEditor({
    required ValueChanged<Size> onSize,
    required Widget editor,
  }) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: MeasureSize(onChange: onSize, child: editor),
      ),
    );
  }

  Widget _row({
    required Key key,
    required double top,
    required double height,
    required Widget child,
  }) {
    return AnimatedPositioned(
      key: key,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: RepaintBoundary(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var top = 0.0;

    // A new task sits after the open tasks and before the completed ones,
    // which is where it will land once it's saved.
    void addNewTaskRow() {
      final height = _newTaskHeight ?? _taskRowHeight;
      rows.add(
        _row(
          key: const ValueKey(_newTaskKey),
          top: top,
          height: height,
          child: _measuredEditor(
            onSize: _onNewTaskSize,
            editor: TaskEditorCard(
              key: const ValueKey('editor-$_newTaskKey'),
              onCancel: widget.onCreateClosed,
              onSave: widget.onCreate,
            ),
          ),
        ),
      );
      top += height;
    }

    var newTaskPlaced = !widget.creating;
    for (final task in widget.tasks) {
      if (!newTaskPlaced && task.isCompleted) {
        addNewTaskRow();
        newTaskPlaced = true;
      }

      final editing = task.id == _editingId && !task.isCompleted;
      final height = editing
          ? (_editorHeight ?? _taskRowHeight)
          : _taskRowHeight;

      rows.add(
        _row(
          key: ValueKey(task.id),
          top: top,
          height: height,
          child: editing
              ? _measuredEditor(
                  onSize: (size) => _onEditorSize(task.id, size),
                  editor: TaskEditorCard(
                    key: ValueKey('editor-${task.id}'),
                    task: task,
                    onCancel: _close,
                    onSave: (name) {
                      widget.onRename(task, name);
                      _close();
                    },
                  ),
                )
              : _buildClosedCard(task),
        ),
      );
      top += height;
    }
    if (!newTaskPlaced) addNewTaskRow();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: top,
        child: Stack(children: rows),
      ),
    );
  }
}
