import 'package:task_pipeline/database_helper.dart';
import 'package:task_pipeline/models/project.dart';

/// Handles all database operations for projects.
class ProjectService {
  const ProjectService();

  Future<List<Project>> getProjects() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('projects', orderBy: 'id ASC');
    return rows.map(Project.fromMap).toList();
  }

  Future<void> addProject(String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('projects', {'name': name});
  }

  Future<void> editProject(String id, String newName) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'projects',
      {'name': newName},
      where: 'id = ?',
      // The id column is INTEGER; convert the model's String id back.
      whereArgs: [int.parse(id)],
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [int.parse(id)]);
  }
}
