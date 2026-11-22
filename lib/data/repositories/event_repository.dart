import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/event.dart';
import '../database.dart';
import '../services/notification_service.dart';

class EventRepository {
  EventRepository(this._db);

  final Future<Database> _db;
  final _uuid = const Uuid();

  Future<List<PlannerEvent>> getAll(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'events',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'start_date ASC, start_time ASC',
    );
    return rows.map(PlannerEvent.fromMap).toList();
  }

  Future<List<PlannerEvent>> getByDate(String userId, DateTime date) async {
    final target = date.toIso8601String().substring(0, 10);
    final db = await _db;
    final rows = await db.query(
      'events',
      where: '''
        user_id = ? AND deleted_at IS NULL
        AND start_date <= ? AND end_date >= ?
      ''',
      whereArgs: [userId, target, target],
      orderBy: 'start_time ASC',
    );
    return rows.map(PlannerEvent.fromMap).toList();
  }

  Future<List<PlannerEvent>> getOverdue(String userId) async {
    final events = await getAll(userId);
    final now = DateTime.now();
    return events.where((e) => e.isOverdue(now)).toList();
  }

  Future<PlannerEvent?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('events', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : PlannerEvent.fromMap(rows.first);
  }

  Future<bool> hasOverlap(PlannerEvent event) async {
    final events = await getAll(event.userId);
    return events.any((e) => e.id != event.id && e.overlaps(event));
  }

  Future<void> create(PlannerEvent event) async {
    final db = await _db;
    await db.insert('events', event.toMap());
    await scheduleEventReminder(event);
  }

  Future<void> update(PlannerEvent event) async {
    final db = await _db;
    event.updatedAt = DateTime.now();
    event.version++;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    await scheduleEventReminder(event);
  }

  Future<void> moveToTrash(String id) async {
    final db = await _db;
    await db.update(
      'events',
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
      'events',
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePermanently(String id) async {
    final db = await _db;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> purgeExpired(DateTime cutoff) async {
    final db = await _db;

    final rows = await db.query(
      'events',
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
      'events',
      where: 'deleted_at IS NOT NULL',
    );

    for (final row in rows) {
      await deletePermanently(row['id'] as String);
    }
  }
  Future<void> scheduleEventReminder(PlannerEvent event) async {
  if (event.reminderTime == null) return;

  final parts = event.reminderTime!.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  final reminder = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
    hour,
    minute,
  );

  await NotificationService.instance.schedule(
    recordId: event.id,
    title: 'Событие: ${event.title}',
    body: '${event.startTime}–${event.endTime}',
    when: reminder,
  );
}

  Future<List<PlannerEvent>> getDeletedEvents(String userId) async {
  final db = await _db;

  final rows = await db.query(
    'events',
    where: 'user_id = ? AND deleted_at IS NOT NULL',
    whereArgs: [userId],
    orderBy: 'deleted_at DESC',
  );

  return rows.map(PlannerEvent.fromMap).toList();
}

  String newId() => _uuid.v4();
}