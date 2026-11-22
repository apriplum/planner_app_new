import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/habit.dart';
import '../../models/habit_track.dart';
import '../database.dart';
import '../services/notification_service.dart';


class HabitRepository {
  HabitRepository(this._db);

  final Future<Database> _db;
  final _uuid = const Uuid();

  Future<List<Habit>> getActive(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'habits',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Habit.fromMap(rows.first);
  }

  Future<List<HabitTrack>> getTracks(String habitId) async {
    final db = await _db;
    final rows = await db.query(
      'habit_tracks',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'track_date ASC',
    );
    return rows.map(HabitTrack.fromMap).toList();
  }

  Future<bool> isDuplicate(Habit habit) async {
    final db = await _db;
    final rows = await db.query(
      'habits',
      where: '''
        user_id = ? AND deleted_at IS NULL
        AND LOWER(title) = ? AND frequency = ?
      ''',
      whereArgs: [
        habit.userId,
        habit.title.toLowerCase(),
        habit.frequency.dbValue,
      ],
    );
    return rows.isNotEmpty;
  }

  Future<void> create(Habit habit) async {
    final db = await _db;
    await db.insert('habits', habit.toMap());
    await scheduleHabitReminder(habit);
  }

  Future<void> update(Habit habit) async {
    final db = await _db;
    habit.updatedAt = DateTime.now();
    habit.version++;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    await scheduleHabitReminder(habit);
  }

  Future<void> moveToTrash(String id) async {
    final db = await _db;
    await db.update(
      'habits',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await NotificationService.instance.cancelByRecordId(id);
  }

  Future<void> restore(String id) async {
    final db = await _db;
    await db.update(
      'habits',
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePermanently(String id) async {
    final db = await _db;
    await db.delete('habit_tracks', where: 'habit_id = ?', whereArgs: [id]);
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTrack(HabitTrack track) async {
    final db = await _db;
    await db.insert(
      'habit_tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTrack(String id) async {
    final db = await _db;
    await db.delete('habit_tracks', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> purgeExpired(DateTime cutoff) async {
    final db = await _db;

    final rows = await db.query(
      'habits',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );

    for (final row in rows) {
      final id = row['id'] as String;
      await deletePermanently(id);
    }
  }

  Future<void> clearTrash() async {
    final db = await _db;

    final rows = await db.query(
      'habits',
      where: 'deleted_at IS NOT NULL',
    );

    for (final row in rows) {
      await deletePermanently(row['id'] as String);
    }
  }
  Future<void> scheduleHabitReminder(Habit habit) async {
  if (habit.reminderTime == null) return;

  final parts = habit.reminderTime!.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  final now = DateTime.now();
  var reminder = DateTime(now.year, now.month, now.day, hour, minute);

  if (reminder.isBefore(now)) {
    reminder = reminder.add(const Duration(days: 1));
  }

  await NotificationService.instance.schedule(
    recordId: habit.id,
    title: 'Привычка: ${habit.title}',
    body: 'Не забудьте выполнить привычку сегодня',
    when: reminder,
  );
}

Future<List<Habit>> getDeletedHabits(String userId) async {
  final db = await _db;

  final rows = await db.query(
    'habits',
    where: 'user_id = ? AND deleted_at IS NOT NULL',
    whereArgs: [userId],
    orderBy: 'deleted_at DESC',
  );

  return rows.map(Habit.fromMap).toList();
}

  String newId() => _uuid.v4();
}