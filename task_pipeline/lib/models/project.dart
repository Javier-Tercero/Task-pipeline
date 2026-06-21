import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a project in the Task Pipeline app.
class Project {
  final String id;
  final String name;
  final String? summary;

  const Project({required this.id, required this.name, this.summary});

  /// Creates a [Project] from a Fires
  /// tore document snapshot.
  factory Project.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(
      id: doc.id,
      name: data['name'] as String,
      summary: data['summary'] as String?,
    );
  }
}
