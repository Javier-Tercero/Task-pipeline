part of 'task_bloc.dart';

sealed class TaskEvent {}

/// Loads all tasks for [projectId].
final class LoadTasks extends TaskEvent {
  final String projectId;
  LoadTasks(this.projectId);
}

/// Persists a new task with [name] under [projectId].
final class AddTask extends TaskEvent {
  final String name;
  final String projectId;
  AddTask(this.name, this.projectId);
}

/// Renames the task identified by [id], then reloads [projectId].
final class EditTask extends TaskEvent {
  final int id;
  final String newName;
  final String projectId;
  EditTask(this.id, this.newName, this.projectId);
}

/// Deletes the task identified by [id], then reloads [projectId].
final class DeleteTask extends TaskEvent {
  final int id;
  final String projectId;
  DeleteTask(this.id, this.projectId);
}
