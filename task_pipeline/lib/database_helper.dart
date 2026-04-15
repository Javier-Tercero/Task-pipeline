import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Manages all SQLite database operations for Task Pipeline.
/// Uses a singleton so the database is opened only once.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  /// Returns the open database, initializing it on first access.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Opens (or creates) the database and sets up the schema.
  Future<Database> _initDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), 'task_pipeline.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Projects table — stores project names.
        await db.execute('''
          CREATE TABLE projects (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');

        // Tasks table — each task belongs to a project via project_id.
        await db.execute('''
          CREATE TABLE tasks (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT NOT NULL,
            project_id INTEGER NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (id)
          )
        ''');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Projects
  // ---------------------------------------------------------------------------

  /// Inserts a project with the given [name] and returns its new id.
  Future<int> insertProject(String name) async {
    final db = await database;
    return db.insert('projects', {'name': name});
  }

  /// Returns all projects as a list of maps with keys: id, name.
  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return db.query('projects', orderBy: 'id ASC');
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  /// Inserts a task with the given [name] under the specified [projectId].
  Future<int> insertTask(String name, int projectId) async {
    final db = await database;
    return db.insert('tasks', {'name': name, 'project_id': projectId});
  }

  /// Returns all tasks belonging to [projectId], ordered by insertion.
  Future<List<Map<String, dynamic>>> getTasks(int projectId) async {
    final db = await database;
    return db.query(
      'tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'id ASC',
    );
  }
}
