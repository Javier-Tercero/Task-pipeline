import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_pipeline/features/tasks/data/task_service.dart';
import 'package:task_pipeline/models/task.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _service;

  TaskBloc(this._service) : super(TasksInitial()) {
    on<LoadTasks>(_onLoad);
    on<AddTask>(_onAdd);
    on<EditTask>(_onEdit);
    on<DeleteTask>(_onDelete);
  }

  Future<void> _onLoad(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _service.getTasks(event.projectId);
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAdd(AddTask event, Emitter<TaskState> emit) async {
    try {
      await _service.addTask(event.name, event.projectId);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onEdit(EditTask event, Emitter<TaskState> emit) async {
    try {
      await _service.editTask(event.id, event.newName);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _service.deleteTask(event.id);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
