import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _init();
  }

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'planner.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _create,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        yandex_id TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login TEXT,
        sync_enabled INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'medium',
        status TEXT NOT NULL DEFAULT 'active',
        category_id TEXT,
        due_date TEXT,
        due_time TEXT,
        reminder_time TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence TEXT NOT NULL DEFAULT 'none',
        difficulty TEXT,
        duration_minutes INTEGER,
        color TEXT,
        icon TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        event_type TEXT NOT NULL DEFAULT 'other',
        location TEXT,
        description TEXT DEFAULT '',
        color TEXT,
        start_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_date TEXT NOT NULL,
        end_time TEXT NOT NULL,
        reminder_time TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        version INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        frequency TEXT NOT NULL DEFAULT 'daily',
        target_value INTEGER NOT NULL DEFAULT 1,
        unit TEXT,
        color TEXT,
        start_date TEXT NOT NULL,
        reminder_time TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        version INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE habit_tracks (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        track_date TEXT NOT NULL,
        value INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        version INTEGER NOT NULL DEFAULT 1,
        UNIQUE(habit_id, track_date),
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date);');
    await db.execute('CREATE INDEX idx_events_start_date ON events(start_date);');
    await db.execute('CREATE INDEX idx_habit_tracks_date ON habit_tracks(track_date);');
    await db.execute('CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at);');
    await db.execute('CREATE INDEX idx_events_deleted_at ON events(deleted_at);');
    await db.execute('CREATE INDEX idx_habits_deleted_at ON habits(deleted_at);');
  }
}