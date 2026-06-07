/// Represents a task belonging to a project.
///
/// [projectId] is a String to match [Project.id].
class Task {
  final int id;
  final String name;
  final String projectId;

  const Task({required this.id, required this.name, required this.projectId});

  /// Creates a [Task] from a SQLite row map.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      name: map['name'] as String,
      projectId: (map['project_id'] as int).toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'project_id': projectId,
      };
}
