import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_pipeline/models/task.dart';

/// Firestore-backed alternative to [TaskService].
///
/// Tasks live in a subcollection at projects/{projectId}/tasks, where each
/// document holds:
///   - name: String
///   - createdAt: Timestamp
///
/// Firestore assigns its own String document IDs, which map directly onto
/// [Task.id] (also a String) — no conversion needed.
class FirestoreTaskService {
  const FirestoreTaskService();

  /// Returns the tasks subcollection for a given project.
  CollectionReference<Map<String, dynamic>> _tasks(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('tasks');
  }

  /// Streams all tasks for [projectId] in real time, ordered by creation time.
  Stream<List<Task>> watchTasks(String projectId) {
    return _tasks(projectId).orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromFirestore(doc, projectId))
              .toList(),
        );
  }

  /// Adds a new task document under the project's tasks subcollection.
  Future<void> addTask(String projectId, String name) async {
    await _tasks(projectId).add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
  }

  /// Renames the task identified by [taskId] under [projectId].
  Future<void> editTask(
    String projectId,
    String taskId,
    String newName,
  ) async {
    await _tasks(projectId).doc(taskId).update({'name': newName});
  }

  /// Deletes the task document identified by [taskId] under [projectId].
  Future<void> deleteTask(String projectId, String taskId) async {
    await _tasks(projectId).doc(taskId).delete();
  }
}
