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
  Future<void> addProject(String name, {String? summary}) async {
    await _projects.add({
      'name': name,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the project identified by [id]. Omitted fields are left untouched.
  Future<void> editProject(String id, {String? newName, String? newSummary}) async {
    await _projects.doc(id).update({
      'name': ?newName,
      'summary': ?newSummary,
    });
  }

  /// Deletes the project document identified by [id], along with every task
  /// in its tasks subcollection — Firestore never cascade-deletes
  /// subcollections on its own, so this has to be done explicitly.
  Future<void> deleteProject(String id) async {
    final tasks = await _projects.doc(id).collection('tasks').get();
    for (var i = 0; i < tasks.docs.length; i += 500) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in tasks.docs.skip(i).take(500)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _projects.doc(id).delete();
  }
}
