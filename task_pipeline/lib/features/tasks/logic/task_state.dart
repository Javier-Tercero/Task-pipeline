part of 'task_bloc.dart';

sealed class TaskState {
  const TaskState();
}

/// Initial state before any load has been requested.
final class TasksInitial extends TaskState {}

/// Loading is in progress.
final class TasksLoading extends TaskState {}

/// Tasks loaded successfully.
final class TasksLoaded extends TaskState {
  final List<Task> tasks;
  const TasksLoaded(this.tasks);
}

/// A database or network error occurred.
final class TasksError extends TaskState {
  final String message;
  const TasksError(this.message);
}
