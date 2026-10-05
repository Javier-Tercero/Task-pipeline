import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_pipeline/models/task.dart';
import 'package:task_pipeline/shared/data/user_root.dart';

/// Firestore-backed alternative to [TaskService].
///
/// Tasks live in a subcollection at users/{uid}/projects/{projectId}/tasks,
/// where each document holds:
///   - name: String
///   - isCompleted: bool
///   - createdAt: Timestamp
///
/// Firestore assigns its own String document IDs, which map directly onto
/// [Task.id] (also a String) — no conversion needed.
class FirestoreTaskService {
  const FirestoreTaskService();

  /// Returns the tasks subcollection for a given project.
  CollectionReference<Map<String, dynamic>> _tasks(String projectId) {
    return currentUserRoot()
        .collection('projects')
        .doc(projectId)
        .collection('tasks');
  }

  /// Streams all tasks for [projectId] in real time, ordered by creation time.
  Stream<List<Task>> watchTasks(String projectId) {
    return _tasks(projectId).orderBy('createdAt').snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc, projectId))
          .toList();
      // Completed tasks sink to the bottom; createdAt order is preserved within each group.
      final incomplete = tasks.where((task) => !task.isCompleted);
      final completed = tasks.where((task) => task.isCompleted);
      return [...incomplete, ...completed];
    });
  }

  /// Adds a new task document under the project's tasks subcollection.
  Future<void> addTask(String projectId, String name) async {
    await _tasks(
      projectId,
    ).add({'name': name, 'createdAt': Timestamp.now(), 'isCompleted': false});
  }

  /// Renames the task identified by [taskId] under [projectId].
  Future<void> editTask(String projectId, String taskId, String newName) async {
    await _tasks(projectId).doc(taskId).update({'name': newName});
  }

  /// Deletes the task document identified by [taskId] under [projectId].
  Future<void> deleteTask(String projectId, String taskId) async {
    await _tasks(projectId).doc(taskId).delete();
  }

  /// Marks the task identified by [taskId] as completed or not under [projectId].
  Future<void> completeTask(
    String projectId,
    String taskId,
    bool isCompleted,
  ) async {
    await _tasks(projectId).doc(taskId).update({'isCompleted': isCompleted});
  }
}
