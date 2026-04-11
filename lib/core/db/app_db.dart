import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/courses/data/course.dart';
import '../../features/file_library/data/study_file.dart';
import '../../features/study_sessions/data/study_session.dart';
import '../../features/timetable/data/timetable_block.dart';

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
      version: 4,
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
        await db.execute('''
CREATE TABLE timetable_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL,
  weekday INTEGER NOT NULL,
  start_minutes INTEGER NOT NULL,
  end_minutes INTEGER NOT NULL
);
''');
        await db.execute('''
CREATE TABLE study_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  path TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at INTEGER NOT NULL
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
        if (oldVersion < 3) {
          await db.execute('''
CREATE TABLE timetable_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL,
  weekday INTEGER NOT NULL,
  start_minutes INTEGER NOT NULL,
  end_minutes INTEGER NOT NULL
);
''');
        }
        if (oldVersion < 4) {
          await db.execute('''
CREATE TABLE study_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  path TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at INTEGER NOT NULL
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
    return db.insert('courses', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> insertStudySession({
    required int courseId,
    required int startedAt,
    required int endedAt,
    required int durationSeconds,
  }) async {
    final db = await database;
    return db.insert('study_sessions', {
      'course_id': courseId,
      'started_at': startedAt,
      'ended_at': endedAt,
      'duration_seconds': durationSeconds,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
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

  Future<int> insertTimetableBlock({
    required int courseId,
    required int weekday,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final db = await database;
    return db.insert('timetable_blocks', {
      'course_id': courseId,
      'weekday': weekday,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<TimetableBlock>> getTimetableBlocks() async {
    final db = await database;
    final maps = await db.query(
      'timetable_blocks',
      orderBy: 'weekday ASC, start_minutes ASC',
    );
    return maps.map((map) => TimetableBlock.fromMap(map)).toList();
  }

  Future<int> insertStudyFile({
    required String name,
    required String path,
    required String type,
  }) async {
    final db = await database;
    return db.insert('study_files', {
      'name': name,
      'path': path,
      'type': type,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<StudyFile>> getStudyFiles() async {
    final db = await database;
    final maps = await db.query(
      'study_files',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => StudyFile.fromMap(map)).toList();
  }

  Future<int> deleteStudyFile(int id) async {
    final db = await database;
    return db.delete('study_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTimetableBlock(int id) async {
    final db = await database;
    return db.delete('timetable_blocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    return db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }
}
