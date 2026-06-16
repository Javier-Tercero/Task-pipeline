import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/tasks/data/firestore_task_service.dart';
import 'package:task_pipeline/models/task.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirestoreTaskService _service;

  TaskBloc(this._service) : super(TasksInitial()) {
    on<LoadTasks>(_onLoad);
    on<AddTask>(_onAdd);
    on<EditTask>(_onEdit);
    on<DeleteTask>(_onDelete);
  }

  // Subscribes to the live Firestore stream — every snapshot becomes a new
  // state, so the UI stays in sync without ever needing to reload manually.
  Future<void> _onLoad(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TasksLoading());
    await emit.forEach<List<Task>>(
      _service.watchTasks(event.projectId),
      onData: (tasks) => TasksLoaded(tasks),
      onError: (error, stackTrace) => TasksError(error.toString()),
    );
  }

  // The watchTasks() stream picks up the change automatically — no need
  // to trigger a reload after a successful write.
  Future<void> _onAdd(AddTask event, Emitter<TaskState> emit) async {
    try {
      await _service.addTask(event.projectId, event.name);
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onEdit(EditTask event, Emitter<TaskState> emit) async {
    try {
      await _service.editTask(event.projectId, event.id, event.newName);
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _service.deleteTask(event.projectId, event.id);
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
