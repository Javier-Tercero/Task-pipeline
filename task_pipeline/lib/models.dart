/// Represents a project in the Task Pipeline app.
class Project {
  final int id;
  final String name;

  const Project({required this.id, required this.name});

  /// Creates a [Project] from a database row map.
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  /// Converts this [Project] to a map suitable for database insertion.
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

/// Represents a task belonging to a [Project].
class Task {
  final int id;
  final String name;
  final int projectId;

  const Task({required this.id, required this.name, required this.projectId});

  /// Creates a [Task] from a database row map.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      name: map['name'] as String,
      projectId: map['project_id'] as int,
    );
  }

  /// Converts this [Task] to a map suitable for database insertion.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'project_id': projectId,
      };
}
