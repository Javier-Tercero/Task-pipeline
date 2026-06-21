part of 'project_bloc.dart';

sealed class ProjectEvent {}

/// Loads all projects from the database.
final class LoadProjects extends ProjectEvent {}

/// Persists a new project with [name].
final class AddProject extends ProjectEvent {
  final String name;
  final String? summary;
  AddProject(this.name, {this.summary});
}

/// Renames the project identified by [id].
final class EditProject extends ProjectEvent {
  final String id;
  final String? newName;
  final String? newSummary;
  EditProject(this.id, {this.newName, this.newSummary});
}

/// Deletes the project identified by [id].
final class DeleteProject extends ProjectEvent {
  final String id;
  DeleteProject(this.id);
}
