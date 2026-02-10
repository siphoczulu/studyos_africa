import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/courses/data/course.dart';

class AppDb {
  AppDb._internal();

  static final AppDb instance = AppDb._internal();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'studyos_africa.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
''');
      },
    );
  }

  Future<List<Course>> getCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'id DESC');
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  Future<int> insertCourse(String name) async {
    final db = await database;
    return db.insert(
      'courses',
      {
        'name': name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    return db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
