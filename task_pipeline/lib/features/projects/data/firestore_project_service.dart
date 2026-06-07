import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_pipeline/models/project.dart';

/// Firestore-backed alternative to [ProjectService].
///
/// Projects live in the 'projects' collection, where each document holds:
///   - name: String
///   - createdAt: Timestamp
///
/// Firestore assigns its own String document IDs, which map directly onto
/// [Project.id] (also a String) — no conversion needed.
class FirestoreProjectService {
  const FirestoreProjectService();

  CollectionReference<Map<String, dynamic>> get _projects =>
      FirebaseFirestore.instance.collection('projects');

  /// Streams all projects in real time, ordered by creation time.
  Stream<List<Project>> watchProjects() {
    return _projects.orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs.map(Project.fromFirestore).toList(),
        );
  }

  /// Adds a new project document with an auto-generated ID.
  Future<void> addProject(String name) async {
    await _projects.add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
  }

  /// Renames the project identified by [id].
  Future<void> editProject(String id, String newName) async {
    await _projects.doc(id).update({'name': newName});
  }

  /// Deletes the project document identified by [id].
  Future<void> deleteProject(String id) async {
    await _projects.doc(id).delete();
  }
}
