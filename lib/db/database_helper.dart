import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/habit.dart';
import '../models/completion.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'habit_mastery.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        completed_date TEXT NOT NULL,
        UNIQUE(habit_id, completed_date),
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Habits ──────────────────────────────────────────────

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<Habit?> getHabitById(String id) async {
    final db = await database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ── Completions ──────────────────────────────────────────

  Future<void> insertCompletion(Completion completion) async {
    final db = await database;
    await db.insert(
      'completions',
      completion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> isCompletedToday(String habitId) async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.query(
      'completions',
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, today],
    );
    return result.isNotEmpty;
  }

  Future<List<Completion>> getCompletionsForHabit(String habitId) async {
    final db = await database;
    final maps = await db.query(
      'completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completed_date DESC',
    );
    return maps.map((m) => Completion.fromMap(m)).toList();
  }

  Future<List<String>> getCompletedDatesInMonth(
    String habitId,
    int year,
    int month,
  ) async {
    final db = await database;
    final prefix = '${year.toString()}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'completions',
      columns: ['completed_date'],
      where: "habit_id = ? AND completed_date LIKE ?",
      whereArgs: [habitId, '$prefix%'],
    );
    return maps.map((m) => m['completed_date'] as String).toList();
  }

  Future<Map<String, int>> getWeeklyCompletionCounts() async {
    final db = await database;
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final rows = await db.query(
        'completions',
        where: 'completed_date = ?',
        whereArgs: [dateStr],
      );
      result[dateStr] = rows.length;
    }
    return result;
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('completions');
    await db.delete('habits');
  }

  Future<void> deleteTodayCompletion(String habitId) async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db.delete(
      'completions',
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, today],
    );
  }

  Future<void> deleteCompletionByDate(
    String habitId,
    String completedDate,
  ) async {
    final db = await database;

    await db.delete(
      'completions',
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, completedDate],
    );
  }
}
