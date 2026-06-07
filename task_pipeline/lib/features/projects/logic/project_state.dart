part of 'project_bloc.dart';

sealed class ProjectState {
  const ProjectState();
}

/// Initial state before any load has been requested.
final class ProjectsInitial extends ProjectState {}

/// Loading is in progress.
final class ProjectsLoading extends ProjectState {}

/// Projects loaded successfully.
final class ProjectsLoaded extends ProjectState {
  final List<Project> projects;
  const ProjectsLoaded(this.projects);
}

/// A database or network error occurred.
final class ProjectsError extends ProjectState {
  final String message;
  const ProjectsError(this.message);
}
