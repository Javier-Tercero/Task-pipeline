import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a task belonging to a project.
///
/// [id] and [projectId] are both Strings so the same model can represent
/// SQLite rows (where integer keys are stringified) and Firestore documents
/// (which use String document IDs natively).
class Task {
  final String id;
  final String name;
  final String projectId;

  const Task({required this.id, required this.name, required this.projectId});

  /// Creates a [Task] from a SQLite row map.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: (map['id'] as int).toString(),
      name: map['name'] as String,
      projectId: (map['project_id'] as int).toString(),
    );
  }

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'project_id': projectId,
      };
}