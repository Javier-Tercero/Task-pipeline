import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/projects/data/firestore_project_service.dart';
import 'package:task_pipeline/models/project.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final FirestoreProjectService _service;

  ProjectBloc(this._service) : super(ProjectsInitial()) {
    on<LoadProjects>(_onLoad);
    on<AddProject>(_onAdd);
    on<EditProject>(_onEdit);
    on<DeleteProject>(_onDelete);
  }

  // Subscribes to the live Firestore stream — every snapshot becomes a new
  // state, so the UI stays in sync without ever needing to reload manually.
  Future<void> _onLoad(LoadProjects event, Emitter<ProjectState> emit) async {
    emit(ProjectsLoading());
    await emit.forEach<List<Project>>(
      _service.watchProjects(),
      onData: (projects) => ProjectsLoaded(projects),
      onError: (error, stackTrace) => ProjectsError(error.toString()),
    );
  }

  // The watchProjects() stream picks up the change automatically — no need
  // to trigger a reload after a successful write.
  Future<void> _onAdd(AddProject event, Emitter<ProjectState> emit) async {
    try {
      await _service.addProject(event.name);
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onEdit(EditProject event, Emitter<ProjectState> emit) async {
    try {
      await _service.editProject(event.id, event.newName);
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteProject event, Emitter<ProjectState> emit) async {
    try {
      await _service.deleteProject(event.id);
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }
}
