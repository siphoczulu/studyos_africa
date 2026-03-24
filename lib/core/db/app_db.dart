import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/courses/data/course.dart';
import '../../features/study_sessions/data/study_session.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
''');
        await db.execute('''
CREATE TABLE study_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL
);
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
CREATE TABLE study_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL
);
''');
        }
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

  Future<int> insertStudySession({
    required int courseId,
    required int startedAt,
    required int endedAt,
    required int durationSeconds,
  }) async {
    final db = await database;
    return db.insert(
      'study_sessions',
      {
        'course_id': courseId,
        'started_at': startedAt,
        'ended_at': endedAt,
        'duration_seconds': durationSeconds,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<StudySession>> getStudySessions() async {
    final db = await database;
    final maps = await db.query('study_sessions', orderBy: 'id DESC');
    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<List<StudySession>> getStudySessionsForCourse(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'study_sessions',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'id DESC',
    );
    return maps.map((map) => StudySession.fromMap(map)).toList();
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
