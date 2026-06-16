import 'package:task_pipeline/database_helper.dart';
import 'package:task_pipeline/models/task.dart';

/// Handles all database operations for tasks.
class TaskService {
  const TaskService();

  Future<List<Task>> getTasks(String projectId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'tasks',
      where: 'project_id = ?',
      // The project_id column is INTEGER; convert the model's String id back.
      whereArgs: [int.parse(projectId)],
      orderBy: 'id ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<void> addTask(String name, String projectId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('tasks', {'name': name, 'project_id': int.parse(projectId)});
  }

  Future<void> editTask(String id, String newName) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tasks',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [int.parse(id)]);
  }
}
