import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a project in the Task Pipeline app.
///
/// [id] is a String so the same model can represent both SQLite rows
/// (where the integer primary key is stringified) and Firestore documents
/// (which use String document IDs natively).
class Project {
  final String id;
  final String name;

  const Project({required this.id, required this.name});

  /// Creates a [Project] from a SQLite row map.
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: (map['id'] as int).toString(),
      name: map['name'] as String,
    );
  }

  /// Creates a [Project] from a Firestore document snapshot.
  factory Project.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(id: doc.id, name: data['name'] as String);
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}
