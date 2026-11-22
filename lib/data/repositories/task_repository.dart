import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../database.dart';
import '../services/notification_service.dart';

class TaskRepository {
  TaskRepository(this._db);

  final Future<Database> _db;
  final _uuid = const Uuid();

  Future<List<Task>> getActiveTasks(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'user_id = ? AND deleted_at IS NULL AND status = ?',
      whereArgs: [userId, TaskStatus.active.dbValue],
      orderBy: 'due_date ASC, priority DESC, created_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getCompletedTasks(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'user_id = ? AND deleted_at IS NULL AND status = ?',
      whereArgs: [userId, TaskStatus.completed.dbValue],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTodayTasks(String userId) async {
    final today = DateTime.now();
    final date = today.toIso8601String().substring(0, 10);
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: '''
        user_id = ? AND deleted_at IS NULL AND status = ?
        AND (due_date = ? OR due_date IS NULL)
      ''',
      whereArgs: [userId, TaskStatus.active.dbValue, date],
      orderBy: 'due_time ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getOverdueTasks(String userId) async {
    final tasks = await getActiveTasks(userId);
    return tasks.where((t) => t.isOverdue).toList();
  }

  Future<Task?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  Future<List<Subtask>> getSubtasks(String taskId) async {
    final db = await _db;
    final rows = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(Subtask.fromMap).toList();
  }

  Future<Task> create(Task task, List<Subtask> subtasks) async {
    final db = await _db;
    await db.insert('tasks', task.toMap());

    for (var i = 0; i < subtasks.length; i++) {
      final subtask = Subtask(
        id: subtasks[i].id,
        taskId: task.id,
        title: subtasks[i].title,
        isCompleted: subtasks[i].isCompleted,
        sortOrder: i,
      );
      await scheduleTaskReminder(task);
      await db.insert('subtasks', subtask.toMap());
    }

    return task;
  }

  Future<void> update(Task task) async {
    final db = await _db;
    task.updatedAt = DateTime.now();
    task.version++;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    await scheduleTaskReminder(task);
  }

  Future<void> toggleComplete(String id) async {
    final task = await getById(id);
    if (task == null) return;

    task.status = task.status == TaskStatus.active
        ? TaskStatus.completed
        : TaskStatus.active;

    await update(task);
  }

  Future<void> moveToTrash(String id) async {
    final db = await _db;
    await db.update(
      'tasks',
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
      'tasks',
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePermanently(String id) async {
    final db = await _db;
    await db.delete('subtasks', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reschedule(List<String> ids, DateTime newDate) async {
    final db = await _db;
    final date = newDate.toIso8601String().substring(0, 10);

    for (final id in ids) {
      await db.update(
        'tasks',
        {
          'due_date': date,
          'updated_at': DateTime.now().toIso8601String(),
          'version': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
  
  Future<void> updateSubtask(Subtask subtask) async {
    final db = await _db;
    subtask.updatedAt = DateTime.now();

    await db.update(
      'subtasks',
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }
  Future<void> purgeExpired(DateTime cutoff) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
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
      'tasks',
      where: 'deleted_at IS NOT NULL',
    );

    for (final row in rows) {
      await deletePermanently(row['id'] as String);
    }
  }
  Future<void> scheduleTaskReminder(Task task) async {
  if (task.reminderTime == null || task.dueDate == null) return;

  final timeParts = task.reminderTime!.split(':');
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);

  final reminder = DateTime(
    task.dueDate!.year,
    task.dueDate!.month,
    task.dueDate!.day,
    hour,
    minute,
  );

  await NotificationService.instance.schedule(
    recordId: task.id,
    title: 'Задача: ${task.title}',
    body: 'Пора выполнить задачу',
    when: reminder,
  );
}

  Future<List<Task>> getDeletedTasks(String userId) async {
  final db = await _db;

  final rows = await db.query(
    'tasks',
    where: 'user_id = ? AND deleted_at IS NOT NULL',
    whereArgs: [userId],
    orderBy: 'deleted_at DESC',
  );

  return rows.map(Task.fromMap).toList();
}
  String newId() => _uuid.v4();
}