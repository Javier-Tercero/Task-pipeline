import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a task belonging to a project.
class Task {
  final String id;
  final String name;
  final String projectId;

  const Task({required this.id, required this.name, required this.projectId});

  /// Creates a [Task] from a Firestore document snapshot.
  ///
  /// [projectId] is passed in explicitly because tasks live in a subcollection
  /// under their project — the document itself does not store projectId.
  factory Task.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String projectId,
  ) {
    final data = doc.data()!;
    return Task(
      id: doc.id,
      name: data['name'] as String,
      projectId: projectId,
    );
  }
}